#!/usr/bin/env ruby
# Simple mixer to combine chord progressions with drums

SOX = "G:/pub/dilla/effects/sox/sox.exe"
def sox(*args)
  system("#{SOX} #{args.join(' ')}")

end

def cleanup(*files)
  files.each { |f| File.delete(f) if File.exist?(f) }

end

# Mix chord progression with drums
def mix(chords_file, drums_file, output)

  # Get duration of chord file

  duration_cmd = "#{SOX} --info -D #{chords_file}"

  duration = `#{duration_cmd}`.strip.to_f

  # Loop drums to match chord duration
  sox("#{drums_file} drums_loop.wav repeat #{(duration / 8).ceil}")

  sox("drums_loop.wav drums_trimmed.wav trim 0 #{duration}")

  # Mix: chords at 0dB, drums at -6dB for balance
  sox("-m #{chords_file} drums_trimmed.wav temp.wav")

  # Final normalization and limiting
  sox("temp.wav #{output} norm -2 compand 0.05,0.2 6:-70,-60,-20 -6 -90 0.1")

  cleanup("drums_loop.wav", "drums_trimmed.wav", "temp.wav")
end

puts "J Dilla Mixer - Combining Chords + Drums"
puts "=" * 60

# Get all chord progression files (exclude stems and temp files)
chord_files = Dir.glob("*.wav").select do |f|

  !f.match?(/drums|mix_|temp|loop|trimmed|_raw|voice_|hit_|pos_|pad_/)

end

# Also check chords/ directory if it exists
chord_files += Dir.glob("chords/*.wav") if Dir.exist?("chords")

if chord_files.empty?
  puts "\n❌ No chord progression files found. Run chords.rb first."

  exit 1

end

# Check for drums files
drum_files = Dir.glob("drums/*.wav") + Dir.glob("drums.wav")

if drum_files.empty?

  puts "\n❌ No drum files found. Run drums.rb first."

  exit 1

end

# Use first drum file found
drum_file = drum_files.first

puts "\nFound #{chord_files.size} chord progressions"
puts "Mixing each with drums.wav...\n"

# Mix each progression
system("mkdir -p mix 2>/dev/null")

chord_files.each do |chord_file|

  name = File.basename(chord_file, ".wav")

  output = "mix/#{name}.wav"

  print "  #{name}... "
  mix(chord_file, drum_file, output)

  puts "✓"

end

puts "\n" + "=" * 60
puts "Complete! Created #{chord_files.size} mixed tracks."

puts "\nFiles created:"

Dir.glob("mix/*.wav").each { |f| puts "  - #{f}" }

