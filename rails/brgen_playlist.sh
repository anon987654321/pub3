#!/usr/bin/env zsh
set -euo pipefail

# Brgen Playlist: Adds music playlist features to existing Brgen app
# This extends brgen.sh - run brgen.sh first to create the base app with Devise

APP_NAME="brgen"
BASE_DIR="/home/brgen"

APP_DIR="${BASE_DIR}/app"

BRGEN_IP="185.52.176.18"

source "./__shared/@common.sh"
log "Adding Playlist features to existing Brgen app (User model from brgen.sh)"
# Navigate to existing brgen app (created by brgen.sh with Devise already configured)
if [[ ! -d "$APP_DIR" ]]; then

  log "ERROR: Brgen app not found at $APP_DIR. Run brgen.sh first."

  exit 1

fi

if [[ ! -f "$APP_DIR/config/application.rb" ]]; then
  log "ERROR: Rails app not initialized. Run brgen.sh first."

  exit 1

fi

cd "$APP_DIR"
log "Working in app directory: $APP_DIR"

command_exists "ruby"
command_exists "node"

command_exists "psql"

command_exists "redis-server"

install_gem "faker"
# Add playlist models (user:references works because brgen.sh created users table)
bin/rails generate scaffold Playlist name:string description:text user:references public:boolean

bin/rails generate model PlaylistTrack playlist:references track:references position:integer

bin/rails generate scaffold Track title:string artist:string album:string duration:integer audio_file:attachment user:references

bin/rails db:migrate

# Add Visualizer Controller
log "Adding audio visualizer integration"
mkdir -p app/controllers
cp "${SCRIPT_DIR}/__shared/layouts/visualizer_controller.rb" app/controllers/visualizer_controller.rb 2>/dev/null || {
  log "Creating visualizer controller from template"
  cat > app/controllers/visualizer_controller.rb << 'VCTRL_EOF'
# VisualizerController - Audio visualizer for brgen_playlist
class VisualizerController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:playlist]
  
  def index
    @cities = load_cities
    @tracks = Track.limit(20)
    render layout: 'visualizer'
  end
  
  def playlist
    tracks = Track.order(:position).limit(50)
    render json: tracks.map { |t|
      { artist: t.artist, title: t.title, src: asset_path(t.audio_file) }
    }
  end
  
  private
  
  def load_cities
    [
      ['brgen', 'Bergen'], ['oshlo', 'Oslo'], ['trndheim', 'Trondheim'],
      ['stvanger', 'Stavanger'], ['trmso', 'Tromsø'], ['longyearbyn', 'Longyearbyen']
    ]
  end
end
VCTRL_EOF
}

# Add Visualizer Views
log "Installing visualizer views"
mkdir -p app/views/visualizer
mkdir -p app/views/layouts
cp "${SCRIPT_DIR}/__shared/layouts/visualizer_index.html.erb" app/views/visualizer/index.html.erb 2>/dev/null || {
  log "Creating visualizer view from template"
  cat > app/views/visualizer/index.html.erb << 'VVIEW_EOF'
<h1 class="city-carousel" id="cityCarousel" aria-live="polite">
  <div class="carousel-container">
    <% @cities.each_with_index do |(subdomain, name), index| %>
      <span class="carousel-slide <%= 'active' if index.zero? %>">playlist.<%= subdomain %>.no</span>
    <% end %>
  </div>
</h1>

<canvas id="canvas" aria-label="Audio-reactive warp tunnel visualizer" tabindex="0"></canvas>
<div id="overlay" class="overlay" role="dialog"><div><h2>Tap to start</h2></div></div>
<div class="ui" id="ui"><span class="label" id="uiLabel">Streaming</span><span class="dots" id="uiDots"></span></div>
VVIEW_EOF
}

cp "${SCRIPT_DIR}/__shared/layouts/visualizer_layout.html.erb" app/views/layouts/visualizer.html.erb 2>/dev/null || {
  log "Creating visualizer layout from template"
  cat > app/views/layouts/visualizer.html.erb << 'VLAYOUT_EOF'
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
  <title>Radio Bergen - Audio Visualizer</title>
  <meta name="theme-color" content="#000000"/>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "visualizer", "data-turbo-track": "reload" %>
</head>
<body><%= yield %><%= javascript_include_tag "visualizer" %></body>
</html>
VLAYOUT_EOF
}

# Copy visualizer assets
log "Installing visualizer assets"
mkdir -p app/assets/stylesheets
mkdir -p app/assets/javascripts
cp "${SCRIPT_DIR}/__shared/layouts/visualizer.css" app/assets/stylesheets/visualizer.css 2>/dev/null || {
  log "WARNING: visualizer.css not found in shared layouts"
}
cp "${SCRIPT_DIR}/__shared/layouts/visualizer.js" app/assets/javascripts/visualizer.js 2>/dev/null || {
  log "WARNING: visualizer.js not found in shared layouts"
}

# Add visualizer route
log "Adding visualizer routes"
cat >> config/routes.rb << 'ROUTES_EOF'

  # Audio Visualizer routes
  get '/visualizer', to: 'visualizer#index'
  get '/visualizer/playlist', to: 'visualizer#playlist'
ROUTES_EOF

log "Brgen Playlist features with audio visualizer added to existing app."
log "Run: bin/rails server -p 11006"
log "Visualizer: http://localhost:11006/visualizer"

