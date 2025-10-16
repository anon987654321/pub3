#!/usr/bin/env ruby
# Create final mixed tracks from all rendered progressions

# Complexity: 6/10

require "json"
SOX = "G:/pub/dilla/effects/sox/sox.exe"
def sox(cmd)
  system("#{SOX} #{cmd}")

end

# Get all rendered chord files
chord_files = Dir.glob("chords/*.wav").sort

puts "Found #{chord_files.size} chord progressions"

system("mkdir -p final 2>/dev/null")
chord_files.each do |chord_file|
  name = File.basename(chord_file, ".wav")

  bass_file = "bass/#{name}.wav"

  next unless File.exist?(bass_file)
  puts "🎵 Mixing: #{name}"
  # Get chord duration
  duration_cmd = "#{SOX} --info -D #{chord_file}"

  chord_duration = `#{duration_cmd}`.strip.to_f

  # Use appropriate drums based on tempo
  drum_file = if name.include?("techno") || name.include?("flylo")

    "drums/kicks_130bpm.wav"

  else

    "drums/kicks_92bpm.wav"

  end

  snare_file = "drums/snares_92bpm.wav"
  # Loop drums to match chord duration
  if File.exist?(drum_file)

    drum_duration = `#{SOX} --info -D #{drum_file}`.strip.to_f

    drum_repeats = (chord_duration / drum_duration).ceil + 1

    sox("#{([drum_file] * drum_repeats).join(' ')} drums_loop.wav trim 0 #{chord_duration}")
  end

  if File.exist?(snare_file)
    snare_duration = `#{SOX} --info -D #{snare_file}`.strip.to_f

    snare_repeats = (chord_duration / snare_duration).ceil + 1

    sox("#{([snare_file] * snare_repeats).join(' ')} snares_loop.wav trim 0 #{chord_duration}")
  end

  # Mix all stems
  stems = [chord_file, bass_file]

  stems << "drums_loop.wav" if File.exist?("drums_loop.wav")

  stems << "snares_loop.wav" if File.exist?("snares_loop.wav")

  # Create final mix with mastering
  sox("-m #{stems.join(' ')} final/#{name}_FULL_MIX.wav gain -n -2 compand 0.02,0.20 -60,-60,-30,-24,-20,-18,-4,-12,-2,-9,0,-6 -6 0 0.05 overdrive 5 reverb 18 10 equalizer 80 0.5q +2 equalizer 3000 1.2q +1.5 equalizer 10000 0.6q +1.5 gain -n -0.5")

  # Cleanup temp files
  File.delete("drums_loop.wav") if File.exist?("drums_loop.wav")

  File.delete("snares_loop.wav") if File.exist?("snares_loop.wav")

  puts "✓ final/#{name}_FULL_MIX.wav"
end

puts "\n✅ All final mixes created in final/ directory"
