#!/usr/bin/env ruby
# Comprehensive drum pattern generator - Evidence-based timing
# Consolidated from drums.rb + drums_fixed.rb per master.json anti-fragmentation
# Research: arXiv 1904.03442 - consistent swing ratios, not random jitter
# Complexity: 7/10 (adheres to master.json ≤10 limit)

require "json"
SOX = "G:/pub/dilla/effects/sox/sox.exe"

# Load unified data from dilla_data.json (consolidation>fragmentation)
DILLA_DATA = JSON.parse(File.read(File.join(__dir__, "dilla_data.json")))
DRUM_PATTERNS = DILLA_DATA["drums"]

def sox(cmd)
  system("#{SOX} #{cmd}")

end

def cleanup(*files)
  files.each do |f|

    next unless File.exist?(f)

    3.times do

      begin

        File.delete(f)

        break

      rescue Errno::EBUSY, Errno::EACCES

        sleep 0.1

      end

    end

  end

end

# Apply swing timing (evidence-based: arXiv 1904.03442)
def apply_swing(step, swing_percent)

  return step.to_f if step.even?  # Straight beats unaffected

  swing_factor = (swing_percent - 50) / 50.0
  step + (swing_factor * 0.5)

end

# Synthesize drum hit using SoX
def synth_hit(type, gain_db)

  params = DRUM_PATTERNS["synthesis_parameters"]["sox_commands"][type]

  return nil unless params

  file = "hit_#{type}.wav"
  cmd = params + " gain #{gain_db}"

  sox("-n #{file} #{cmd}")

  file

end

# Generate one drum voice with dynamics and swing
def generate_voice(type, pattern, dynamics, tempo, swing_percent, bar_duration)

  step_duration = bar_duration / 16.0

  hits = []

  pattern.each_with_index do |step, idx|
    velocity = dynamics[idx] || 0.8

    gain_db = ((velocity - 1.0) * 20).round(1)

    # Apply swing
    swung_step = apply_swing(step, swing_percent)

    offset = swung_step * step_duration

    # Synthesize hit
    hit = synth_hit(type, gain_db)

    next unless hit

    # Position in timeline
    positioned = "pos_#{type}_#{idx}.wav"

    if offset > 0.001

      sox("-n pad_#{positioned} synth #{offset} sine 1000 gain -100")

      sox("-n #{positioned} #{hit} pad #{offset} 0")

      cleanup("pad_#{positioned}")

    else

      sox("#{hit} #{positioned}")

    end

    cleanup(hit)
    hits << positioned

  end

  return nil if hits.empty?
  # Mix all hits for this voice
  voice_file = "voice_#{type}.wav"

  sox("-m #{hits.join(' ')} #{voice_file} pad 0 #{bar_duration}")

  cleanup(*hits)

  voice_file

end

# Render complete drum pattern
def render_pattern(category, pattern_name)

  pattern_data = DRUM_PATTERNS["#{category}_patterns"][pattern_name]

  return unless pattern_data

  puts "\n🥁 #{pattern_data['name']}"
  puts "   Tempo: #{pattern_data['tempo']} BPM | Swing: #{pattern_data['swing']}%"

  tempo = pattern_data["tempo"]
  swing = pattern_data["swing"]

  bar_duration = (60.0 / tempo) * 4

  pattern = pattern_data["pattern"]
  dynamics = pattern_data["dynamics"]

  voice_files = []
  pattern.each do |drum_type, steps|

    next if steps.empty?

    dyn = dynamics[drum_type] || Array.new(steps.size, 0.8)
    voice = generate_voice(drum_type, steps, dyn, tempo, swing, bar_duration)

    next unless voice

    voice_files << voice
    print "  #{drum_type} ✓"

  end

  puts ""

  return if voice_files.empty?
  # Mix all voices
  system("mkdir -p drums 2>/dev/null")

  output = "drums/#{pattern_name}.wav"

  sox("-m #{voice_files.join(' ')} #{output}")

  cleanup(*voice_files)

  puts "   → #{output}"
end

# Main execution
if __FILE__ == $0

  puts "\n" + ("=" * 70)

  puts "🥁 COMPREHENSIVE DRUM PATTERN GENERATOR"

  puts "=" * 70

  puts "\nVersion: #{DRUM_PATTERNS['meta']['version']}"

  puts "\n📊 Evidence-Based Swing (arXiv 1904.03442):"

  puts "   \"#{DRUM_PATTERNS['swing_theory']['evidence_based']['finding']}\""

  puts "   → Use consistent swing ratios, not random microtiming"

  # Render patterns from each category
  ["hip_hop", "reggae", "techno_house", "jazz"].each do |category|

    category_key = "#{category}_patterns"

    next unless DRUM_PATTERNS[category_key]

    puts "\n" + ("-" * 70)
    puts "📁 #{category.upcase.gsub('_', ' ')} PATTERNS"

    puts "-" * 70

    # Render first 3 patterns from each category
    DRUM_PATTERNS[category_key].keys.first(3).each do |pattern_name|

      render_pattern(category, pattern_name)

    end

  end

  puts "\n" + ("=" * 70)
  puts "✅ GENERATION COMPLETE"

  puts "=" * 70

  puts "\nOutput:"

  puts "  📁 drums/ - Drum patterns with velocity dynamics and swing"

  puts ""

end

