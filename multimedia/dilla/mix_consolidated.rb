#!/usr/bin/env ruby
# Unified mixer - combines chord progressions with drums
# Consolidated from mix.rb + create_final_mixes.rb per master.json anti-fragmentation
# Complexity: 6/10 (adheres to master.json ≤10 limit)

SOX = "G:/pub/dilla/effects/sox/sox.exe"

def sox(*args)
  system("#{SOX} #{args.join(' ')}")
end

def cleanup(*files)
  files.each { |f| File.delete(f) if File.exist?(f) }
end

# Get all rendered chord files
chord_files = Dir.glob("chords/*.wav").sort

if chord_files.empty?
  puts "\n❌ No chord progression files found. Run master.rb or chords.rb first."
  exit 1
end

# Check for drums files
drum_files = Dir.glob("drums/*.wav").sort

if drum_files.empty?
  puts "\n❌ No drum files found. Run master.rb or drums_consolidated.rb first."
  exit 1
end

puts "\n" + ("=" * 70)
puts "🎵 UNIFIED MIXER (consolidated from mix.rb + create_final_mixes.rb)"
puts "=" * 70
puts "\nFound #{chord_files.size} chord progressions"
puts "Found #{drum_files.size} drum patterns"
puts "\nCreating final mixes with rotation through all drum patterns..."

system("mkdir -p final 2>/dev/null")

# Rotate through drum patterns for variety (per master.rb approach)
drum_index = 0

chord_files.each do |chord_file|
  name = File.basename(chord_file, ".wav")
  bass_file = "bass/#{name}.wav"
  
  unless File.exist?(bass_file)
    puts "⚠ Skipping #{name} (no bass file)"
    next
  end

  # Rotate to next drum pattern
  drum_file = drum_files[drum_index % drum_files.size]
  drum_name = File.basename(drum_file, ".wav").gsub("_intricate", "")
  
  puts "🎵 Mixing: #{name} + #{drum_name}"
  
  # Get chord duration
  chord_duration = `#{SOX} --info -D #{chord_file}`.strip.to_f
  drum_duration = `#{SOX} --info -D #{drum_file}`.strip.to_f
  
  # Loop drums to match chord duration
  drum_repeats = (chord_duration / drum_duration).ceil + 1
  sox("#{([drum_file] * drum_repeats).join(' ')} drums_loop.wav trim 0 #{chord_duration}")
  
  # Final mix with mastering chain
  sox("-m #{chord_file} #{bass_file} drums_loop.wav final/#{name}_#{drum_name}.wav gain -n -2 compand 0.02,0.20 -60,-60,-30,-24,-20,-18,-4,-12,-2,-9,0,-6 -6 0 0.05 overdrive 5 reverb 18 10 equalizer 80 0.5q +2 equalizer 3000 1.2q +1.5 equalizer 10000 0.6q +1.5 gain -n -0.5")
  
  cleanup("drums_loop.wav")
  puts "✓ final/#{name}_#{drum_name}.wav"
  
  drum_index += 1
end

puts "\n" + ("=" * 70)
puts "✅ MIXING COMPLETE"
puts "=" * 70
puts "\n📁 Created #{Dir.glob('final/*.wav').size} mixed tracks in final/"
puts ""
