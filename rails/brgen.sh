#!/usr/bin/env zsh
set -euo pipefail

# Brgen core setup: Multi-tenant social and marketplace platform with Mapbox, live search, infinite scroll, and anonymous features on OpenBSD 7.5, unprivileged user
APP_NAME="brgen"
BASE_DIR="/home/brgen"

APP_DIR="${BASE_DIR}/app"

BRGEN_IP="185.52.176.18"

BRGEN_PORT="11006"

source "./__shared/@common.sh"
log "Starting Brgen core setup"
# Note: openbsd.sh creates /home/brgen/app with basic structure
# We need to initialize a full Rails app within that directory

if [[ ! -d "$APP_DIR" ]]; then

  log "ERROR: $APP_DIR does not exist. Run: doas zsh openbsd.sh --pre-point"

  exit 1

fi

cd "$APP_DIR"
log "Working in app directory: $APP_DIR"

# Initialize Rails app if not already done
# openbsd.sh creates the directory structure but NOT the Rails skeleton

if [[ ! -f "config/application.rb" ]]; then

  log "Initializing Rails application skeleton"

  rails new . --database=postgresql --skip-git --force

  # openbsd.sh already created Gemfile, so merge our additions
  log "Rails skeleton created. Installing additional gems..."

fi

# Fix database.yml to use correct username and database name
if [[ -f "config/database.yml" ]]; then

  content=$(<config/database.yml)

  content=${content//database: app_production/database: brgen_production}

  content=${content//username: app/username: brgen}

  content=${content//APP_DATABASE_PASSWORD/BRGEN_DATABASE_PASSWORD}

  print -r -- "$content" > config/database.yml

  log "Fixed database.yml to use brgen user"

fi

# Run bundle install to ensure all gems are available
bundle install

command_exists "ruby"
command_exists "node"

command_exists "psql"

# Rails 8: Solid Queue/Cache/Cable replace Redis (per edgeguides.rubyonrails.org/8_0_release_notes)
install_gem "solid_queue"
install_gem "solid_cache"
install_gem "solid_cable"

install_gem "acts_as_tenant"
install_gem "pagy"

install_gem "faker"

# Rails 8: Use built-in authentication generator (replaces Devise)
log "Setting up Rails 8 authentication"

bin/rails generate authentication User

# Setup Posts/Communities which depend on User
log "Setting up Posts and Communities"

bin/rails generate model Community name:string description:text

bin/rails generate model Post title:string content:text user:references community:references

# Social features: Comments, Votes, Karma, Retweets, Follows, Timeline
setup_reddit_features
setup_twitter_features

# Marketplace features: Bookings, Reviews, Host Profiles
setup_airbnb_features

# Travel search features: Flights, Hotels, Price Alerts
setup_momondo_features

# Messenger features: DMs, Typing Indicators, Read Receipts
setup_messenger_features

# Now generate City scaffold (no user dependency)
log "Generating City scaffold"

bin/rails generate scaffold City name:string subdomain:string country:string city:string language:string favicon:string analytics:string tld:string

# Generate Listing scaffold (depends on user)
log "Generating Listing scaffold"

bin/rails generate scaffold Listing title:string description:text price:decimal category:string status:string user:references location:string lat:decimal lng:decimal photos:attachments community:references

# Run all migrations
log "Running database migrations"

bin/rails db:migrate

# Add ActsAsTenant to models
log "Configuring multi-tenancy"

cat <<EOF > app/models/listing.rb

class Listing < ApplicationRecord
  include Votable
  include Commentable

  acts_as_tenant :city

  belongs_to :user

  belongs_to :city, foreign_key: :community_id

  has_many_attached :photos

  validates :title, :description, :price, :category, :status, :location, :lat, :lng, presence: true
end

EOF

cat <<EOF > app/models/post.rb
class Post < ApplicationRecord
  include Votable
  include Commentable

  acts_as_tenant :city

  belongs_to :user

  belongs_to :city, foreign_key: :community_id

  validates :title, :content, presence: true

  # Reddit-style sorting
  scope :hot, -> { left_joins(:votes).group(:id).order("SUM(COALESCE(votes.value, 0)) / POW(EXTRACT(EPOCH FROM (NOW() - posts.created_at)) / 3600 + 2, 1.5) DESC") }
  scope :top, -> { left_joins(:votes).group(:id).order("SUM(COALESCE(votes.value, 0)) DESC") }
  scope :new, -> { order(created_at: :desc) }
end

EOF

cat <<EOF > app/models/city.rb
class City < ApplicationRecord

  has_many :posts, foreign_key: :community_id

  has_many :listings, foreign_key: :community_id

  validates :name, :subdomain, presence: true
  validates :subdomain, uniqueness: true

end

EOF

cat <<EOF > app/models/user.rb
class User < ApplicationRecord

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :listings, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end

EOF

generate_infinite_scroll_reflex "Listing" "listings"
cat <<EOF > app/reflexes/insights_reflex.rb
class InsightsReflex < ApplicationReflex

  def analyze

    posts = Post.where(community: ActsAsTenant.current_tenant)

    titles = posts.map(&:title).join(", ")

    cable_ready.replace(selector: "#insights-output", html: "<div class='insights'>Analyzed: #{titles}</div>").broadcast

  end

end

EOF

generate_mapbox_controller "mapbox" 5.3467 60.3971 "listings"
generate_insights_controller "output"
# Generate all Stimulus controllers for Rails 8 PWA
generate_all_stimulus_controllers

# Generate CRUD views for listings
generate_crud_views "listing" "listings"

cat <<EOF > config/initializers/tenant.rb
ActsAsTenant.configure do |config|

  config.require_tenant = true

end

EOF

cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base

  before_action :set_tenant

  before_action :authenticate_user!, except: [:index, :show], unless: :guest_user_allowed?

  def after_sign_in_path_for(resource)
    root_path

  end

  private
  def set_tenant
    ActsAsTenant.current_tenant = City.find_by(subdomain: request.subdomain)

    unless ActsAsTenant.current_tenant

      redirect_to root_url(subdomain: false), alert: t("brgen.tenant_not_found")

    end

  end

  def guest_user_allowed?
    controller_name == "home" ||

    (controller_name == "posts" && action_name.in?(["index", "show", "create"])) ||

    (controller_name == "listings" && action_name.in?(["index", "show"]))

  end

end

EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController

  def index

    @pagy, @posts = pagy(Post.where(community: ActsAsTenant.current_tenant).order(created_at: :desc), items: 10) unless @stimulus_reflex

    @listings = Listing.where(community: ActsAsTenant.current_tenant).order(created_at: :desc).limit(5)

  end

end

EOF

cat <<EOF > app/controllers/listings_controller.rb
class ListingsController < ApplicationController

  before_action :set_listing, only: [:show, :edit, :update, :destroy]

  before_action :initialize_listing, only: [:index, :new]

  def index
    @pagy, @listings = pagy(Listing.where(community: ActsAsTenant.current_tenant).order(created_at: :desc)) unless @stimulus_reflex

  end

  def show
  end

  def new
  end

  def create
    @listing = Listing.new(listing_params)

    @listing.user = current_user

    @listing.community = ActsAsTenant.current_tenant

    if @listing.save

      respond_to do |format|

        format.html { redirect_to listings_path, notice: t("brgen.listing_created") }

        format.turbo_stream

      end

    else

      render :new, status: :unprocessable_entity

    end

  end

  def edit
  end

  def update
    if @listing.update(listing_params)

      respond_to do |format|

        format.html { redirect_to listings_path, notice: t("brgen.listing_updated") }

        format.turbo_stream

      end

    else

      render :edit, status: :unprocessable_entity

    end

  end

  def destroy
    @listing.destroy

    respond_to do |format|

      format.html { redirect_to listings_path, notice: t("brgen.listing_deleted") }

      format.turbo_stream

    end

  end

  private
  def set_listing
    @listing = Listing.where(community: ActsAsTenant.current_tenant).find(params[:id])

    redirect_to listings_path, alert: t("brgen.not_authorized") unless @listing.user == current_user || current_user&.admin?

  end

  def initialize_listing
    @listing = Listing.new

  end

  def listing_params
    params.require(:listing).permit(:title, :description, :price, :category, :status, :location, :lat, :lng, photos: [])

  end

end

EOF

cat <<EOF > app/views/listings/_listing.html.erb
<%= turbo_frame_tag dom_id(listing) do %>

  <%= tag.article class: "post-card", id: dom_id(listing), role: "article" do %>

    <%= tag.div class: "post-header" do %>

      <%= tag.span t("brgen.posted_by", user: listing.user.email) %>

      <%= tag.span listing.created_at.strftime("%Y-%m-%d %H:%M") %>

    <% end %>

    <%= tag.h2 listing.title %>

    <%= tag.p listing.description %>

    <%= tag.p t("brgen.listing_price", price: number_to_currency(listing.price)) %>

    <%= tag.p t("brgen.listing_location", location: listing.location) %>

    <% if listing.photos.attached? %>

      <% listing.photos.each do |photo| %>

        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen.listing_photo", title: listing.title) %>

      <% end %>

    <% end %>

    <%= render partial: "shared/vote", locals: { votable: listing } %>

    <%= tag.p class: "post-actions" do %>

      <%= link_to t("brgen.view_listing"), listing_path(listing), "aria-label": t("brgen.view_listing") %>

      <%= link_to t("brgen.edit_listing"), edit_listing_path(listing), "aria-label": t("brgen.edit_listing") if listing.user == current_user || current_user&.admin? %>

      <%= button_to t("brgen.delete_listing"), listing_path(listing), method: :delete, data: { turbo_confirm: t("brgen.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen.delete_listing") if listing.user == current_user || current_user&.admin? %>

    <% end %>

  <% end %>

<% end %>

EOF

cat <<EOF > app/views/listings/_form.html.erb
<%= form_with model: listing, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>

  <%= tag.div data: { turbo_frame: "notices" } do %>

    <%= render "shared/notices" %>

  <% end %>

  <% if listing.errors.any? %>

    <%= tag.div role: "alert" do %>

      <%= tag.p t("brgen.errors", count: listing.errors.count) %>

      <%= tag.ul do %>

        <% listing.errors.full_messages.each do |msg| %>

          <%= tag.li msg %>

        <% end %>

      <% end %>

    <% end %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :title, t("Brgen.listing_title"), "aria-required": true %>

    <%= form.text_field :title, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_title_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_title" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :description, t("brgen.listing_description"), "aria-required": true %>

    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen.listing_description_help") %>

    <%= tag.span data: { "character-counter-target": "count" } %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_description" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :price, t("brgen.listing_price"), "aria-required": true %>

    <%= form.number_field :price, required: true, step: 0.01, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_price_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_price" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :category, t("brgen.listing_category"), "aria-required": true %>

    <%= form.text_field :category, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_category_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_category" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :status, t("brgen.listing_status"), "aria-required": true %>

    <%= form.select :status, ["available", "sold"], { prompt: t("brgen.status_prompt") }, required: true %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_status" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :location, t("brgen.listing_location"), "aria-required": true %>

    <%= form.text_field :location, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_location_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_location" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :lat, t("brgen.listing_lat"), "aria-required": true %>

    <%= form.number_field :lat, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_lat_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_lat" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :lng, t("brgen.listing_lng"), "aria-required": true %>

    <%= form.number_field :lng, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_lng_help") %>

    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_lng" } %>

  <% end %>

  <%= tag.fieldset do %>

    <%= form.label :photos, t("brgen.listing_photos") %>

    <%= form.file_field :photos, multiple: true, accept: "image/*", data: { controller: "file-preview", "file-preview-target": "input" } %>

    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>

  <% end %>

  <%= form.submit %>

<% end %>

EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>

  <%= render partial: "${APP_NAME}_logo/logo" %>

<% end %>

EOF

cat <<EOF > app/views/shared/_footer.html.erb
<%= tag.footer role: "contentinfo" do %>

  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>

    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>

    <%= link_to "", "https://x.com", class: "footer-link x", "aria-label": "X (formerly Twitter)" %>

    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>

    <%= link_to t("shared.about"), "#", class: "footer-link text" %>

    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>

    <%= link_to t("shared.terms"), "#", class: "footer-link text" %>

    <%= link_to t("shared.privacy"), "#", class: "footer-link text" %>

  <% end %>

<% end %>

EOF

cat <<EOF > app/views/listings/index.html.erb
<% content_for :title, t("brgen.listings_title") %>

<% content_for :description, t("brgen.listings_description") %>

<% content_for :keywords, t("brgen.listings_keywords", default: "brgen, marketplace, listings, #{ActsAsTenant.current_tenant.name}") %>

<% content_for :schema do %>

  <script type="application/ld+json">

  {

    "@context": "https://schema.org",

    "@type": "WebPage",

    "name": "<%= t('brgen.listings_title') %>",

    "description": "<%= t('brgen.listings_description') %>",

    "url": "<%= request.original_url %>",

    "hasPart": [

      <% @listings.each do |listing| %>

      {

        "@type": "Product",

        "name": "<%= listing.title %>",

        "description": "<%= listing.description&.truncate(160) %>",

        "offers": {

          "@type": "Offer",

          "price": "<%= listing.price %>",

          "priceCurrency": "NOK"

        },

        "geo": {

          "@type": "GeoCoordinates",

          "latitude": "<%= listing.lat %>",

          "longitude": "<%= listing.lng %>"

        }

      }<%= "," unless listing == @listings.last %>

      <% end %>

    ]

  }

  </script>

<% end %>

<%= render "shared/header" %>

<%= tag.main role: "main" do %>

  <%= tag.section aria-labelledby: "listings-heading" do %>

    <%= tag.h1 t("brgen.listings_title"), id: "listings-heading" %>

    <%= tag.div data: { turbo_frame: "notices" } do %>

      <%= render "shared/notices" %>

    <% end %>

    <%= link_to t("brgen.new_listing"), new_listing_path, class: "button", "aria-label": t("brgen.new_listing") if current_user %>

    <%= turbo_frame_tag "listings" data: { controller: "infinite-scroll" } do %>

      <% @listings.each do |listing| %>

        <%= render partial: "listings/listing", locals: { listing: listing } %>

      <% end %>

      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ListingsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>

    <% end %>

    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->ListingsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>

  <% end %>

  <%= tag.section aria-labelledby: "search-heading" do %>

    <%= tag.h2 t("brgen.search_title"), id: "search-heading" %>

    <%= tag.div data: { controller: "search", model: "Listing", field: "title" } do %>

      <%= tag.input type: "text", placeholder: t("brgen.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("brgen.search_listings") %>

      <%= tag.div id: "search-results", data: { "search-target": "results" } %>

      <%= tag.div id: "reset-link" %>

    <% end %>

  <% end %>

<% end %>

<%= render "shared/footer" %>

EOF

cat <<EOF > app/views/cities/index.html.erb
<% content_for :title, t("brgen.cities_title") %>

<% content_for :description, t("brgen.cities_description") %>

<% content_for :keywords, t("brgen.cities_keywords", default: "brgen, cities, community") %>

<% content_for :schema do %>

  <script type="application/ld+json">

  {

    "@context": "https://schema.org",

    "@type": "WebPage",

    "name": "<%= t('brgen.cities_title') %>",

    "description": "<%= t('brgen.cities_description') %>",

    "url": "<%= request.original_url %>"

  }

  </script>

<% end %>

<%= render "shared/header" %>

<%= tag.main role: "main" do %>

  <%= tag.section aria-labelledby: "cities-heading" do %>

    <%= tag.h1 t("brgen.cities_title"), id: "cities-heading" %>

    <%= tag.div data: { turbo_frame: "notices" } do %>

      <%= render "shared/notices" %>

    <% end %>

    <%= link_to t("brgen.new_city"), new_city_path, class: "button", "aria-label": t("brgen.new_city") if current_user %>

    <%= turbo_frame_tag "cities" do %>

      <% @cities.each do |city| %>

        <%= render partial: "cities/city", locals: { city: city } %>

      <% end %>

    <% end %>

  <% end %>

<% end %>

<%= render "shared/footer" %>

EOF

cat <<EOF > app/views/cities/_city.html.erb
<%= turbo_frame_tag dom_id(city) do %>

  <%= tag.article class: "post-card", id: dom_id(city), role: "article" do %>

    <%= tag.h2 city.name %>

    <%= tag.p t("brgen.city_country", country: city.country) %>

    <%= tag.p t("brgen.city_name", city: city.city) %>

    <%= tag.p class: "post-actions" do %>

      <%= link_to t("brgen.view_posts"), "http://#{city.subdomain}.brgen.#{city.tld}/posts", "aria-label": t("brgen.view_posts") %>

      <%= link_to t("brgen.view_listings"), "http://#{city.subdomain}.brgen.#{city.tld}/listings", "aria-label": t("brgen.view_listings") %>

      <%= link_to t("brgen.edit_city"), edit_city_path(city), "aria-label": t("brgen.edit_city") if current_user %>

      <%= button_to t("brgen.delete_city"), city_path(city), method: :delete, data: { turbo_confirm: t("brgen.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen.delete_city") if current_user %>

    <% end %>

  <% end %>

<% end %>

EOF

cat <<EOF > app/views/home/index.html.erb
<% content_for :title, t("brgen.home_title") %>

<% content_for :description, t("brgen.home_description") %>

<% content_for :keywords, t("brgen.home_keywords", default: "brgen, community, marketplace, #{ActsAsTenant.current_tenant.name}") %>

<% content_for :schema do %>

  <script type="application/ld+json">

  {

    "@context": "https://schema.org",

    "@type": "WebPage",

    "name": "<%= t('brgen.home_title') %>",

    "description": "<%= t('brgen.home_description') %>",

    "url": "<%= request.original_url %>",

    "publisher": {

      "@type": "Organization",

      "name": "Brgen",

      "logo": {

        "@type": "ImageObject",

        "url": "<%= image_url('brgen_logo.svg') %>"

      }

    }

  }

  </script>

<% end %>

<%= render "shared/header" %>

<%= tag.main role: "main" do %>

  <%= tag.section aria-labelledby: "post-heading" do %>

    <%= tag.h1 t("brgen.post_title"), id: "post-heading" %>

    <%= tag.div data: { turbo_frame: "notices" } do %>

      <%= render "shared/notices" %>

    <% end %>

    <%= render partial: "posts/form", locals: { post: Post.new } %>

  <% end %>

  <%= tag.section aria-labelledby: "map-heading" do %>

    <%= tag.h2 t("brgen.map_title"), id: "map-heading" %>

    <%= tag.div id: "map" data: { controller: "mapbox", "mapbox-api-key-value": ENV["MAPBOX_API_KEY"], "mapbox-listings-value": @listings.to_json } %>

  <% end %>

  <%= tag.section aria-labelledby: "search-heading" do %>

    <%= tag.h2 t("brgen.search_title"), id: "search-heading" %>

    <%= tag.div data: { controller: "search", model: "Post", field: "title" } do %>

      <%= tag.input type: "text", placeholder: t("brgen.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("brgen.search_posts") %>

      <%= tag.div id: "search-results", data: { "search-target": "results" } %>

      <%= tag.div id: "reset-link" %>

    <% end %>

  <% end %>

  <%= tag.section aria-labelledby: "posts-heading" do %>

    <%= tag.h2 t("brgen.posts_title"), id: "posts-heading" %>

    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>

      <% @posts.each do |post| %>

        <%= render partial: "posts/post", locals: { post: post } %>

      <% end %>

      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>

    <% end %>

    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>

  <% end %>

  <%= tag.section aria-labelledby: "listings-heading" do %>

    <%= tag.h2 t("brgen.listings_title"), id: "listings-heading" %>

    <%= link_to t("brgen.new_listing"), new_listing_path, class: "button", "aria-label": t("brgen.new_listing") if current_user %>

    <%= turbo_frame_tag "listings" data: { controller: "infinite-scroll" } do %>

      <% @listings.each do |listing| %>

        <%= render partial: "listings/listing", locals: { listing: listing } %>

      <% end %>

      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ListingsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>

    <% end %>

    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->ListingsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>

  <% end %>

  <%= render partial: "shared/chat" %>

  <%= tag.section aria-labelledby: "insights-heading" do %>

    <%= tag.h2 t("brgen.insights_title"), id: "insights-heading" %>

    <%= tag.div data: { controller: "insights" } do %>

      <%= tag.button t("brgen.get_insights"), data: { action: "click->insights#analyze" }, "aria-label": t("brgen.get_insights") %>

      <%= tag.div id: "insights-output", data: { "insights-target": "output" } %>

    <% end %>

  <% end %>

<% end %>

<%= render "shared/footer" %>

EOF

cat <<EOF > config/locales/en.yml
en:

  brgen:

    home_title: "Brgen - Connect Locally"

    home_description: "Join your local Brgen community to share posts, trade items, and connect with neighbors in #{ActsAsTenant.current_tenant&.name || 'your city'}."

    home_keywords: "brgen, community, marketplace, #{ActsAsTenant.current_tenant&.name}"

    post_title: "Share What's Happening"

    posts_title: "Community Posts"

    posts_description: "Explore posts from your #{ActsAsTenant.current_tenant&.name} community."

    new_post_title: "Create a Post"

    new_post_description: "Share an update or idea with your community."

    edit_post_title: "Edit Your Post"

    edit_post_description: "Update your community post."

    post_created: "Post shared successfully."

    post_updated: "Post updated successfully."

    post_deleted: "Post removed successfully."

    listing_title: "Item Title"

    listing_description: "Item Description"

    listing_price: "Price"

    listing_category: "Category"

    listing_status: "Status"

    listing_location: "Location"

    listing_lat: "Latitude"

    listing_lng: "Longitude"

    listing_photos: "Photos"

    listing_title_help: "Enter a clear title for your item."

    listing_description_help: "Describe your item in detail."

    listing_price_help: "Set the price for your item."

    listing_category_help: "Choose a category for your item."

    listing_status_help: "Select the current status of your item."

    listing_location_help: "Specify the pickup location."

    listing_lat_help: "Enter the latitude for the location."

    listing_lng_help: "Enter the longitude for the location."

    listings_title: "Marketplace Listings"

    listings_description: "Browse items for sale in #{ActsAsTenant.current_tenant&.name}."

    new_listing_title: "Create a Listing"

    new_listing_description: "Add an item to the marketplace."

    edit_listing_title: "Edit Listing"

    edit_listing_description: "Update your marketplace listing."

    listing_created: "Listing created successfully."

    listing_updated: "Listing updated successfully."

    listing_deleted: "Listing removed successfully."

    listing_photo: "Photo of %{title}"

    cities_title: "Brgen Cities"

    cities_description: "Explore Brgen communities across the globe."

    new_city_title: "Add a City"

    new_city_description: "Create a new Brgen community."

    edit_city_title: "Edit City"

    edit_city_description: "Update city details."

    city_title: "%{name} Community"

    city_description: "Connect with the Brgen community in %{name}."

    city_created: "City added successfully."

    city_updated: "City updated successfully."

    city_deleted: "City removed successfully."

    city_name: "City Name"

    city_subdomain: "Subdomain"

    city_country: "Country"

    city_city: "City"

    city_language: "Language"

    city_tld: "TLD"

    city_favicon: "Favicon"

    city_analytics: "Analytics"

    city_name_help: "Enter the full city name."

    city_subdomain_help: "Choose a unique subdomain."

    city_country_help: "Specify the country."

    city_city_help: "Enter the city name."

    city_language_help: "Set the primary language code."

    city_tld_help: "Enter the top-level domain."

    city_favicon_help: "Optional favicon URL."

    city_analytics_help: "Optional analytics ID."

    tenant_not_found: "Community not found."

    not_authorized: "You are not authorized to perform this action."

    errors: "%{count} error(s) prevented this action."

    logo_alt: "Brgen Logo"

    logo_title: "Brgen Community Platform"

    map_title: "Local Listings Map"

    search_title: "Search Community"

    search_placeholder: "Search posts or listings..."

    status_prompt: "Select status"

    confirm_delete: "Are you sure you want to delete this?"

    analyzing: "Analyzing..."

    insights_title: "Community Insights"

    get_insights: "Get Insights"

    posted_by: "Posted by %{user}"

    view_post: "View Post"

    edit_post: "Edit Post"

    delete_post: "Delete Post"

    view_listing: "View Listing"

    edit_listing: "Edit Listing"

    delete_listing: "Delete Listing"

    new_post: "New Post"

    new_listing: "New Listing"

    new_city: "New City"

    edit_city: "Edit City"

    delete_city: "Delete City"

    view_posts: "View Posts"

    view_listings: "View Listings"

EOF

cat <<EOF > db/seeds.rb
cities = [

  { name: "Bergen", subdomain: "brgen", country: "Norway", city: "Bergen", language: "no", tld: "no" },

  { name: "Oslo", subdomain: "oshlo", country: "Norway", city: "Oslo", language: "no", tld: "no" },

  { name: "Trondheim", subdomain: "trndheim", country: "Norway", city: "Trondheim", language: "no", tld: "no" },

  { name: "Stavanger", subdomain: "stvanger", country: "Norway", city: "Stavanger", language: "no", tld: "no" },

  { name: "Tromsø", subdomain: "trmso", country: "Norway", city: "Tromsø", language: "no", tld: "no" },

  { name: "Longyearbyen", subdomain: "longyearbyn", country: "Norway", city: "Longyearbyen", language: "no", tld: "no" },

  { name: "Reykjavík", subdomain: "reykjavk", country: "Iceland", city: "Reykjavík", language: "is", tld: "is" },

  { name: "Copenhagen", subdomain: "kbenhvn", country: "Denmark", city: "Copenhagen", language: "dk", tld: "dk" },

  { name: "Stockholm", subdomain: "stholm", country: "Sweden", city: "Stockholm", language: "se", tld: "se" },

  { name: "Gothenburg", subdomain: "gtebrg", country: "Sweden", city: "Gothenburg", language: "se", tld: "se" },

  { name: "Malmö", subdomain: "mlmoe", country: "Sweden", city: "Malmö", language: "se", tld: "se" },

  { name: "Helsinki", subdomain: "hlsinki", country: "Finland", city: "Helsinki", language: "fi", tld: "fi" },

  { name: "London", subdomain: "lndon", country: "UK", city: "London", language: "en", tld: "uk" },

  { name: "Cardiff", subdomain: "cardff", country: "UK", city: "Cardiff", language: "en", tld: "uk" },

  { name: "Manchester", subdomain: "mnchester", country: "UK", city: "Manchester", language: "en", tld: "uk" },

  { name: "Birmingham", subdomain: "brmingham", country: "UK", city: "Birmingham", language: "en", tld: "uk" },

  { name: "Liverpool", subdomain: "lverpool", country: "UK", city: "Liverpool", language: "en", tld: "uk" },

  { name: "Edinburgh", subdomain: "edinbrgh", country: "UK", city: "Edinburgh", language: "en", tld: "uk" },

  { name: "Glasgow", subdomain: "glasgw", country: "UK", city: "Glasgow", language: "en", tld: "uk" },

  { name: "Amsterdam", subdomain: "amstrdam", country: "Netherlands", city: "Amsterdam", language: "nl", tld: "nl" },

  { name: "Rotterdam", subdomain: "rottrdam", country: "Netherlands", city: "Rotterdam", language: "nl", tld: "nl" },

  { name: "Utrecht", subdomain: "utrcht", country: "Netherlands", city: "Utrecht", language: "nl", tld: "nl" },

  { name: "Brussels", subdomain: "brssels", country: "Belgium", city: "Brussels", language: "nl", tld: "be" },

  { name: "Zürich", subdomain: "zrich", country: "Switzerland", city: "Zurich", language: "de", tld: "ch" },

  { name: "Vaduz", subdomain: "lchtenstein", country: "Liechtenstein", city: "Vaduz", language: "de", tld: "li" },

  { name: "Frankfurt", subdomain: "frankfrt", country: "Germany", city: "Frankfurt", language: "de", tld: "de" },

  { name: "Warsaw", subdomain: "wrsawa", country: "Poland", city: "Warsaw", language: "pl", tld: "pl" },

  { name: "Gdańsk", subdomain: "gdnsk", country: "Poland", city: "Gdańsk", language: "pl", tld: "pl" },

  { name: "Bordeaux", subdomain: "brdeaux", country: "France", city: "Bordeaux", language: "fr", tld: "fr" },

  { name: "Marseille", subdomain: "mrseille", country: "France", city: "Marseille", language: "fr", tld: "fr" },

  { name: "Milan", subdomain: "mlan", country: "Italy", city: "Milan", language: "it", tld: "it" },

  { name: "Lisbon", subdomain: "lsbon", country: "Portugal", city: "Lisbon", language: "pt", tld: "pt" },

  { name: "Los Angeles", subdomain: "lsangeles", country: "USA", city: "Los Angeles", language: "en", tld: "org" },

  { name: "New York", subdomain: "newyrk", country: "USA", city: "New York", language: "en", tld: "org" },

  { name: "Chicago", subdomain: "chcago", country: "USA", city: "Chicago", language: "en", tld: "org" },

  { name: "Houston", subdomain: "houstn", country: "USA", city: "Houston", language: "en", tld: "org" },

  { name: "Dallas", subdomain: "dllas", country: "USA", city: "Dallas", language: "en", tld: "org" },

  { name: "Austin", subdomain: "austn", country: "USA", city: "Austin", language: "en", tld: "org" },

  { name: "Portland", subdomain: "prtland", country: "USA", city: "Portland", language: "en", tld: "org" },

  { name: "Minneapolis", subdomain: "mnnesota", country: "USA", city: "Minneapolis", language: "en", tld: "org" }

]

cities.each do |city|
  City.find_or_create_by(subdomain: city[:subdomain]) do |c|

    c.name = city[:name]

    c.country = city[:country]

    c.city = city[:city]

    c.language = city[:language]

    c.tld = city[:tld]

  end

end

puts "Seeded #{cities.count} cities."
# Create demo users with Faker
require "faker"

demo_users = []
5.times do

  demo_users << User.create!(

    email: Faker::Internet.unique.email,

    password: "password123",

    name: Faker::Name.name

  )

end

puts "Created #{demo_users.count} demo users with Faker."
# Seed sample data for each city
cities.each do |city_data|

  city = City.find_by(subdomain: city_data[:subdomain])

  next unless city

  ActsAsTenant.with_tenant(city) do
    # Create 10 posts per city

    10.times do

      user = demo_users.sample

      Post.create!(

        title: Faker::Lorem.sentence(word_count: 5),

        content: Faker::Lorem.paragraph(sentence_count: 5),

        user: user,

        community: city

      )

    end

    # Create 5 listings per city
    5.times do

      user = demo_users.sample

      Listing.create!(

        title: Faker::Commerce.product_name,

        description: Faker::Lorem.paragraph(sentence_count: 3),

        price: Faker::Commerce.price(range: 10.0..1000.0),

        category: Faker::Commerce.department,

        status: ["available", "sold"].sample,

        user: user,

        location: "#{city_data[:city]}, #{city_data[:country]}",

        lat: Faker::Address.latitude,

        lng: Faker::Address.longitude,

        community: city

      )

    end

  end

end

puts "Seeded posts and listings for all cities with Faker data."
EOF

mkdir -p app/views/brgen_logo
cat <<EOF > app/views/brgen_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("brgen.logo_alt") do %>

  <%= tag.title t("brgen.logo_title", default: "Brgen Logo") %>

  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "20", fill: "#1a73e8" do %>Brgen<% end %>

<% end %>

EOF

# Replace the simple Falcon config from openbsd.sh with a full Rails integration
cat <<'EOF' > config/falcon.rb

#!/usr/bin/env ruby

require 'async'

require 'async/http/endpoint'

require 'async/http/server'

require 'rack'

ENV["RAILS_ENV"] ||= "production"
port = ENV.fetch("PORT", 11006).to_i

# Load the Rails application
require_relative '../config/environment'

app = Rails.application
Async do
  endpoint = Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")

    .with(protocol: Async::HTTP::Protocol::HTTP11)

  bound_endpoint = endpoint.bound

  puts "Falcon serving Brgen Rails app on port #{port}"
  puts "Environment: #{Rails.env}"

  puts "Serving domains: #{ENV['DOMAINS']}"

  Async::HTTP::Server.new(app, bound_endpoint).run
end

EOF

chmod +x config/falcon.rb
# Create a startup script for easy deployment
cat <<EOF > bin/falcon-host

#!/bin/ksh

export RAILS_ENV=production

export PORT=$BRGEN_PORT

cd "$APP_DIR"

exec /usr/local/bin/ruby config/falcon.rb

EOF

chmod +x bin/falcon-host
commit "Brgen core setup complete: Multi-tenant social and marketplace platform"
log "Brgen core setup complete."
log "App deployed to: $APP_DIR"

log "App will run on port: $BRGEN_PORT"

log "Falcon server: bin/falcon-host or config/falcon.rb"

log "The openbsd.sh script has already set up the service via rcctl."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments

# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon

# - Leveraged bin/rails generate scaffold for Listings and Cities to reduce manual code

# - Extracted header and footer into shared partials

# - Reused anonymous posting and live chat from __shared.sh

# - Added Mapbox for listings, live search, and infinite scroll

# - Fixed tenant TLDs with .org for US cities

# - Ensured NNG, SEO, schema data, and minimal flat design compliance

# - Finalized for unprivileged user on OpenBSD 7.5

