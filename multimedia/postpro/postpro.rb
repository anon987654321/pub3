#!/usr/bin/env ruby
# frozen_string_literal: true

# Postpro.rb - Professional Cinematic Post-Processing
# Version: 14.2.0 - Master.json Optimized

require "logger"
require "json"

require "time"

require "fileutils"

module PostproBootstrap
  def self.dmesg(msg)

    puts "[postpro] #{msg}"

  end

  def self.startup_banner
    ruby_version = RUBY_VERSION

    os = RbConfig::CONFIG["host_os"]

    dmesg "boot ruby=#{ruby_version} os=#{os}"

  end

  def self.ensure_gems
    vips_available = ensure_vips

    tty_available = ensure_tty_prompt

    dmesg "vipsgem=#{vips_available} tty=#{tty_available}"
    { vips: vips_available, tty: tty_available }

  end

  def self.ensure_vips
    require "vips"

    true

  rescue LoadError

    dmesg "WARN ruby-vips gem missing, attempting install..."

    begin

      if system("gem install ruby-vips --no-document")

        require "vips"

        dmesg "OK ruby-vips gem installed"

        true

      else

        dmesg "WARN ruby-vips install failed"

        probe_and_install_libvips

        false

      end

    rescue => e

      dmesg "WARN ruby-vips unavailable: #{e.message}"

      false

    end

  end

  def self.ensure_tty_prompt
    require "tty-prompt"

    true

  rescue LoadError

    dmesg "WARN tty-prompt gem missing, attempting install..."

    begin

      if system("gem install tty-prompt --no-document")

        require "tty-prompt"

        dmesg "OK tty-prompt gem installed"

        true

      else

        dmesg "WARN tty-prompt install failed, degraded prompt experience"

        false

      end

    rescue => e

      dmesg "WARN tty-prompt unavailable: #{e.message}"

      false

    end

  end

  def self.probe_and_install_libvips
    dmesg "probing libvips installation..."

    if system("pkg-config --exists vips 2>/dev/null")
      dmesg "OK libvips already installed"

      return true

    end

    dmesg "WARN libvips not found, attempting installation..."
    # Detect OS and package manager
    os = RbConfig::CONFIG["host_os"]

    success = case os

    when /openbsd/

      # OpenBSD: MUST use pkg_add vips (per VPS requirements)

      if system("which pkg_add > /dev/null 2>&1")

        dmesg "attempting: doas pkg_add vips"

        system("doas pkg_add vips") || system("pkg_add vips")

      else

        dmesg "ERROR pkg_add not found"

        false

      end

    when /darwin/
      if system("which brew > /dev/null 2>&1")

        dmesg "attempting: brew install vips"

        system("brew install vips")

      else

        dmesg "ERROR homebrew not found, install manually: brew install vips"

        false

      end

    when /linux/
      if system("which apt > /dev/null 2>&1")

        dmesg "attempting: apt install libvips-dev libvips42"

        system("sudo apt update && sudo apt install -y libvips-dev libvips42")

      elsif system("which dnf > /dev/null 2>&1")

        dmesg "attempting: dnf install vips-devel"

        system("sudo dnf install -y vips-devel")

      elsif system("which yum > /dev/null 2>&1")

        dmesg "attempting: yum install vips-devel"

        system("sudo yum install -y vips-devel")

      elsif system("which apk > /dev/null 2>&1")

        dmesg "attempting: apk add vips-dev"

        system("sudo apk add vips-dev")

      elsif system("which pacman > /dev/null 2>&1")

        dmesg "attempting: pacman -S libvips"

        system("sudo pacman -S --noconfirm libvips")

      else

        dmesg "ERROR no supported package manager found"

        false

      end

    else
      dmesg "ERROR unsupported OS: #{os}"

      puts "\nManual installation required:"

      puts "  macOS:   brew install vips"

      puts "  Ubuntu:  sudo apt install libvips-dev libvips42"

      puts "  OpenBSD: doas pkg_add vips"

      puts "  Arch:    sudo pacman -S libvips"

      puts "\nDocs: https://libvips.github.io/libvips/install.html"

      false

    end

    # Verify installation
    if system("pkg-config --exists vips 2>/dev/null")

      dmesg "OK libvips installation successful"

      true

    else

      dmesg "ERROR libvips installation failed"

      puts "\n❌ libvips installation failed!"

      puts "Please install manually:"

      puts "  OpenBSD: doas pkg_add vips"

      puts "  macOS:   brew install vips"

      puts "  Ubuntu:  sudo apt install libvips-dev libvips42"

      false

    end

  end

  def self.load_camera_profiles(profiles_path)

    profiles = {}

    unless Dir.exist?(profiles_path)
      dmesg "WARN camera profiles directory not found: #{profiles_path}"

      return profiles

    end

    Dir.glob(File.join(profiles_path, "*.json")).each do |file|
      begin

        data = JSON.parse(File.read(file))

        vendor = data["vendor"]

        if vendor && data["profiles"]

          profiles[vendor] = data["profiles"]

        end

      rescue => e

        dmesg "WARN failed to load profile #{File.basename(file)}: #{e.message}"

      end

    end

    brands = profiles.keys.join(",")
    dmesg "camera_profiles=#{brands.empty? ? 'none' : brands}"

    profiles

  end

  def self.load_master_config
    return {} unless File.exist?("master.json")

    begin
      master = JSON.parse(File.read("master.json").gsub(/^.*\/\/.*$/, ""))

      config = master.dig("config", "multimedia", "postpro") || {}

      dmesg "OK loaded defaults from master.json"

      config

    rescue => e

      dmesg "WARN failed to parse master.json: #{e.message}"

      {}

    end

  end

  def self.run
    startup_banner

    gems = ensure_gems

    unless gems[:vips]
      dmesg "FATAL libvips unavailable - image processing impossible"

      puts "\nPostpro.rb requires libvips for image processing."

      puts "Installation failed. Please install manually:"

      puts "  macOS: brew install vips"

      puts "  Ubuntu/Debian: sudo apt install libvips-dev"

      puts "  OpenBSD: doas pkg_add vips"

      exit 1

    end

    profiles_path = "multimedia/camera_profiles"
    camera_profiles = load_camera_profiles(profiles_path)

    config = load_master_config

    {
      gems: gems,

      camera_profiles: camera_profiles,

      config: config

    }

  end

end

# Initialize postpro
BOOTSTRAP = PostproBootstrap.run

$logger = Logger.new("postpro.log", "daily", level: Logger::DEBUG)

$cli_logger = Logger.new(STDOUT, level: Logger::INFO)

if BOOTSTRAP[:gems][:tty]
  require "tty-prompt"

  PROMPT = TTY::Prompt.new

else

  PROMPT = nil

end

if BOOTSTRAP[:gems][:vips]
  require "vips"

end

REPLIGEN_PRESENT = File.exist?("repligen.rb")
CAMERA_PROFILES = BOOTSTRAP[:camera_profiles]

CONFIG = BOOTSTRAP[:config]

STOCKS = {
  kodak_portra: { grain: 15, gamma: 0.65, rolloff: 0.88, lift: 0.05, matrix: [1.05, -0.02, -0.03, 0.02, 0.98, 0.00, 0.01, -0.05, 1.04] },

  kodak_vision3: { grain: 20, gamma: 0.65, rolloff: 0.85, lift: 0.08, matrix: [1.08, -0.05, -0.03, 0.03, 0.95, 0.02, 0.02, -0.08, 1.06] },

  fuji_velvia: { grain: 8, gamma: 0.75, rolloff: 0.92, lift: 0.03, matrix: [1.12, -0.08, -0.04, 0.05, 1.05, -0.02, 0.01, -0.12, 1.11] },

  tri_x: { grain: 25, gamma: 0.70, rolloff: 0.80, lift: 0.12, matrix: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0] }

}.freeze

PRESETS = {
  portrait: { fx: %w[skin_protect film_curve highlight_roll micro_contrast grain color_temp base_tint], stock: :kodak_portra, temp: 5200, intensity: 0.8 },

  landscape: { fx: %w[film_curve color_separate highlight_roll micro_contrast grain vintage_lens], stock: :fuji_velvia, temp: 5800, intensity: 0.9 },

  street: { fx: %w[film_curve shadow_lift micro_contrast vintage_lens grain], stock: :tri_x, temp: 5600, intensity: 1.0 },

  blockbuster: { fx: %w[teal_orange grain bloom_pro highlight_roll micro_contrast], stock: :kodak_vision3, temp: 4800, intensity: 1.2 }

}.freeze

def safe_cast(image, format = 'uchar')
  image.cast(format)

rescue StandardError => e

  $logger.error "Cast failed: #{e.message}"

  image

end

def rgb_bands(image, bands = 3)
  return image if image.bands == bands

  image.bands < bands ? image.bandjoin([image] * (bands - image.bands)) : image.extract_band(0, n: bands)

end

def load_image(file)
  return nil unless File.exist?(file) && File.readable?(file)

  image = Vips::Image.new_from_file(file, access: :sequential)

  image = image.colourspace("srgb") if image.bands < 3

  rgb_bands(image)

rescue StandardError => e

  $logger.error "Load failed #{file}: #{e.message}"

  nil

end

def get_camera_profile(image)
  return nil if CAMERA_PROFILES.empty?

  begin
    make = image.get("exif-ifd0-Make")&.strip&.downcase

    model = image.get("exif-ifd0-Model")&.strip&.downcase

    return nil unless make && model
    # Try exact model match first
    CAMERA_PROFILES.each do |brand, profiles|

      return profiles[model] if profiles[model]

    end

    # Try brand match
    CAMERA_PROFILES.each do |brand, profiles|

      return profiles.values.first if make.include?(brand) || brand.include?(make)

    end

    nil
  rescue => e

    $logger.debug "EXIF read failed: #{e.message}"

    nil

  end

end

def apply_camera_profile(image, profile)
  return image unless profile && profile["color_matrix"]

  begin
    matrix = profile["color_matrix"]

    return image unless matrix.length == 9

    # Apply 3x3 color matrix
    result = image.recomb([

      [matrix[0], matrix[1], matrix[2]],

      [matrix[3], matrix[4], matrix[5]],

      [matrix[6], matrix[7], matrix[8]]

    ])

    # Apply optional adjustments
    if profile["saturation"]

      hsv = result.colourspace("hsv")

      h, s, v = hsv.bandsplit

      s = s.linear([profile["saturation"]], [0])

      result = Vips::Image.bandjoin([h, s, v]).colourspace("srgb")

    end

    if profile["vibrance"]
      # Simple vibrance simulation

      result = result.linear([1.0 + profile["vibrance"] * 0.1], [0])

    end

    if profile["base_tint"]
      result = base_tint(result, profile["base_tint"], 0.1)

    end

    safe_cast(result)
  rescue => e

    $logger.error "Camera profile failed: #{e.message}"

    image

  end

end

# Professional Color Science
def color_temp(image, kelvin, intensity = 1.0)

  factor = kelvin / 5500.0

  r_mult, g_mult, b_mult = if factor < 1.0

                             [1.0, factor**0.5, factor**2]

                           else

                             [factor**-0.3, 1.0, 1.0 + (factor - 1.0) * 0.5]

                           end

  safe_cast(image.linear([
    1.0 + (r_mult - 1.0) * intensity,

    1.0 + (g_mult - 1.0) * intensity,

    1.0 + (b_mult - 1.0) * intensity

  ], [0, 0, 0]))

end

def skin_protect(image, intensity = 1.0)
  hsv = image.colourspace('hsv')

  h, s, v = hsv.bandsplit

  hue_mask = (h > 25.5) & (h < 63.75)
  sat_mask = (s > 51) & (s < 153)

  skin_mask = hue_mask & sat_mask

  protection = skin_mask.cast('float') / 255.0 * (1.0 - intensity * 0.7)
  protection_rgb = protection.bandjoin([protection, protection])

  safe_cast(image * (1.0 - protection_rgb) + image * protection_rgb)
end

def film_curve(image, stock = :kodak_portra, intensity = 1.0)
  data = STOCKS[stock] || STOCKS[:kodak_portra]

  shadows = image.linear([1.0], [data[:lift] * 255 * intensity])
  gamma_corrected = shadows.pow(data[:gamma])

  highlights = gamma_corrected.pow(data[:rolloff])

  safe_cast(image * (1 - intensity) + highlights * intensity)
end

def highlight_roll(image, threshold = 200, intensity = 1.0)
  mask = image > threshold

  over_exposed = image - threshold

  rolled_off = threshold + (over_exposed * 0.3).pow(0.7)

  result = mask.ifthenelse(rolled_off, image)

  safe_cast(image * (1 - intensity) + result * intensity)

end

def shadow_lift(image, lift = 0.15, preserve_blacks = true)
  gray = image.colourspace('grey16').cast('float') / 255.0

  shadow_mask = preserve_blacks ? ((1.0 - gray).pow(2.0)) * 0.8 : (1.0 - gray) * lift

  lift_rgb = shadow_mask.bandjoin([shadow_mask, shadow_mask])

  safe_cast(image.linear([1.0, 1.0, 1.0], [lift_rgb * 255 * lift]))

end

def micro_contrast(image, radius = 5, intensity = 0.3)
  blurred = image.gaussblur(radius)

  high_pass = image - blurred

  safe_cast(image + high_pass * intensity)

end

def color_separate(image, intensity = 0.6)
  r, g, b = image.bandsplit

  r_clean = (r - (g * 0.08 * intensity) - (b * 0.05 * intensity)).max(0)
  g_clean = (g - (r * 0.06 * intensity) - (b * 0.10 * intensity)).max(0)

  b_clean = (b - (r * 0.04 * intensity) - (g * 0.07 * intensity)).max(0)

  separated = Vips::Image.bandjoin([r_clean, g_clean, b_clean])
  safe_cast(image * (1 - intensity) + separated * intensity)

end

def grain(image, iso = 400, stock = :kodak_portra, intensity = 0.4)
  data = STOCKS[stock]

  sigma = data[:grain] * Math.sqrt(iso / 100.0) * intensity

  noise = Vips::Image.gaussnoise(image.width, image.height, sigma: sigma)
  brightness = image.colourspace('grey16').cast('float') / 255.0

  strength = (1.2 - brightness).max(0.3) * intensity

  grain_rgb = rgb_bands(noise * strength.bandjoin([strength, strength]))
  safe_cast(image + grain_rgb * 0.25)

end

def base_tint(image, color = [252, 248, 240], intensity = 0.08)
  overlay = Vips::Image.black(image.width, image.height, bands: 3) + color

  overlay_norm = overlay.cast('float') / 255.0

  image_norm = image.cast('float') / 255.0

  result = image_norm.ifthenelse(
    overlay_norm < 0.5,

    2 * image_norm * overlay_norm,

    1 - 2 * (1 - image_norm) * (1 - overlay_norm)

  )

  blended = result * 255
  safe_cast(image * (1 - intensity) + blended * intensity)

end

def vintage_lens(image, type = 'zeiss', intensity = 0.7)
  case type

  when 'zeiss' then micro_contrast(image, 3, 0.4 * intensity)

  when 'leica'

    glow = image.gaussblur(20).linear([0.3 * intensity], [0])

    safe_cast(image + glow)

  when 'helios'

    sharp = image.sharpen(mask: [[0, -1, 0], [-1, 5, -1], [0, -1, 0]])

    safe_cast(image * (1 - intensity * 0.3) + sharp * (intensity * 0.3))

  else

    image

  end

end

def teal_orange(image, intensity = 1.0)
  protected = skin_protect(image, 0.8)

  r, g, b = protected.bandsplit

  r_enhanced = r.linear([1 + 0.25 * intensity], [8 * intensity])
  g_balanced = g.linear([1 - 0.08 * intensity], [0])

  b_enhanced = b.linear([1 + 0.35 * intensity], [0])

  safe_cast(Vips::Image.bandjoin([r_enhanced, g_balanced, b_enhanced]))
end

def bloom_pro(image, intensity = 1.0)
  bright = image.linear([2.0 * intensity], [0])

  bloom_1 = bright.gaussblur(8 * intensity)

  bloom_2 = bright.gaussblur(16 * intensity)

  combined = (bloom_1 + bloom_2 * 0.5) * 0.2

  safe_cast(image + combined)

end

# Preset Application
def preset(image, name)

  p = PRESETS[name.to_sym]

  return image unless p

  result = image

  p[:fx].each do |fx|
    result = case fx

             when 'skin_protect' then skin_protect(result, p[:intensity])

             when 'film_curve' then film_curve(result, p[:stock], p[:intensity])

             when 'highlight_roll' then highlight_roll(result, 200, p[:intensity] * 0.7)

             when 'shadow_lift' then shadow_lift(result, 0.2, false)

             when 'micro_contrast' then micro_contrast(result, 6, p[:intensity] * 0.4)

             when 'grain' then grain(result, 400, p[:stock], p[:intensity] * 0.4)

             when 'color_temp' then color_temp(result, p[:temp], p[:intensity] * 0.6)

             when 'base_tint' then base_tint(result, [255, 250, 245], 0.08)

             when 'color_separate' then color_separate(result, p[:intensity] * 0.6)

             when 'vintage_lens' then vintage_lens(result, 'zeiss', p[:intensity] * 0.8)

             when 'teal_orange' then teal_orange(result, p[:intensity])

             when 'bloom_pro' then bloom_pro(result, p[:intensity])

             else result

             end

  end

  result
end

# Random Effects
def random_fx(image, effects, mode)

  result = image

  effects.each do |fx|

    intensity = mode == 'experimental' ? rand(0.5..1.5) : rand(0.3..0.8)

    result = case fx

             when 'grain' then grain_basic(result, intensity)

             when 'leaks' then leaks_basic(result, intensity)

             when 'sepia' then sepia_basic(result, intensity)

             when 'bloom' then bloom_basic(result, intensity)

             when 'teal_orange' then teal_orange(result, intensity)

             when 'cross' then cross_basic(result, intensity)

             when 'vhs' then vhs_basic(result, intensity)

             when 'chroma' then chroma_basic(result, intensity)

             when 'glitch' then glitch_basic(result, intensity)

             when 'flare' then flare_basic(result, intensity)

             else result

             end

  end

  result

end

def grain_basic(image, intensity)
  noise = Vips::Image.gaussnoise(image.width, image.height, sigma: 25 * intensity)

  safe_cast(image + rgb_bands(noise) * 0.2)

end

def leaks_basic(image, intensity)
  overlay = Vips::Image.black(image.width, image.height, bands: 3)

  rand(2..5).times do

    x, y = rand(image.width), rand(image.height)

    radius = image.width / rand(2..4)

    color = [255 * intensity, 180 * intensity, 80 * intensity]

    overlay = overlay.draw_circle(color, x, y, radius, fill: true)

  end

  safe_cast(image + overlay.gaussblur(15 * intensity) * 0.3)

end

def sepia_basic(image, intensity)
  matrix = [0.9, 0.7, 0.2, 0.3, 0.8, 0.1, 0.2, 0.6, 0.1]

  safe_cast(image.recomb(matrix))

end

def bloom_basic(image, intensity)
  bright = image.linear([1.8 * intensity], [0]).gaussblur(12 * intensity)

  safe_cast(image + bright * 0.3)

end

def cross_basic(image, intensity)
  r, g, b = image.bandsplit

  r = r.linear([1 + 0.2 * intensity], [10 * intensity])

  g = g.linear([1 - 0.1 * intensity], [0])

  b = b.linear([1 + 0.3 * intensity], [-5 * intensity])

  safe_cast(Vips::Image.bandjoin([r, g, b]))

end

def vhs_basic(image, intensity)
  noise = rgb_bands(Vips::Image.gaussnoise(image.width, image.height, sigma: 40 * intensity))

  lines = rgb_bands(Vips::Image.sines(image.width, image.height).linear(0.3 * intensity, 150))

  safe_cast(image + noise * 0.4 + lines * 0.3)

end

def chroma_basic(image, intensity)
  shift = 3 * intensity

  r, g, b = image.bandsplit

  r = r.embed(shift, 0, image.width, image.height)

  b = b.embed(-shift, 0, image.width, image.height)

  safe_cast(Vips::Image.bandjoin([r, g, b]))

end

def glitch_basic(image, intensity)
  r, g, b = image.bandsplit

  shift = 15 * intensity

  r = r.embed(rand(-shift..shift), rand(-shift..shift), image.width, image.height)

  g = g.embed(rand(-shift..shift), rand(-shift..shift), image.width, image.height)

  b = b.embed(rand(-shift..shift), rand(-shift..shift), image.width, image.height)

  noise = rgb_bands(Vips::Image.gaussnoise(image.width, image.height, sigma: 20 * intensity))

  safe_cast(Vips::Image.bandjoin([r, g, b]) + noise * 0.4)

end

def flare_basic(image, intensity)
  flare = Vips::Image.black(image.width, image.height, bands: 3)

  rand(3..6).times do

    x, y = rand(image.width), rand(image.height)

    length = 200 * intensity

    flare = flare.draw_line([255, 220, 180], x, y, x + length, y)

  end

  safe_cast(image + flare.gaussblur(8 * intensity) * 0.3)

end

def recipe(image, recipe_data)
  result = image

  recipe_data.each do |fx, params|

    intensity = params.is_a?(Hash) ? params['intensity'].to_f : params.to_f

    method = fx.gsub('_professional', '')

    result = respond_to?(method) ? send(method, result, intensity) : result

  end

  result

end

# Repligen Integration
def check_repligen

  return unless REPLIGEN_PRESENT

  $cli_logger.info 'Repligen detected! Auto-processing generated images...'
  recent_files = Dir.glob('*_generated_*.{jpg,jpeg,png,webp}')
                    .select { |f| File.mtime(f) > (Time.now - 300) }

  if recent_files.any?
    $cli_logger.info "Found #{recent_files.count} recent Repligen outputs"

    preset_name = PROMPT.select('Choose preset for Repligen outputs:', PRESETS.keys)

    recent_files.each { |file| process_file(file, 2, preset_name) }

  end

end

def process_file(file, variations, preset_name = nil, recipe_data = nil, random_effects = nil, mode = "professional")
  image = load_image(file)

  return 0 unless image

  # Apply camera profile first if enabled
  if CONFIG["apply_camera_profile_first"]

    profile = get_camera_profile(image)

    if profile

      image = apply_camera_profile(image, profile)

      PostproBootstrap.dmesg "applied camera profile for #{file}"

    end

  end

  processed_count = 0
  variations.times do |i|

    begin

      processed = if preset_name

                     preset(image, preset_name)

                   elsif recipe_data

                     recipe(image, recipe_data)

                   elsif random_effects

                     random_fx(image, random_effects, mode)

                   else

                     next

                   end

      next unless processed
      processed = rgb_bands(processed)
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")

      suffix = preset_name || "processed"

      output = file.sub(File.extname(file), "_#{suffix}_v#{i + 1}_#{timestamp}#{File.extname(file)}")

      quality = CONFIG["jpeg_quality"] || 95
      processed.write_to_file(output, Q: quality)

      $cli_logger.info "Saved masterpiece #{i + 1}: #{File.basename(output)}"

      processed_count += 1

    rescue StandardError => e
      $logger.error "Variation #{i + 1} failed: #{e.message}"

    end

  end

  processed_count
end

# Main Workflow
def get_input

  show_postpro_banner

  check_repligen if REPLIGEN_PRESENT

  if PROMPT
    workflow = PROMPT.select("Choose workflow:", [

      "Masterpiece Presets (Recommended)",

      "Random Effects (Experimental)",

      "Custom JSON Recipe"

    ])

    patterns = PROMPT.ask("File patterns:", default: "**/*.{jpg,jpeg,png,webp}").strip.split(",").map(&:strip)
    variations = PROMPT.ask("Variations per image:", convert: :int, default: CONFIG["variations"] || 2) { |q| q.in("1-5") }

    case workflow
    when "Masterpiece Presets (Recommended)"

      preset_name = PROMPT.select("Choose preset:", PRESETS.keys)

      [patterns, variations, { type: :preset, preset: preset_name }]

    when "Random Effects (Experimental)"
      mode = PROMPT.select("Mode:", ["Professional", "Experimental"])

      fx_count = PROMPT.ask("Effects per variation:", convert: :int, default: 4) { |q| q.in("2-8") }

      [patterns, variations, { type: :random, mode: mode.downcase, fx: fx_count }]

    when "Custom JSON Recipe"
      file = PROMPT.ask("Recipe file path:").strip

      recipe_data = File.exist?(file) ? JSON.parse(File.read(file)) : {}

      [patterns, variations, { type: :recipe, recipe: recipe_data }]

    end

  else

    # Interactive mode without tty-prompt - show defaults clearly

    get_input_simple

  end

end

def show_postpro_banner
  $cli_logger.info <<~BANNER

    ╔═══════════════════════════════════════════════════════════╗
    ║            POSTPRO v14.2.0 Professional Edition          ║

    ║         Advanced Color Science & Cinematic Workflows     ║

    ╚═══════════════════════════════════════════════════════════╝

    Film Stocks: Kodak Portra, Vision3, Fuji Velvia, Tri-X
    Presets: Portrait, Landscape, Street, Blockbuster

    #{REPLIGEN_PRESENT ? "🔗 Repligen Integration Active" : ""}

  BANNER
end

def get_input_simple
  # Simple interactive mode with clear defaults

  puts "\n🎬 Workflow Selection:"

  puts "  1. Masterpiece Presets (Recommended)"

  puts "  2. Random Effects (Experimental)"

  puts "  3. Custom JSON Recipe"

  print "\nChoose workflow [1]: "
  workflow_choice = gets&.chomp&.strip

  workflow_choice = "1" if workflow_choice.empty?

  print "File patterns [**/*.{jpg,jpeg,png,webp}]: "
  patterns_input = gets&.chomp&.strip

  patterns = patterns_input.empty? ? ["**/*.{jpg,jpeg,png,webp}"] : patterns_input.split(",").map(&:strip)

  default_variations = CONFIG["variations"] || 2
  print "Variations per image [#{default_variations}]: "

  variations_input = gets&.chomp&.strip

  variations = variations_input.empty? ? default_variations : variations_input.to_i

  case workflow_choice
  when "1"

    puts "\n🎨 Available Presets:"

    PRESETS.keys.each_with_index { |preset, i| puts "  #{i+1}. #{preset}" }

    default_preset = CONFIG["default_preset"] || "portrait"
    print "\nChoose preset [#{default_preset}]: "

    preset_input = gets&.chomp&.strip

    preset_name = if preset_input.empty?
                    default_preset.to_sym

                  elsif preset_input.to_i > 0 && preset_input.to_i <= PRESETS.keys.size

                    PRESETS.keys[preset_input.to_i - 1]

                  else

                    preset_input.to_sym

                  end

    [patterns, variations, { type: :preset, preset: preset_name }]
  when "2"
    print "Mode (professional/experimental) [professional]: "

    mode_input = gets&.chomp&.strip

    mode = mode_input.empty? ? "professional" : mode_input.downcase

    print "Effects per variation [4]: "
    fx_input = gets&.chomp&.strip

    fx_count = fx_input.empty? ? 4 : fx_input.to_i

    [patterns, variations, { type: :random, mode: mode, fx: fx_count }]
  when "3"
    print "Recipe file path: "

    file = gets&.chomp&.strip

    recipe_data = File.exist?(file) ? JSON.parse(File.read(file)) : {}

    [patterns, variations, { type: :recipe, recipe: recipe_data }]

  else
    # Default to portrait preset

    [patterns, variations, { type: :preset, preset: :portrait }]

  end

end

def auto_mode
  PostproBootstrap.dmesg "auto mode enabled"

  patterns = ["**/*.{jpg,jpeg,png,webp}"]

  variations = CONFIG["variations"] || 2

  preset_name = CONFIG["default_preset"] || "portrait"

  [patterns, variations, { type: :preset, preset: preset_name }]
end

def auto_launch
  if ARGV.include?("--auto") || (!$stdin.tty? && ARGV.include?("--from-repligen"))

    input = auto_mode

  elsif ARGV.include?("--from-repligen") && REPLIGEN_PRESENT

    check_repligen

    return

  else

    input = get_input

  end

  return unless input
  patterns, variations, config = input
  files = patterns.flat_map { |pattern| Dir.glob(pattern) }
                  .reject { |f| File.basename(f).match?(/processed|masterpiece/) }

  if files.empty?
    $cli_logger.error "No files matched patterns!"

    return

  end

  $cli_logger.info "Processing #{files.count} files..."
  total_processed = 0

  total_variations = 0

  start_time = Time.now

  files.each_with_index do |file, i|
    begin

      $cli_logger.info "#{i + 1}/#{files.count}: #{File.basename(file)}"

      count = case config[:type]
              when :preset

                process_file(file, variations, config[:preset])

              when :random

                fx = %w[grain leaks sepia bloom teal_orange cross vhs chroma glitch flare]

                selected = config[:mode] == "experimental" ? fx : fx.first(6)

                random_effects = selected.shuffle.take(config[:fx])

                process_file(file, variations, nil, nil, random_effects, config[:mode])

              when :recipe

                process_file(file, variations, nil, config[:recipe])

              else

                0

              end

      total_processed += 1 if count > 0
      total_variations += count

      GC.start if (i % 10).zero?

    rescue StandardError => e
      $logger.error "Failed #{file}: #{e.message}"

      $cli_logger.error "Error: #{File.basename(file)}"

    end

  end

  duration = (Time.now - start_time).round(2)
  $cli_logger.info "Complete! #{total_processed} files → #{total_variations} masterpieces (#{duration}s)"

  if REPLIGEN_PRESENT && total_variations > 0
    $cli_logger.info "Tip: Run 'ruby repligen.rb' to generate more content!"

  end

end

auto_launch if __FILE__ == $0
