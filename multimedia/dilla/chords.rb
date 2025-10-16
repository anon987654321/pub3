#!/usr/bin/env ruby
# Simple J Dilla chord generator - FM SYNTHESIS + HALL OF FAME PRESETS

SOX = "G:/pub/dilla/effects/sox/sox.exe"
# Hall of Fame FX Presets
FX_PRESETS = {

  warm_tape: "compand 0.3,1 -inf,-70,-60,-20 -5 -90 0.2 reverb 35 50 80 norm -2 dither -s",

  lofi_dream: "compand 0.05,0.2 -inf,-70,-50,-20 -6 -90 0.1 reverb 40 60 90 norm -2 dither -s",

  dilla_butter: "compand 0.1,0.3 -inf,-70,-55,-20 -6 -90 0.15 reverb 30 50 85 norm -2 dither -s",

  analog_lush: "compand 0.2,0.4 -inf,-65,-50,-30 -5 -90 0.18 reverb 45 60 95 norm -2 dither -s"

}

PROGRESSIONS = {
  dilla_life: {

    name: "J Dilla 'Life'",

    tempo: 90,

    duration: 2.0,

    fx: :dilla_butter,

    chords: [

      { name: 'Bbm9', freqs: [116.54, 174.61, 220.00, 261.63, 329.63] },

      { name: 'C7', freqs: [130.81, 164.81, 196.00, 233.08, 293.66] },

      { name: 'Fm9', freqs: [174.61, 207.65, 261.63, 311.13, 392.00] },

      { name: 'Bbm9', freqs: [116.54, 174.61, 220.00, 261.63, 329.63] }

    ]

  },

  neo_soul: {

    name: "Neo-Soul Classic",

    tempo: 90,

    duration: 2.0,

    fx: :warm_tape,

    chords: [

      { name: 'Cmaj9', freqs: [130.81, 164.81, 196.00, 246.94, 329.63] },

      { name: 'Am11', freqs: [110.00, 164.81, 220.00, 261.63, 329.63] },

      { name: 'Fmaj13', freqs: [174.61, 220.00, 261.63, 329.63, 440.00] },

      { name: 'G13sus', freqs: [196.00, 261.63, 293.66, 392.00, 493.88] }

    ]

  },

  dreamscape: {

    name: "Dilla Dreamscape",

    tempo: 85,

    duration: 2.5,

    fx: :lofi_dream,

    chords: [

      { name: 'Ebmaj9', freqs: [155.56, 196.00, 233.08, 293.66, 369.99] },

      { name: 'Cm9', freqs: [130.81, 155.56, 196.00, 233.08, 293.66] },

      { name: 'Abmaj13', freqs: [207.65, 261.63, 311.13, 415.30, 523.25] },

      { name: 'Bb13sus', freqs: [233.08, 311.13, 349.23, 466.16, 587.33] }

    ]

  },

  floating: {

    name: "Floating Rhodes",

    tempo: 92,

    duration: 2.0,

    fx: :analog_lush,

    chords: [

      { name: 'Dmaj9', freqs: [146.83, 185.00, 220.00, 277.18, 369.99] },

      { name: 'Bm11', freqs: [123.47, 185.00, 246.94, 293.66, 369.99] },

      { name: 'Gmaj9#11', freqs: [196.00, 246.94, 293.66, 392.00, 493.88] },

      { name: 'A13sus', freqs: [220.00, 293.66, 329.63, 440.00, 554.37] }

    ]

  },

  soulquarian: {

    name: "Soulquarian Butter",

    tempo: 96,

    duration: 2.0,

    fx: :dilla_butter,

    chords: [

      { name: 'Fmaj9', freqs: [174.61, 220.00, 261.63, 329.63, 440.00] },

      { name: 'Dm11', freqs: [146.83, 220.00, 293.66, 349.23, 440.00] },

      { name: 'Bbmaj13', freqs: [233.08, 293.66, 349.23, 466.16, 587.33] },

      { name: 'C13', freqs: [130.81, 164.81, 196.00, 246.94, 329.63] }

    ]

  },

  donut_shop: {

    name: "Donut Shop Dreams",

    tempo: 82,

    duration: 2.5,

    fx: :lofi_dream,

    chords: [

      { name: 'Amaj9', freqs: [110.00, 138.59, 164.81, 207.65, 277.18] },

      { name: 'F#m11', freqs: [92.50, 138.59, 185.00, 220.00, 277.18] },

      { name: 'Dmaj9', freqs: [146.83, 185.00, 220.00, 277.18, 369.99] },

      { name: 'E13sus', freqs: [164.81, 220.00, 246.94, 329.63, 415.30] }

    ]

  },

  slum_village: {

    name: "Slum Village Glow",

    tempo: 98,

    duration: 2.0,

    fx: :warm_tape,

    chords: [

      { name: 'Gmaj9', freqs: [196.00, 246.94, 293.66, 369.99, 493.88] },

      { name: 'Em11', freqs: [164.81, 246.94, 329.63, 392.00, 493.88] },

      { name: 'Cmaj13', freqs: [130.81, 164.81, 196.00, 261.63, 349.23] },

      { name: 'D13sus', freqs: [146.83, 196.00, 220.00, 293.66, 369.99] }

    ]

  },

  ethiojazz: {

    name: "Ethiojazz Nights",

    tempo: 80,

    duration: 2.5,

    fx: :analog_lush,

    chords: [

      { name: 'Dm9(b5)', freqs: [146.83, 174.61, 207.65, 261.63, 329.63] },

      { name: 'Gm11', freqs: [196.00, 293.66, 392.00, 466.16, 587.33] },

      { name: 'Ebmaj7#11', freqs: [155.56, 196.00, 246.94, 311.13, 415.30] },

      { name: 'Am7b13', freqs: [110.00, 130.81, 164.81, 207.65, 261.63] }

    ]

  },

  ahmad_jamal: {

    name: "Ahmad Jamal 'Awakening'",

    tempo: 88,

    duration: 2.2,

    fx: :dilla_butter,

    chords: [

      { name: 'Emaj7', freqs: [164.81, 207.65, 246.94, 311.13] },

      { name: 'G#m7', freqs: [207.65, 246.94, 311.13, 369.99] },

      { name: 'C#m7', freqs: [138.59, 164.81, 207.65, 246.94] },

      { name: 'F#9', freqs: [92.50, 116.54, 138.59, 174.61, 220.00] }

    ]

  },

  isley_brothers: {

    name: "Isley Brothers Style",

    tempo: 92,

    duration: 2.0,

    fx: :analog_lush,

    chords: [

      { name: 'Gbmaj9', freqs: [185.00, 233.08, 277.18, 349.23, 466.16] },

      { name: 'Ebm11', freqs: [155.56, 233.08, 311.13, 369.99, 466.16] },

      { name: 'Abm9', freqs: [207.65, 246.94, 311.13, 369.99, 493.88] },

      { name: 'Db13', freqs: [138.59, 174.61, 207.65, 261.63, 349.23] }

    ]

  },

  modal_jazz: {

    name: "Modal Jazz",

    tempo: 80,

    duration: 2.5,

    fx: :warm_tape,

    chords: [

      { name: 'Ebmaj7#5', freqs: [155.56, 196.00, 246.94, 329.63] },

      { name: 'Fm11', freqs: [174.61, 261.63, 349.23, 415.30, 523.25] },

      { name: 'Dbmaj9', freqs: [138.59, 174.61, 207.65, 261.63, 349.23] },

      { name: 'Cm7', freqs: [130.81, 155.56, 196.00, 233.08] }

    ]

  }

}

def sox(*args)
  cmd = args.join(' ')

  system("#{SOX} #{cmd}")

end

def cleanup(*files)
  files.each { |f| File.delete(f) if File.exist?(f) }

end

# FM Synthesis: 3-layer (sawtooth + square + sine)
def generate_chord(freqs, duration, output)

  voices = freqs.each_with_index.map do |freq, i|

    # Layer 1: Sawtooth (rich harmonics)

    sox("-n saw#{i}.wav synth #{duration} sawtooth #{freq} gain -18")

    # Layer 2: Square (warmth)

    sox("-n sqr#{i}.wav synth #{duration} square #{freq} gain -20")

    # Layer 3: Sine (fundamental)

    sox("-n sin#{i}.wav synth #{duration} sine #{freq} gain -16")

    # Mix all 3 layers per voice
    file = "v#{i}.wav"

    sox("-m saw#{i}.wav sqr#{i}.wav sin#{i}.wav #{file}")

    cleanup("saw#{i}.wav", "sqr#{i}.wav", "sin#{i}.wav")

    file

  end

  sox("-m #{voices.join(' ')} #{output}")

  cleanup(*voices)

end

# Apply Hall of Fame preset
def apply_fx(input, output, preset_name)

  preset = FX_PRESETS[preset_name] || FX_PRESETS[:dilla_butter]

  sox("#{input} #{output} #{preset}")

end

puts "J Dilla FM Synthesis Generator - Hall of Fame Presets"
puts "=" * 60

# Generate all progressions
PROGRESSIONS.each do |key, prog|

  puts "\nGenerating: #{prog[:name]} (#{prog[:fx]})"

  # Generate all chords
  chord_files = prog[:chords].map.with_index do |chord, i|

    file = "c#{i}.wav"

    generate_chord(chord[:freqs], prog[:duration], file)

    print "  #{chord[:name]}... "

    file

  end

  puts

  # Concatenate (doubled for length)
  sox("#{chord_files.join(' ')} #{chord_files.join(' ')} temp.wav")

  # Apply Hall of Fame preset
  output = "#{key}.wav"

  apply_fx("temp.wav", output, prog[:fx])

  cleanup("temp.wav", *chord_files)
  puts "  ✓ Created #{output}"

end

puts "\n" + "=" * 60
puts "Complete! Created #{PROGRESSIONS.size} progressions with FM synthesis."

