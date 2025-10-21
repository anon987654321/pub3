# Audio Visualizer Integration Guide

## Overview

The brgen_playlist audio visualizer is a sophisticated, audio-reactive warp tunnel visualization system extracted from `pub3/index.html` and integrated into the Rails ecosystem.

## Features

### Audio Engine
- **Dual Audio Sources**: YouTube API + MP3/M3U playlists
- **Smart Fallback**: Automatically switches between sources
- **Crossfade Support**: Smooth transitions between tracks
- **Beat Detection**: Real-time BPM analysis
- **Spectral Analysis**: Frequency-based visual effects

### Visualization
- **8 Visualization Modes**: Tunnel, spiral, plasma, kaleidoscope, grid, particles, fractal, waves
- **Auto Mode Switching**: Changes visualization based on audio characteristics
- **Psychedelic Effects**: Color cycling, inversion, rotation
- **Performance Adaptive**: DPR scaling, frame skipping for low-end devices

### User Experience
- **40+ City Carousel**: Rotating display of brgen city domains
- **Mobile Gestures**: 
  - Swipe left/right: Change tracks
  - Pinch: Zoom in/out
  - Tilt: Parallax effect
- **Keyboard Controls**: Arrow keys, space bar, number keys
- **Accessibility**: Full ARIA labels, keyboard navigation, screen reader support

## Installation

### Automatic Installation (Recommended)

The `brgen_playlist.sh` installer automatically sets up the visualizer:

```bash
cd rails
source ./__shared/@common.sh
zsh brgen_playlist.sh
```

This creates:
- `app/controllers/visualizer_controller.rb`
- `app/views/visualizer/index.html.erb`
- `app/views/layouts/visualizer.html.erb`
- `app/assets/stylesheets/visualizer.css`
- `app/assets/javascripts/visualizer.js`
- Routes: `/visualizer` and `/visualizer/playlist`

### Manual Installation

If you need to add the visualizer to an existing Rails app:

```bash
# Copy controller template
cp rails/__shared/layouts/visualizer_controller.rb app/controllers/

# Copy view templates
mkdir -p app/views/visualizer
cp rails/__shared/layouts/visualizer_index.html.erb app/views/visualizer/index.html.erb

# Copy layout
mkdir -p app/views/layouts
cp rails/__shared/layouts/visualizer_layout.html.erb app/views/layouts/visualizer.html.erb

# Copy assets
mkdir -p app/assets/stylesheets app/assets/javascripts
cp rails/__shared/layouts/visualizer.css app/assets/stylesheets/
cp rails/__shared/layouts/visualizer.js app/assets/javascripts/

# Add routes
cat >> config/routes.rb << 'EOF'
  get '/visualizer', to: 'visualizer#index'
  get '/visualizer/playlist', to: 'visualizer#playlist'
EOF
```

## Configuration

### Controller Customization

Edit `app/controllers/visualizer_controller.rb`:

```ruby
class VisualizerController < ApplicationController
  # Skip authentication for public access
  skip_before_action :authenticate_user!, only: [:index, :playlist]
  
  def index
    # Customize cities for carousel
    @cities = City.active.pluck(:subdomain, :name)
    
    # Load tracks from database or use featured tracks
    @tracks = if user_signed_in?
                current_user.playlist_tracks
              else
                Track.featured.limit(20)
              end
    
    render layout: 'visualizer'
  end
  
  def playlist
    # Return JSON playlist for visualizer
    tracks = Track.order(:position).limit(50)
    
    render json: tracks.map { |t|
      {
        artist: t.artist,
        title: t.title,
        src: track_audio_url(t),      # MP3 URL
        id: t.youtube_id               # YouTube video ID
      }
    }
  end
  
  private
  
  def track_audio_url(track)
    if track.audio_file.attached?
      rails_blob_url(track.audio_file)
    else
      track.audio_url
    end
  end
end
```

### City Carousel

The carousel displays cycling city/subdomain names. Customize in controller:

```ruby
def load_cities
  # From database
  City.active.pluck(:subdomain, :name)
  
  # Or hardcoded
  [
    ['bergen', 'Bergen'],
    ['oslo', 'Oslo'],
    ['trondheim', 'Trondheim']
    # ... more cities
  ]
end
```

Cities are displayed as: `playlist.{subdomain}.{domain}`

### Playlist Formats

The visualizer supports multiple playlist formats:

#### 1. JSON Playlist (Recommended)
```json
[
  {
    "artist": "J Dilla",
    "title": "Microphone Master",
    "id": "9EGHwkDix78"
  },
  {
    "artist": "Flying Lotus",
    "title": "Massage Situation",
    "src": "/audio/track.mp3"
  }
]
```

- `id`: YouTube video ID (prioritized if present)
- `src`: Direct MP3 URL (fallback)
- `artist`, `title`: Display metadata

#### 2. M3U Playlist
```m3u
#EXTM3U
#EXTINF:180,Artist - Title
/audio/track1.mp3
#EXTINF:210,Artist 2 - Title 2
/audio/track2.mp3
```

#### 3. index.json (File Listing)
```json
{
  "files": [
    "track1.mp3",
    "track2.mp3",
    "track3.mp3"
  ]
}
```

The visualizer automatically detects and parses these formats.

## Visual Modes

The visualizer includes 8 distinct visualization modes:

1. **Tunnel** (Default)
   - Classic warp tunnel effect
   - Depth-based color gradients
   - Perspective-correct rendering

2. **Spiral**
   - Rotating spiral patterns
   - Audio-reactive twist amount
   - Golden ratio spiral math

3. **Plasma**
   - Smooth color gradients
   - Sine wave patterns
   - Retro demo-scene aesthetic

4. **Kaleidoscope**
   - Mirrored symmetry
   - 4/6/8-way reflections
   - Beat-synced rotation

5. **Grid**
   - 3D wireframe grid
   - Audio-reactive distortion
   - Perspective warping

6. **Particles**
   - Particle system
   - Audio-reactive acceleration
   - Trail effects

7. **Fractal**
   - Recursive pattern generation
   - Mandelbrot-inspired
   - Zoom and rotation

8. **Waves**
   - Sine wave displacement
   - Frequency band mapping
   - Ripple effects

Modes auto-switch based on:
- Beat intensity
- Frequency spectrum
- User preference (number keys 1-8)

## Performance Optimization

### Device Detection
```javascript
const isLowEnd = 
  (navigator.hardwareConcurrency <= 2) || 
  (navigator.deviceMemory <= 2);
```

### Adaptive Rendering
- **High-end devices**: Full DPR (2x), 60fps
- **Low-end devices**: DPR 1x, 30fps, frame skipping
- **Battery saving**: Reduced effects when battery < 20%

### Mobile Optimizations
- Touch-optimized controls
- Reduced particle count
- Simplified shaders
- Hardware acceleration hints

## Keyboard Controls

- **Space**: Play/Pause
- **←/→**: Previous/Next track
- **↑/↓**: Volume up/down
- **1-8**: Switch visualization mode
- **I**: Invert colors
- **M**: Mute
- **F**: Toggle fullscreen (where supported)
- **Esc**: Exit overlay/fullscreen

## Mobile Gestures

- **Swipe Left**: Next track
- **Swipe Right**: Previous track
- **Pinch In/Out**: Zoom visualization
- **Tilt Device**: Parallax effect
- **Double Tap**: Play/pause

## Accessibility

### Screen Reader Support
- Descriptive ARIA labels
- Live region updates for track changes
- Status announcements

### Keyboard Navigation
- Full keyboard control
- Visible focus indicators
- Skip links for screen readers

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}
```

Respects user's motion preferences.

## API Integration

### Track Model Requirements

```ruby
class Track < ApplicationRecord
  belongs_to :user
  has_one_attached :audio_file
  
  # Required fields
  validates :title, presence: true
  validates :artist, presence: true
  
  # Optional fields
  # youtube_id: string (YouTube video ID)
  # audio_url: string (external MP3 URL)
  # duration: integer (seconds)
  # album: string
  # position: integer (playlist order)
  
  scope :featured, -> { where(featured: true).order(:position) }
  
  def audio_source
    if youtube_id.present?
      { type: 'youtube', id: youtube_id }
    elsif audio_file.attached?
      { type: 'mp3', src: Rails.application.routes.url_helpers.rails_blob_url(audio_file) }
    elsif audio_url.present?
      { type: 'mp3', src: audio_url }
    end
  end
end
```

### Playlist Endpoint

```ruby
def playlist
  tracks = Track.includes(:user).order(:position).limit(50)
  
  render json: {
    tracks: tracks.map { |t|
      {
        id: t.id,
        artist: t.artist,
        title: t.title,
        album: t.album,
        duration: t.duration,
        **t.audio_source
      }
    },
    meta: {
      total: tracks.count,
      generated_at: Time.current
    }
  }
end
```

## Deployment Considerations

### Content Security Policy

Update `config/initializers/content_security_policy.rb`:

```ruby
Rails.application.config.content_security_policy do |policy|
  # Allow YouTube iframe API
  policy.frame_src :self, 'https://www.youtube.com'
  
  # Allow YouTube assets
  policy.script_src :self, :https, 'https://www.youtube.com'
  policy.connect_src :self, :https, 'https://www.youtube.com'
  
  # For visualizer canvas
  policy.img_src :self, :https, :data
end
```

### Asset Precompilation

Ensure visualizer assets are included:

```ruby
# config/initializers/assets.rb
Rails.application.config.assets.precompile += %w[
  visualizer.css
  visualizer.js
]
```

### CORS for Audio Files

If serving audio from different domain:

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/audio/*',
      headers: :any,
      methods: [:get, :head, :options]
  end
end
```

## Troubleshooting

### Visualizer Not Loading
1. Check JavaScript console for errors
2. Verify `visualizer.js` is included in layout
3. Ensure canvas element exists: `<canvas id="canvas">`
4. Check Content Security Policy settings

### No Audio Playback
1. Verify playlist endpoint returns valid JSON
2. Check audio file URLs are accessible
3. Test YouTube API key (if using YouTube)
4. Verify CORS headers for cross-origin audio

### Performance Issues
1. Lower DPR in visualizer.js: `const DPR = 1`
2. Reduce particle count
3. Enable frame skipping
4. Use simpler visualization modes

### Mobile Issues
1. Ensure viewport meta tag includes `viewport-fit=cover`
2. Test touch event handlers
3. Verify safe area insets are applied
4. Check for iOS-specific audio autoplay restrictions

## Examples

### Basic Integration
```erb
<%# app/views/playlists/show.html.erb %>
<div class="playlist-header">
  <h1><%= @playlist.name %></h1>
  <%= link_to "Visualizer", visualizer_path, class: "btn-primary" %>
</div>
```

### Embed in Player
```erb
<%# app/views/player/show.html.erb %>
<div class="player-container">
  <div class="audio-controls">
    <!-- Standard player UI -->
  </div>
  
  <%= link_to visualizer_path, class: "visualizer-toggle", 
              data: { turbo_frame: "visualizer" } do %>
    🎨 Enable Visualizer
  <% end %>
  
  <%= turbo_frame_tag "visualizer" %>
</div>
```

### API-Only Mode
```ruby
# For external clients
class Api::V1::VisualizerController < ApiController
  def playlist
    tracks = Track.includes(:audio_file).limit(100)
    
    render json: {
      version: '1.0',
      playlist: tracks.map(&:to_visualizer_json),
      cities: City.active.pluck(:subdomain, :name)
    }
  end
end
```

## Future Enhancements

- [ ] WebGL 2.0 shaders for advanced effects
- [ ] Live audio input (microphone) support
- [ ] Playlist sharing and collaboration
- [ ] User-created visualization modes
- [ ] VR/AR visualization modes
- [ ] AI-generated visuals based on lyrics
- [ ] Social features (reactions, comments on moments)

## Related Files

- `rails/__shared/layouts/visualizer.js` - Main visualizer logic
- `rails/__shared/layouts/visualizer.css` - Visualizer styles
- `rails/__shared/layouts/visualizer_controller.rb` - Controller template
- `pub3/index.html` - Original standalone implementation
- `master.json` - Configuration and standards

## License

Part of the pub3 repository.  
See LICENSE for details.

---

**Last Updated:** 2025-10-21  
**Version:** 1.0.0
