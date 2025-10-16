#!/usr/bin/env ruby
# Comprehensive chord pad generator with bass layer

# Evidence-based: Jazz standards, neo-soul, arXiv research

# Complexity: 6/10 (adheres to master.json ≤10 limit)

require "json"
SOX = "G:/pub/dilla/effects/sox/sox.exe"
CHORD_THEORY = JSON.parse(File.read("G:/pub/dilla/chord_theory.json"))

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

# Rhodes electric piano: 3 sine harmonics (bright, melodic)
def synth_rhodes(i, freq, gain, duration)

  sox("-n sin1_#{i}.wav synth #{duration} sine #{freq} fade h 0.01 #{duration} 0.5 gain #{gain}")

  sox("-n sin2_#{i}.wav synth #{duration} sine #{freq * 2} fade h 0.01 #{duration} 0.5 gain #{gain - 8}")

  sox("-n sin3_#{i}.wav synth #{duration} sine #{freq * 3} fade h 0.01 #{duration} 0.5 gain #{gain - 12}")

  sox("-m sin1_#{i}.wav sin2_#{i}.wav sin3_#{i}.wav rhodes_raw_#{i}.wav")

  sox("rhodes_raw_#{i}.wav voice_#{i}.wav tremolo 5.5 30 chorus 0.6 0.9 45 0.4 0.2 2 -t")

  cleanup("sin1_#{i}.wav", "sin2_#{i}.wav", "sin3_#{i}.wav", "rhodes_raw_#{i}.wav")

end

# FM synthesis: sawtooth + square + sine (warm, rich)
def synth_fm(i, freq, gain, duration)

  sox("-n saw#{i}.wav synth #{duration} sawtooth #{freq} gain #{gain}")

  sox("-n sqr#{i}.wav synth #{duration} square #{freq} gain #{gain - 2}")

  sox("-n sin#{i}.wav synth #{duration} sine #{freq} gain #{gain + 2}")

  sox("-m saw#{i}.wav sqr#{i}.wav sin#{i}.wav voice_#{i}.wav")

  cleanup("saw#{i}.wav", "sqr#{i}.wav", "sin#{i}.wav")

end

# CS-80 Vangelis style: Detuned saws with slow envelopes (Blade Runner)
def synth_cs80(i, freq, gain, duration)

  detune = freq * 1.0091  # ~8 cents detune

  sox("-n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 3 #{duration} 4 gain #{gain}")

  sox("-n saw2_#{i}.wav synth #{duration} sawtooth #{detune} fade h 3 #{duration} 4 gain #{gain - 2}")

  sox("-m saw1_#{i}.wav saw2_#{i}.wav cs80_raw_#{i}.wav")

  sox("cs80_raw_#{i}.wav voice_#{i}.wav lowpass 600 chorus 0.7 0.9 50 0.4 0.25 2 -t")

  cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "cs80_raw_#{i}.wav")

end

# Minimoog brass: Saw + detuned square with filter envelope (Pink Floyd)
def synth_minimoog(i, freq, gain, duration)

  detune = freq * 1.0029  # ~5 cents

  sox("-n saw#{i}.wav synth #{duration} sawtooth #{freq} fade h 1 #{duration} 4 gain #{gain}")

  sox("-n sqr#{i}.wav synth #{duration} square #{detune} fade h 1 #{duration} 4 gain #{gain - 3}")

  sox("-m saw#{i}.wav sqr#{i}.wav moog_raw_#{i}.wav")

  sox("moog_raw_#{i}.wav voice_#{i}.wav lowpass 1200 overdrive 5 chorus 0.6 0.9 40 0.4 0.2 2")

  cleanup("saw#{i}.wav", "sqr#{i}.wav", "moog_raw_#{i}.wav")

end

# String ensemble: 3-voice detuned saws (ARP Solina / Ultravox Vienna)
def synth_strings(i, freq, gain, duration)

  detune1 = freq * 1.0012  # ~2 cents

  detune2 = freq * 1.0023  # ~4 cents

  sox("-n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 0.5 #{duration} 2 gain #{gain}")

  sox("-n saw2_#{i}.wav synth #{duration} sawtooth #{detune1} fade h 0.5 #{duration} 2 gain #{gain - 1}")

  sox("-n saw3_#{i}.wav synth #{duration} sawtooth #{detune2} fade h 0.5 #{duration} 2 gain #{gain - 2}")

  sox("-m saw1_#{i}.wav saw2_#{i}.wav saw3_#{i}.wav strings_raw_#{i}.wav")

  sox("strings_raw_#{i}.wav voice_#{i}.wav lowpass 3000 chorus 0.7 0.9 55 0.5 0.3 2 -t overdrive 3")

  cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "saw3_#{i}.wav", "strings_raw_#{i}.wav")

end

# Ambient pad: Sine + saw blend with ultra-slow envelopes (Brian Eno)
def synth_ambient(i, freq, gain, duration)

  detune = freq * 1.0006  # ~1 cent (subtle)

  sox("-n sine#{i}.wav synth #{duration} sine #{freq} fade h 5 #{duration} 6 gain #{gain}")

  sox("-n saw#{i}.wav synth #{duration} sawtooth #{detune} fade h 5 #{duration} 6 gain #{gain - 8}")

  sox("-m sine#{i}.wav saw#{i}.wav voice_#{i}.wav highpass 80")

  cleanup("sine#{i}.wav", "saw#{i}.wav")

end

# Oberheim OB-X: Unison detuned saws (Frank Ocean, Van Halen)
def synth_oberheim(i, freq, gain, duration)

  detune = freq * 1.0046  # ~8 cents

  sox("-n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 1.5 #{duration} 3.5 gain #{gain}")

  sox("-n saw2_#{i}.wav synth #{duration} sawtooth #{detune} fade h 1.5 #{duration} 3.5 gain #{gain - 2}")

  sox("-m saw1_#{i}.wav saw2_#{i}.wav ob_raw_#{i}.wav")

  sox("ob_raw_#{i}.wav voice_#{i}.wav lowpass 1500 chorus 0.7 0.85 48 0.5 0.28 2")

  cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "ob_raw_#{i}.wav")

end

# Voice leading optimizer: Find smoothest voicing (minimal semitone movement)
def optimize_voice_leading(prev_freqs, current_freqs)

  return current_freqs if prev_freqs.nil? || prev_freqs.empty?

  # Convert frequencies to semitones (easier to calculate movement)
  prev_semitones = prev_freqs.map { |f| 12 * Math.log2(f / 440.0) + 69 }

  # Try all inversions of current chord (rotate frequency array)
  best_voicing = current_freqs

  min_movement = Float::INFINITY

  current_freqs.size.times do |rotation|
    # Rotate to try different inversions

    test_voicing = current_freqs.rotate(rotation)

    test_semitones = test_voicing.map { |f| 12 * Math.log2(f / 440.0) + 69 }

    # Calculate total semitone movement
    total_movement = 0

    [prev_semitones.size, test_semitones.size].min.times do |i|

      total_movement += (test_semitones[i] - prev_semitones[i]).abs

    end

    if total_movement < min_movement
      min_movement = total_movement

      best_voicing = test_voicing

    end

  end

  puts "   Voice leading optimized: #{min_movement.round(1)} semitone movement" if min_movement < Float::INFINITY
  best_voicing

end

# Generate chord from frequency array with instrument selection
def generate_chord(freqs, duration, output, instrument)

  freqs.each_with_index do |freq, i|

    gain = -6 - (i * 1.5)

    case instrument
    when "rhodes"

      synth_rhodes(i, freq, gain, duration)

    when "cs80"

      synth_cs80(i, freq, gain, duration)

    when "minimoog"

      synth_minimoog(i, freq, gain, duration)

    when "strings"

      synth_strings(i, freq, gain, duration)

    when "ambient"

      synth_ambient(i, freq, gain, duration)

    when "oberheim"

      synth_oberheim(i, freq, gain, duration)

    else  # "fm" or default

      synth_fm(i, freq, gain, duration)

    end

  end

  voices = freqs.size.times.map { |i| "voice_#{i}.wav" }
  sox("-m #{voices.join(' ')} #{output}")

  cleanup(*voices)

end

# Generate bass layer (root note + sub-bass)
def generate_bass(root_freq, duration, output)

  # Root bass (sine)

  sox("-n bass_root.wav synth #{duration} sine #{root_freq} fade h 0.02 #{duration} 0.3 gain -3")

  # Sub-bass (octave down)

  sox("-n bass_sub.wav synth #{duration} sine #{root_freq / 2} fade h 0.02 #{duration} 0.3 gain -6")

  sox("-m bass_root.wav bass_sub.wav #{output}")

  cleanup("bass_root.wav", "bass_sub.wav")

end

# Apply FX chain from JSON with optional organic randomization and vinyl crackle
def apply_fx(input, output, fx_name, organic: false)

  fx = CHORD_THEORY["vintage_fx_chains"][fx_name]

  return unless fx

  # Handle organic randomization (template-based chains)
  if organic && fx["sox_chain_template"]

    chain = fx["sox_chain_template"].dup

    fx["randomize"]&.each do |param, config|

      value = rand(config["min"]..config["max"])

      chain.gsub!("{{#{param}}}", value.to_s)

    end

  else

    chain = fx["sox_chain"]

    return unless chain

  end

  # Apply base FX chain
  sox("#{input} temp_fx.wav #{chain}")

  # Add vinyl crackle layer if specified
  if fx["crackle_layer"]

    # Get duration of input file

    duration_cmd = "#{SOX} --info -D #{input}"

    duration = `#{duration_cmd}`.strip.to_f

    # Generate crackle
    crackle_params = fx["crackle_params"]

    sox("-n crackle.wav #{crackle_params} trim 0 #{duration}")

    # Mix crackle with processed audio
    sox("-m temp_fx.wav crackle.wav #{output}")

    cleanup("crackle.wav", "temp_fx.wav")

  else

    sox("temp_fx.wav #{output}")

    cleanup("temp_fx.wav")

  end

end

# Render complete progression
def render_progression(category, prog_name)

  prog_key = "#{category}_progressions"

  progression = CHORD_THEORY[prog_key][prog_name]

  return unless progression

  puts "\n🎹 #{progression['name']}"
  puts "   #{progression['theory']}" if progression["theory"]

  # Use frequencies if provided, otherwise skip (for now)
  freqs_array = progression["freqs"]

  return unless freqs_array

  duration = progression["duration"] || 2.0
  instrument = progression["instrument"] || "rhodes"

  fx = progression["fx"] || "dilla_butter"

  organic = progression["organic"] || false  # Enable per-progression organic mode

  # Generate each chord with voice leading optimization
  chord_files = []

  bass_files = []

  prev_freqs = nil  # Track previous chord for voice leading

  freqs_array.each_with_index do |freqs, i|
    # Optimize voicing based on previous chord

    optimized_freqs = optimize_voice_leading(prev_freqs, freqs)

    # Chord
    chord_file = "chord_#{i}.wav"

    generate_chord(optimized_freqs, duration, chord_file, instrument)

    chord_files << chord_file

    # Bass (root note - use original root, not optimized)
    bass_file = "bass_#{i}.wav"

    generate_bass(freqs[0], duration, bass_file)

    bass_files << bass_file

    prev_freqs = optimized_freqs  # Store for next iteration
    print "."

  end

  puts " ✓"

  # Concatenate and double for length
  sox("#{chord_files.join(' ')} #{chord_files.join(' ')} chords_raw.wav")

  sox("#{bass_files.join(' ')} #{bass_files.join(' ')} bass_raw.wav")

  cleanup(*chord_files, *bass_files)

  # Apply FX and save to directories (with organic mode)
  system("mkdir -p chords bass 2>/dev/null")

  apply_fx("chords_raw.wav", "chords/#{prog_name}.wav", fx, organic: organic)

  apply_fx("bass_raw.wav", "bass/#{prog_name}.wav", "warm_tape", organic: false)

  cleanup("chords_raw.wav", "bass_raw.wav")

  # Report organic mode status
  puts "   ⚡ Organic variation: #{organic ? 'ENABLED' : 'disabled'}" if organic

  puts "   → chords/#{prog_name}.wav"
  puts "   → bass/#{prog_name}.wav"

end

# Main execution
if __FILE__ == $0

  puts "\n" + ("=" * 70)

  puts "🎹 COMPREHENSIVE CHORD PAD GENERATOR + BASS LAYER"

  puts "=" * 70

  puts "\nVersion: #{CHORD_THEORY['meta']['version']}"

  puts "Evidence sources: #{CHORD_THEORY['meta']['evidence_sources'].size} academic/professional"

  # Render progressions with frequency data
  ["neo_soul"].each do |category|

    prog_key = "#{category}_progressions"

    next unless CHORD_THEORY[prog_key]

    puts "\n" + ("-" * 70)
    puts "📁 #{category.upcase.gsub('_', ' ')} PROGRESSIONS"

    puts "-" * 70

    CHORD_THEORY[prog_key].each do |prog_name, data|
      next unless data["freqs"]  # Only render if frequencies provided

      render_progression(category, prog_name)

    end

  end

  puts "\n" + ("=" * 70)
  puts "✅ GENERATION COMPLETE"

  puts "=" * 70

  puts "\nOutputs:"

  puts "  📁 chords/ - Chord progressions (Rhodes/FM synthesis)"

  puts "  📁 bass/ - Bass layers (sub-bass + root)"

  puts ""

end

