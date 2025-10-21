#!/usr/bin/env ruby
# Synthesis Examples - Demonstrates new audio synthesis capabilities
# Tests per-note swing, FM synthesis, and various synthesis methods

require_relative 'audio_synthesis'

puts "Audio Synthesis Examples"
puts "=" * 70

# Set SoX path
AudioSynthesis.sox_path = "G:/pub/dilla/effects/sox/sox.exe"

# Create output directory
system("mkdir -p synthesis_examples 2>/dev/null")

# Example 1: Basic FM Synthesis
puts "\n1. Basic FM Synthesis (DX7-style electric piano)"
AudioSynthesis.fm_synth(
  261.63,  # Middle C
  2.0,     # 2 seconds
  "synthesis_examples/fm_basic.wav",
  operator_ratio: 14.0,
  mod_index: 2.0,
  envelope: :percussive
)
puts "   ✓ Created synthesis_examples/fm_basic.wav"

# Example 2: Multi-operator FM (complex timbre)
puts "\n2. Multi-operator FM Synthesis (bell-like tone)"
AudioSynthesis.fm_multi_operator(
  440.0,  # A4
  2.5,
  "synthesis_examples/fm_multi_bell.wav",
  operators: [
    {ratio: 1.0, level: 1.0},   # Fundamental
    {ratio: 3.5, level: 0.8},   # Harmonic overtone
    {ratio: 14.0, level: 0.6},  # High shimmer
    {ratio: 0.5, level: 0.4}    # Sub-harmonic warmth
  ]
)
puts "   ✓ Created synthesis_examples/fm_multi_bell.wav"

# Example 3: Chord with per-note swing timing
puts "\n3. Chord with Per-Note Swing (J Dilla style)"
chord_freqs = [261.63, 329.63, 392.00, 493.88]  # Cmaj7
AudioSynthesis.generate_chord_with_swing(
  chord_freqs,
  2.0,
  "synthesis_examples/chord_swing.wav",
  swing: 0.58,           # 58% swing (Dilla's golden ratio)
  microtonal_range: 8    # ±8 cents variation
)
puts "   ✓ Created synthesis_examples/chord_swing.wav (with swing & microtonality)"

# Example 4: Comparison - Same chord without swing
puts "\n4. Same Chord Without Swing (for comparison)"
voices = []
chord_freqs.each_with_index do |freq, i|
  sox_cmd = "#{AudioSynthesis.sox_path} -n saw#{i}.wav synth 2.0 sawtooth #{freq} gain -18"
  system(sox_cmd)
  sox_cmd = "#{AudioSynthesis.sox_path} -n sqr#{i}.wav synth 2.0 square #{freq} gain -20"
  system(sox_cmd)
  sox_cmd = "#{AudioSynthesis.sox_path} -n sin#{i}.wav synth 2.0 sine #{freq} gain -16"
  system(sox_cmd)
  sox_cmd = "#{AudioSynthesis.sox_path} -m saw#{i}.wav sqr#{i}.wav sin#{i}.wav voice_#{i}.wav"
  system(sox_cmd)
  AudioSynthesis.cleanup("saw#{i}.wav", "sqr#{i}.wav", "sin#{i}.wav")
  voices << "voice_#{i}.wav"
end
system("#{AudioSynthesis.sox_path} -m #{voices.join(' ')} synthesis_examples/chord_no_swing.wav gain -n")
AudioSynthesis.cleanup(*voices)
puts "   ✓ Created synthesis_examples/chord_no_swing.wav (no swing)"

# Example 5: Subtractive synthesis - lowpass filter sweep
puts "\n5. Subtractive Synthesis (classic analog sound)"
AudioSynthesis.subtractive_synth(
  110.0,  # A2
  3.0,
  "synthesis_examples/subtractive_lowpass.wav",
  filter_type: :lowpass,
  cutoff: 800,
  resonance: 8
)
puts "   ✓ Created synthesis_examples/subtractive_lowpass.wav"

# Example 6: Additive synthesis - organ-like
puts "\n6. Additive Synthesis (Hammond organ style)"
AudioSynthesis.additive_synth(
  196.0,  # G3
  2.5,
  "synthesis_examples/additive_organ.wav",
  harmonics: [1.0, 0.8, 0.6, 0.4, 0.3, 0.2, 0.15, 0.1]
)
puts "   ✓ Created synthesis_examples/additive_organ.wav"

# Example 7: Bass synthesis with sub-harmonics
puts "\n7. Bass Synthesis (deep sub-bass)"
AudioSynthesis.bass_synth(
  55.0,   # A1
  3.0,
  "synthesis_examples/bass_deep.wav",
  sub_octaves: 2  # Add 2 octaves below
)
puts "   ✓ Created synthesis_examples/bass_deep.wav"

# Example 8: Wavetable synthesis - various waveforms
puts "\n8. Wavetable Synthesis (pulse wave)"
AudioSynthesis.wavetable_synth(
  329.63,  # E4
  2.0,
  "synthesis_examples/wavetable_pulse.wav",
  waveform: :pulse
)
puts "   ✓ Created synthesis_examples/wavetable_pulse.wav"

# Example 9: Demonstration of per-note swing on a full progression
puts "\n9. Full Chord Progression with Per-Note Swing"
progression = [
  {name: "Dm9", freqs: [146.83, 174.61, 220.00, 261.63, 329.63]},
  {name: "G13", freqs: [196.00, 246.94, 293.66, 392.00, 493.88]},
  {name: "Cmaj9", freqs: [130.81, 164.81, 196.00, 246.94, 329.63]},
  {name: "Fmaj13", freqs: [174.61, 220.00, 261.63, 329.63, 440.00]}
]

chord_files = []
progression.each_with_index do |chord, i|
  file = "synthesis_examples/prog_#{i}.wav"
  AudioSynthesis.generate_chord_with_swing(
    chord[:freqs],
    2.0,
    file,
    swing: 0.542,  # Golden ratio swing
    microtonal_range: 5
  )
  chord_files << file
  print "   #{chord[:name]}... "
end
puts

# Concatenate progression
system("#{AudioSynthesis.sox_path} #{chord_files.join(' ')} synthesis_examples/progression_swing.wav gain -n -2")
AudioSynthesis.cleanup(*chord_files)
puts "   ✓ Created synthesis_examples/progression_swing.wav"

puts "\n" + ("=" * 70)
puts "Examples complete! Created #{Dir.glob('synthesis_examples/*.wav').size} audio files"
puts "\nFiles created in synthesis_examples/ directory:"
Dir.glob('synthesis_examples/*.wav').sort.each do |f|
  puts "  - #{File.basename(f)}"
end
puts "\nCompare chord_swing.wav vs chord_no_swing.wav to hear the difference!"
