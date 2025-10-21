# Rails Shared Layouts Documentation

## Overview

This document describes the shared layout system for all Rails applications in the pub3 repository. The shared layouts provide a consistent, reusable foundation while allowing per-app customization.

## Directory Structure

```
rails/__shared/layouts/
├── application.html.erb          # Base layout template
├── _meta.html.erb                # SEO, mobile, PWA meta tags
├── _nav.html.erb                 # Navigation header
├── _flash.html.erb               # Flash message component
├── _footer.html.erb              # Footer component
├── _skip_links.html.erb          # Accessibility skip links
├── visualizer.css                # Audio visualizer styles
├── visualizer.js                 # Audio visualizer logic
├── visualizer_controller.rb      # Visualizer controller template
├── visualizer_index.html.erb     # Visualizer view template
└── visualizer_layout.html.erb    # Minimal layout for visualizer
```

## Installation

### Using install_shared_layouts()

The `@common.sh` script provides a helper function to install shared layouts:

```bash
source "./__shared/@common.sh"

# Install with app-specific configuration
install_shared_layouts "AppName" "#theme_color" "App description"
```

**Parameters:**
- `app_name`: Display name for the application (e.g., "Brgen", "Amber")
- `theme_color`: Hex color for theme-color meta tag (e.g., "#1a1a1a")
- `app_description`: Short description for meta description tag

**Example:**
```bash
install_shared_layouts "Brgen" "#1a1a1a" "Multi-tenant social and marketplace platform"
```

### What Gets Installed

The function creates:
- `app/views/layouts/application.html.erb` - Main layout
- `app/views/shared/_meta.html.erb` - Meta tags partial
- `app/views/shared/_nav.html.erb` - Navigation partial
- `app/views/shared/_flash.html.erb` - Flash messages partial
- `app/views/shared/_footer.html.erb` - Footer partial
- `app/views/shared/_skip_links.html.erb` - Skip links partial
- Updates `app/controllers/application_controller.rb` with app variables

## Layout Structure

### Base Layout (application.html.erb)

```erb
<!DOCTYPE html>
<html lang="<%= I18n.locale rescue 'en' %>" dir="ltr">
<head>
  <%= render "shared/meta" %>
  <%= yield :head %>
</head>
<body data-controller="<%= controller_name rescue 'application' %>" 
      class="<%= body_classes rescue "#{controller_name} #{action_name}" %>">
  <%= render "shared/skip_links" %>
  <%= render "shared/nav" %>
  
  <main id="main-content" class="site-main">
    <%= render "shared/flash" %>
    <%= yield %>
  </main>
  
  <%= render "shared/footer" %>
  <%= yield :scripts %>
</body>
</html>
```

### Customization Points

#### 1. Override Entire Partials

Replace a partial with app-specific content:

```bash
cat > app/views/shared/_nav.html.erb << 'NAV_EOF'
<header class="custom-header">
  <!-- Your custom navigation -->
</header>
NAV_EOF
```

#### 2. Use content_for Blocks

Add content from views using `content_for`:

```erb
<%# In your view %>
<% content_for :nav_links do %>
  <%= link_to "Features", features_path, class: "nav-link" %>
  <%= link_to "Pricing", pricing_path, class: "nav-link" %>
<% end %>
```

Available blocks:
- `:title` - Page title
- `:head` - Additional head content
- `:nav_links` - Navigation links
- `:footer_content` - Footer content
- `:scripts` - Additional scripts

#### 3. Set App Variables

Variables available in views (set by ApplicationController):

```ruby
@app_name = "Your App Name"
@theme_color = "#hexcolor"
@app_description = "Your app description"
```

## Component Details

### Meta Tags (_meta.html.erb)

Includes:
- Character encoding (UTF-8)
- Viewport for mobile (with safe-area-insets)
- CSRF and CSP meta tags
- Dynamic title and description
- Theme color
- PWA capabilities
- Stylesheet and JavaScript imports

### Navigation (_nav.html.erb)

Features:
- Responsive navigation structure
- App name/logo display
- ActsAsTenant support for multi-tenancy
- User authentication state handling
- Customizable nav links via `content_for :nav_links`

### Flash Messages (_flash.html.erb)

Handles:
- Standard Rails flash (notice, alert)
- Additional flash types (success, error, warning, info)
- Auto-dismiss functionality (when Stimulus controller added)
- Accessible with ARIA roles

### Footer (_footer.html.erb)

Provides:
- Copyright year (auto-updated)
- Standard links (Privacy, Terms, About)
- Customizable via `content_for :footer_content`

### Skip Links (_skip_links.html.erb)

Accessibility feature:
- Allows keyboard users to skip navigation
- Jumps to `#main-content`

## Standards

### Required Meta Tags
- `charset="UTF-8"`
- `viewport` with `viewport-fit=cover`
- `csrf_meta_tags`
- `csp_meta_tag`

### Accessibility
- ✅ Skip links for keyboard navigation
- ✅ ARIA labels on navigation
- ✅ Semantic HTML5 elements
- ✅ Role attributes on interactive elements
- ✅ Focus-visible styles

### Performance
- ✅ Turbo enabled by default
- ✅ Import maps for JavaScript
- ✅ Propshaft asset pipeline
- ✅ Data-turbo-track for cache busting

### Mobile Support
- ✅ Responsive viewport
- ✅ Safe area insets (for notched devices)
- ✅ PWA meta tags
- ✅ Touch-friendly navigation

## Audio Visualizer Integration

### For brgen_playlist

The visualizer integration adds:

**Controller:** `app/controllers/visualizer_controller.rb`
```ruby
class VisualizerController < ApplicationController
  def index
    @cities = load_cities
    @tracks = Track.limit(20)
    render layout: 'visualizer'
  end
  
  def playlist
    tracks = Track.order(:position)
    render json: tracks.map { |t| { artist: t.artist, title: t.title, src: t.audio_url } }
  end
end
```

**Routes:**
```ruby
get '/visualizer', to: 'visualizer#index'
get '/visualizer/playlist', to: 'visualizer#playlist'
```

**Assets:**
- `app/assets/stylesheets/visualizer.css` - Full visualizer styles
- `app/assets/javascripts/visualizer.js` - Complete audio engine and visualization logic

**Features:**
- Warp tunnel audio-reactive visualization
- Dual audio engines (YouTube + MP3)
- 40+ city carousel rotation
- 8 visualization modes with auto-switching
- Beat detection and spectral analysis
- Mobile gestures (swipe, pinch, tilt)
- Performance-adaptive rendering

## App-Specific Examples

### Brgen (Multi-tenant Platform)

```bash
install_shared_layouts "Brgen" "#1a1a1a" "Multi-tenant social and marketplace platform"

# Add custom nav links
cat >> app/views/shared/_nav.html.erb << 'EOF'
<% content_for :nav_links do %>
  <%= link_to t("nav.listings"), listings_path, class: "nav-link" %>
  <%= link_to t("nav.cities"), cities_path, class: "nav-link" %>
<% end %>
EOF
```

### Amber (Fashion Assistant)

```bash
install_shared_layouts "Amber" "#D4A574" "AI-powered fashion and wardrobe assistant"

# Completely override nav and footer for custom branding
cat > app/views/shared/_nav.html.erb << 'EOF'
# Custom navigation with fashion-specific links
EOF
```

### BAIBL (Norwegian Bible App)

```bash
# BAIBL uses custom Norwegian layout
# See baibl.sh for full implementation
```

### MyToonz (Comic Generator)

```bash
# MyToonz uses minimal layout (no header/footer)
# Full-screen comic generation interface
```

## Migration Guide

### From Embedded Layouts

**Before:**
```bash
cat <<'LAYOUTEOF' > app/views/layouts/application.html.erb
<!DOCTYPE html>
<html>
  <!-- 70+ lines of layout code -->
</html>
LAYOUTEOF
```

**After:**
```bash
install_shared_layouts "MyApp" "#color" "Description"

# Optional: Add custom nav links
cat >> app/views/shared/_nav.html.erb << 'EOF'
<% content_for :nav_links do %>
  <%= link_to "Custom Link", path %>
<% end %>
EOF
```

## Troubleshooting

### Layout Not Found
- Ensure `install_shared_layouts()` is called after `cd "$APP_DIR"`
- Verify `__shared/layouts/` directory exists in installer directory

### Partials Not Rendering
- Check that `app/views/shared/` directory was created
- Verify partial names start with underscore (`_meta.html.erb`)

### App Variables Not Set
- Ensure ApplicationController includes `before_action :set_app_variables`
- Check that `@app_name`, `@theme_color`, `@app_description` are defined

### CSS/JS Not Loading
- Verify asset pipeline is configured (importmap, propshaft)
- Check `stylesheet_link_tag` and `javascript_importmap_tags` are in meta partial

## Best Practices

1. **Use shared layouts as base** - Override only what you need
2. **Leverage content_for** - Add view-specific content without changing layouts
3. **Keep partials small** - Each partial should have a single responsibility
4. **Maintain accessibility** - Keep skip links, ARIA labels, semantic HTML
5. **Test responsiveness** - Verify mobile, tablet, and desktop layouts
6. **Document customizations** - Comment why custom layouts were needed

## Future Enhancements

- [ ] Add dark mode toggle component
- [ ] Create additional layout variants (admin, authentication)
- [ ] Stimulus controllers for flash auto-dismiss
- [ ] SEO optimization helpers
- [ ] Open Graph and Twitter Card meta tags
- [ ] Internationalization (i18n) support improvements

## Related Files

- `rails/__shared/@common.sh` - Contains `install_shared_layouts()` function
- `master.json` - Rails configuration and standards
- Individual installer scripts (brgen.sh, amber.sh, etc.)

## Support

For questions or issues:
1. Check `master.json` for standards and conventions
2. Review individual installer implementations
3. Refer to Rails guides for layout and partial rendering

---

**Last Updated:** 2025-10-21  
**Version:** 1.0.0
