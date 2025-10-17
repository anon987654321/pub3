#!/usr/bin/env ruby
# J Dilla Audio Generator - Master Orchestrator

# Complexity: 8/10 (within master.json ≤10 limit)

# Purpose: Single entry point for complete beat generation with MAXIMUM VARIETY

# Workflow: dilla_data.json → chords + bass → drums → VARIED final mixes

# Usage:
#   ruby master.rb               # Full render (all progressions, drums, varied mixes)
#   ruby master.rb --chords      # Just render chord progressions
#   ruby master.rb --drums       # Just render drum patterns
#   ruby master.rb --mix         # Just create final mixes
#   ruby master.rb --quick       # Render only 5 progressions for testing
#   ruby master.rb --list        # List all available progressions
#   ruby master.rb --play        # Generate + play random progression

require "json"
require_relative "lib/synthesis"

# ============================================================================
# CONFIGURATION
# ============================================================================

SOX = "G:/pub/dilla/effects/sox/sox.exe"
DATA_JSON = File.expand_path("dilla_data.json", __dir__)

# Note frequencies (A4 = 440Hz)
NOTES = {

  "C" => 130.81, "C#" => 138.59, "Db" => 138.59,

  "D" => 146.83, "D#" => 155.56, "Eb" => 155.56,

  "E" => 164.81, "F" => 174.61, "F#" => 185.00, "Gb" => 185.00,

  "G" => 196.00, "G#" => 207.65, "Ab" => 207.65,

  "A" => 220.00, "A#" => 233.08, "Bb" => 233.08,

  "B" => 246.94

}

# Chord intervals (semitones from root)
INTERVALS = {

  "maj7" => [0, 4, 7, 11], "maj9" => [0, 4, 7, 11, 14], "maj13" => [0, 4, 7, 11, 14, 21],

  "min7" => [0, 3, 7, 10], "min9" => [0, 3, 7, 10, 14], "min11" => [0, 3, 7, 10, 14, 17],

  "dom7" => [0, 4, 7, 10], "dom9" => [0, 4, 7, 10, 14], "dom13" => [0, 4, 7, 10, 14, 21],

  "7#9" => [0, 4, 7, 10, 15], "sus2" => [0, 2, 7], "sus4" => [0, 5, 7],

  "" => [0, 4, 7]  # major triad

}

# ============================================================================
# UTILITIES

# ============================================================================

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

# ============================================================================
# CHORD SYNTHESIS (Using lib/synthesis.rb)
# ============================================================================

def generate_chord(freqs, duration, instrument)
  freqs.each_with_index do |freq, i|
    case instrument
    when "rhodes" then Dilla::Synthesis.rhodes(i, freq, -10, duration, SOX)
    when "fm" then Dilla::Synthesis.fm(i, freq, -10, duration, SOX)
    when "cs80" then Dilla::Synthesis.cs80(i, freq, -10, duration, SOX)
    when "minimoog" then Dilla::Synthesis.minimoog(i, freq, -10, duration, SOX)
    when "strings" then Dilla::Synthesis.strings(i, freq, -10, duration, SOX)
    when "ambient" then Dilla::Synthesis.ambient(i, freq, -10, duration, SOX)
    when "oberheim" then Dilla::Synthesis.oberheim(i, freq, -10, duration, SOX)
    else Dilla::Synthesis.fm(i, freq, -10, duration, SOX)
    end
  end

  voices = freqs.size.times.map { |i| "voice_#{i}.wav" }
  sox("-m #{voices.join(' ')} chord_out.wav gain -n")
  cleanup(*voices)
  "chord_out.wav"
end

def generate_bass(root_freq, duration)
  sub = root_freq / 2

  sox("-n bass_root.wav synth #{duration} sine #{root_freq} gain -8")

  sox("-n bass_sub.wav synth #{duration} sine #{sub} gain -6")

  sox("-m bass_root.wav bass_sub.wav bass_out.wav gain -n")

  cleanup("bass_root.wav", "bass_sub.wav")

  "bass_out.wav"

end

def render_progression(prog_name, prog_data)
  puts "🎹 #{prog_name}"

  chords = prog_data["chords"]
  freqs_list = prog_data["freqs"]

  dur = prog_data["duration"] || 2.0

  instrument = prog_data["instrument"] || "fm"

  return unless freqs_list
  chord_files = []
  bass_files = []

  chords.zip(freqs_list).each_with_index do |(chord_name, freqs), idx|
    chord_file = generate_chord(freqs, dur, instrument)

    sox("#{chord_file} chord_#{idx}.wav")

    chord_files << "chord_#{idx}.wav"

    cleanup(chord_file)

    bass_file = generate_bass(freqs[0], dur)
    sox("#{bass_file} bass_#{idx}.wav")

    bass_files << "bass_#{idx}.wav"

    cleanup(bass_file)

  end

  sox("#{chord_files.join(' ')} #{chord_files.join(' ')} chords_raw.wav")
  sox("#{bass_files.join(' ')} #{bass_files.join(' ')} bass_raw.wav")

  cleanup(*chord_files, *bass_files)

  system("mkdir -p chords bass 2>/dev/null")
  sox("chords_raw.wav chords/#{prog_name}.wav gain -n -2")

  sox("bass_raw.wav bass/#{prog_name}.wav gain -n -2")

  cleanup("chords_raw.wav", "bass_raw.wav")

  puts "   → chords/#{prog_name}.wav + bass/#{prog_name}.wav"
end

# ============================================================================
# DRUM SYNTHESIS (from drums_fixed.rb)

# ============================================================================

def make_kick
  sox("-n _kick.wav synth 0.16 sine 58 fade h 0.001 0.16 0.06 overdrive 10 gain -3")

  "_kick.wav"

end

def make_snare
  sox("-n _snare.wav synth 0.12 noise lowpass 4000 highpass 200 fade h 0.001 0.12 0.04 overdrive 8 gain -6")

  "_snare.wav"

end

def make_hat_closed
  sox("-n _hat.wav synth 0.06 noise highpass 7000 fade h 0.001 0.06 0.02 gain -12")

  "_hat.wav"

end

def make_kick_909
  sox("-n _kick909.wav synth 0.18 sine 65 fade h 0.001 0.18 0.08 overdrive 15 gain -1")

  "_kick909.wav"

end

def generate_techno(tempo, bars)
  beat_sec = 60.0 / tempo

  bar_sec = beat_sec * 4

  total_sec = bar_sec * bars

  kick = make_kick_909
  hat = make_hat_closed

  kick_seq = []
  bars.times do |bar|

    4.times do |beat|

      offset = bar * bar_sec + beat * beat_sec

      sox("#{kick} _k#{bar}_#{beat}.wav pad #{offset} 0")

      kick_seq << "_k#{bar}_#{beat}.wav"

    end

  end

  hat_seq = []
  bars.times do |bar|

    16.times do |sixteenth|

      offset = bar * bar_sec + sixteenth * (beat_sec / 4)

      dyn = (sixteenth % 4 == 0) ? 0 : -6

      sox("#{hat} _h#{bar}_#{sixteenth}.wav pad #{offset} 0 gain #{dyn}")

      hat_seq << "_h#{bar}_#{sixteenth}.wav"

    end

  end

  sox("-m #{kick_seq.join(' ')} _kicks.wav pad 0 #{total_sec}")
  sox("-m #{hat_seq.join(' ')} _hats.wav pad 0 #{total_sec}")

  sox("-m _kicks.wav _hats.wav drums/techno_intricate_#{tempo}bpm.wav gain -n -3")

  cleanup(*kick_seq, *hat_seq, "_kicks.wav", "_hats.wav", kick, hat)
  puts "✓ drums/techno_intricate_#{tempo}bpm.wav"

end

def generate_hiphop(tempo, swing_pct, bars)
  beat_sec = 60.0 / tempo

  bar_sec = beat_sec * 4

  total_sec = bar_sec * bars

  swing_factor = (swing_pct - 50) / 100.0

  swing_offset = (beat_sec / 8) * swing_factor

  kick = make_kick
  snare = make_snare

  hat = make_hat_closed

  kick_seq = []
  bars.times do |bar|

    base = bar * bar_sec

    sox("#{kick} _k#{bar}_0.wav pad #{base} 0")

    kick_seq << "_k#{bar}_0.wav"

    sox("#{kick} _k#{bar}_1.wav pad #{base + beat_sec + beat_sec/2 + swing_offset} 0 gain -2")

    kick_seq << "_k#{bar}_1.wav"

    sox("#{kick} _k#{bar}_2.wav pad #{base + beat_sec * 2} 0")

    kick_seq << "_k#{bar}_2.wav"

  end

  snare_seq = []
  bars.times do |bar|

    base = bar * bar_sec

    sox("#{snare} _s#{bar}_0.wav pad #{base + beat_sec} 0")

    snare_seq << "_s#{bar}_0.wav"

    sox("#{snare} _s#{bar}_1.wav pad #{base + beat_sec * 3} 0")

    snare_seq << "_s#{bar}_1.wav"

    [0.5, 1.5, 2.5, 3.5].each_with_index do |beat_pos, idx|
      offset = base + beat_pos * beat_sec + (idx.odd? ? swing_offset : 0)

      sox("#{snare} _sg#{bar}_#{idx}.wav pad #{offset} 0 gain -18")

      snare_seq << "_sg#{bar}_#{idx}.wav"

    end

  end

  hat_seq = []
  bars.times do |bar|

    base = bar * bar_sec

    8.times do |eighth|

      offset = base + eighth * (beat_sec / 2) + (eighth.odd? ? swing_offset : 0)

      dyn = eighth.even? ? -3 : -6

      sox("#{hat} _h#{bar}_#{eighth}.wav pad #{offset} 0 gain #{dyn}")

      hat_seq << "_h#{bar}_#{eighth}.wav"

    end

  end

  sox("-m #{kick_seq.join(' ')} _kicks.wav pad 0 #{total_sec}")
  sox("-m #{snare_seq.join(' ')} _snares.wav pad 0 #{total_sec}")

  sox("-m #{hat_seq.join(' ')} _hats.wav pad 0 #{total_sec}")

  sox("-m _kicks.wav _snares.wav _hats.wav drums/hiphop_intricate_#{tempo}bpm_#{swing_pct}swing.wav gain -n -3")

  cleanup(*kick_seq, *snare_seq, *hat_seq, "_kicks.wav", "_snares.wav", "_hats.wav", kick, snare, hat)
  puts "✓ drums/hiphop_intricate_#{tempo}bpm_#{swing_pct}swing.wav"

end

# ============================================================================
# FINAL MIXING (MAXIMUM VARIETY - ROTATES THROUGH ALL DRUMS)

# ============================================================================

def create_final_mix(name, drum_file)
  chord_file = "chords/#{name}.wav"

  bass_file = "bass/#{name}.wav"

  return unless File.exist?(chord_file) && File.exist?(bass_file)
  unless File.exist?(drum_file)
    puts "⚠ No drums for #{name} (#{drum_file} missing)"

    return

  end

  # Get chord duration to loop drums
  chord_duration = `#{SOX} --info -D #{chord_file}`.strip.to_f

  drum_duration = `#{SOX} --info -D #{drum_file}`.strip.to_f

  drum_repeats = (chord_duration / drum_duration).ceil + 1

  # Loop drums to match
  sox("#{([drum_file] * drum_repeats).join(' ')} _drums_loop.wav trim 0 #{chord_duration}")

  # Extract drum name for output filename
  drum_name = File.basename(drum_file, ".wav").gsub("_intricate", "")

  # Final mix with mastering
  sox("-m #{chord_file} #{bass_file} _drums_loop.wav final/#{name}_#{drum_name}.wav gain -n -2 compand 0.02,0.20 -60,-60,-30,-24,-20,-18,-4,-12,-2,-9,0,-6 -6 0 0.05 overdrive 5 reverb 18 10 equalizer 80 0.5q +2 equalizer 3000 1.2q +1.5 equalizer 10000 0.6q +1.5 gain -n -0.5")

  cleanup("_drums_loop.wav")
  puts "✓ final/#{name}_#{drum_name}.wav"

end

# ============================================================================
# MAIN ORCHESTRATION

# ============================================================================

def load_data
  JSON.parse(File.read(DATA_JSON))
end

def list_progressions(data)
  puts "\n📋 AVAILABLE PROGRESSIONS:"
  puts "=" * 70
  ['neo_soul', 'jazz', 'funk_soul'].each do |category|
    progs = data['progressions'][category]
    next unless progs
    puts "\n#{category.upcase.gsub('_', ' ')}:"
    progs.each do |name, prog|
      puts "  - #{name}: #{prog['name'] || name}"
    end
  end
  puts
end

if __FILE__ == $0
  puts "\n" + ("=" * 70)
  puts "🎹 J DILLA AUDIO GENERATOR - MASTER ORCHESTRATOR"
  puts "=" * 70

  mode = ARGV[0] || "--full"
  
  # Handle --list mode
  if mode == "--list"
    data = load_data
    list_progressions(data)
    exit 0
  end
  
  # Load JSON
  data = load_data
  theory = {
    'neo_soul_progressions' => data['progressions']['neo_soul'],
    'jazz_progressions' => data['progressions']['jazz'],
    'funk_soul_progressions' => data['progressions']['funk_soul']
  }

  # Create directories
  system("mkdir -p chords bass drums final 2>/dev/null")

  # CHORDS & BASS
  unless mode == "--drums"
    puts "\n📊 RENDERING CHORD PROGRESSIONS + BASS"
    puts "-" * 70

    progressions_to_render = []
    ["neo_soul", "jazz", "funk_soul"].each do |cat|
      key = "#{cat}_progressions"
      next unless theory[key]

      theory[key].each do |name, data|
        progressions_to_render << [name, data] if data["freqs"]
      end
    end

    # Quick mode: only 5 progressions
    progressions_to_render = progressions_to_render.first(5) if mode == "--quick"

    progressions_to_render.each { |name, data| render_progression(name, data) }
  end

  # DRUMS
  unless mode == "--chords" || mode == "--mix"

    puts "\n📊 RENDERING INTRICATE DRUMS"

    puts "-" * 70

    if mode == "--quick"
      generate_techno(130, 4)

      generate_hiphop(92, 58, 4)

    else

      [128, 130, 135, 140].each { |t| generate_techno(t, 4) }

      [[90, 58], [92, 58], [95, 62], [85, 54]].each { |t, s| generate_hiphop(t, s, 4) }

    end

  end

  # FINAL MIXES - ROTATE THROUGH ALL DRUMS FOR MAXIMUM VARIETY
  unless mode == "--chords" || mode == "--drums"

    puts "\n📊 CREATING FINAL MIXES (ROTATING DRUMS FOR VARIETY)"

    puts "-" * 70

    # Get all available drum files
    drum_files = Dir.glob("drums/*.wav").sort

    if drum_files.empty?
      puts "⚠ No drum files found - skipping final mixes"

    else

      puts "   Using #{drum_files.size} drum patterns in rotation"

      chord_files = Dir.glob("chords/*.wav").sort
      drum_index = 0

      chord_files.each do |path|
        name = File.basename(path, ".wav")

        # Rotate through drum files
        drum_file = drum_files[drum_index % drum_files.size]

        create_final_mix(name, drum_file)

        drum_index += 1
      end

    end

  end

  puts "\n" + ("=" * 70)
  puts "✅ RENDER COMPLETE"

  puts "=" * 70

  puts "\n📁 Outputs:"

  puts "  chords/ - Chord progressions (#{Dir.glob('chords/*.wav').size} files)"

  puts "  bass/   - Bass layers (#{Dir.glob('bass/*.wav').size} files)"

  puts "  drums/  - Drum patterns (#{Dir.glob('drums/*.wav').size} files)"

  puts "  final/  - Full mixes (#{Dir.glob('final/*.wav').size} files)"

  puts ""

end

