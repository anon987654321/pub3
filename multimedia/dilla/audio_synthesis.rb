#!/usr/bin/env ruby
# Audio Synthesis Utilities Module
# Provides comprehensive synthesis capabilities including FM synthesis,
# per-note swing timing, and advanced waveform generation

module AudioSynthesis
  # Default SoX path - can be overridden
  SOX_PATH = "G:/pub/dilla/effects/sox/sox.exe"

  class << self
    attr_accessor :sox_path

    def sox_path
      @sox_path ||= SOX_PATH
    end
  end

  # Execute SoX command
  def self.sox(*args)
    cmd = args.join(' ')
    system("#{sox_path} #{cmd}")
  end

  # Cleanup temporary files
  def self.cleanup(*files)
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

  # FM Synthesis with configurable parameters
  # operator_ratio: Frequency ratio between carrier and modulator (default 1.0)
  # mod_index: Modulation index/depth (default 2.0)
  # envelope: ADSR envelope type (:percussive, :pad, :pluck)
  def self.fm_synth(freq, duration, output_file, operator_ratio: 1.0, mod_index: 2.0, envelope: :percussive)
    mod_freq = freq * operator_ratio
    
    # Generate carrier (main frequency)
    sox("-n _carrier.wav synth #{duration} sine #{freq}")
    
    # Generate modulator (affects carrier frequency)
    sox("-n _modulator.wav synth #{duration} sine #{mod_freq} gain #{mod_index * 6}")
    
    # Apply modulation: carrier + (modulator * mod_index)
    # This creates the classic FM bell-like timbre
    sox("_carrier.wav _fm_raw.wav synth #{duration} sine #{freq} fmod _modulator.wav")
    
    # Apply envelope based on type
    case envelope
    when :percussive
      sox("_fm_raw.wav #{output_file} fade h 0.001 #{duration} 0.3 gain -6")
    when :pad
      sox("_fm_raw.wav #{output_file} fade h 0.5 #{duration} 1.5 gain -6")
    when :pluck
      sox("_fm_raw.wav #{output_file} fade h 0.001 #{duration} 0.1 gain -6")
    else
      sox("_fm_raw.wav #{output_file} fade h 0.01 #{duration} 0.5 gain -6")
    end
    
    cleanup("_carrier.wav", "_modulator.wav", "_fm_raw.wav")
  end

  # Advanced FM synthesis with multiple operators (Yamaha DX7 style)
  # operators: Array of {ratio, level} hashes
  def self.fm_multi_operator(freq, duration, output_file, operators: [{ratio: 1.0, level: 1.0}])
    temp_files = []
    
    operators.each_with_index do |op, i|
      op_freq = freq * op[:ratio]
      op_level = op[:level]
      op_file = "_op#{i}.wav"
      
      sox("-n #{op_file} synth #{duration} sine #{op_freq} gain #{-12 + (op_level * 6)}")
      temp_files << op_file
    end
    
    # Mix all operators
    sox("-m #{temp_files.join(' ')} _fm_multi_raw.wav")
    sox("_fm_multi_raw.wav #{output_file} fade h 0.01 #{duration} 0.5 gain -n -3")
    
    cleanup(*temp_files, "_fm_multi_raw.wav")
  end

  # Per-note swing timing
  # Applies J Dilla-style swing to individual notes with microtonality
  # swing_amount: 0.0-1.0, where 0.5 is no swing, >0.5 pushes notes later
  # microtonal_cents: Pitch variation in cents (-50 to +50)
  def self.apply_per_note_swing(notes, swing_amount: 0.542, microtonal_cents: 0)
    notes.map.with_index do |note, i|
      # Calculate swing offset for odd-indexed notes
      base_offset = note[:offset] || 0
      swing_offset = if i.odd?
        # Apply swing to odd notes (offbeats)
        note[:duration] * (swing_amount - 0.5) * 0.5
      else
        0
      end
      
      # Apply microtonality (frequency variation)
      base_freq = note[:freq]
      microtonal_factor = 2 ** (microtonal_cents / 1200.0)
      adjusted_freq = base_freq * microtonal_factor
      
      note.merge(
        offset: base_offset + swing_offset,
        freq: adjusted_freq,
        original_freq: base_freq
      )
    end
  end

  # Generate chord with per-note swing and microtonality
  # Each voice can have its own timing and pitch variation
  def self.generate_chord_with_swing(freqs, duration, output_file, swing: 0.542, microtonal_range: 5)
    voices = []
    
    freqs.each_with_index do |freq, i|
      # Apply per-note microtonality (random variation within range)
      microtonal_cents = (rand * 2 - 1) * microtonal_range
      adjusted_freq = freq * (2 ** (microtonal_cents / 1200.0))
      
      # Calculate per-note swing offset
      # Odd voices (index 1, 3, 5...) get pushed later
      time_offset = if i.odd?
        duration * (swing - 0.5) * 0.15  # 15% of the swing amount
      else
        0
      end
      
      voice_file = "voice_#{i}.wav"
      
      # Generate voice with 3-layer FM synthesis
      sox("-n saw#{i}.wav synth #{duration} sawtooth #{adjusted_freq} gain -18")
      sox("-n sqr#{i}.wav synth #{duration} square #{adjusted_freq} gain -20")
      sox("-n sin#{i}.wav synth #{duration} sine #{adjusted_freq} gain -16")
      sox("-m saw#{i}.wav sqr#{i}.wav sin#{i}.wav voice_raw_#{i}.wav")
      
      # Apply time offset if needed
      if time_offset > 0.001
        sox("voice_raw_#{i}.wav #{voice_file} pad #{time_offset} 0")
      else
        sox("voice_raw_#{i}.wav #{voice_file}")
      end
      
      cleanup("saw#{i}.wav", "sqr#{i}.wav", "sin#{i}.wav", "voice_raw_#{i}.wav")
      voices << voice_file
    end
    
    # Mix all voices
    sox("-m #{voices.join(' ')} #{output_file} gain -n")
    cleanup(*voices)
  end

  # Classic subtractive synthesis
  def self.subtractive_synth(freq, duration, output_file, filter_type: :lowpass, cutoff: 1000, resonance: 5)
    sox("-n _sub_raw.wav synth #{duration} sawtooth #{freq}")
    
    case filter_type
    when :lowpass
      sox("_sub_raw.wav #{output_file} lowpass #{cutoff} #{resonance}q fade h 0.01 #{duration} 0.5 gain -6")
    when :highpass
      sox("_sub_raw.wav #{output_file} highpass #{cutoff} #{resonance}q fade h 0.01 #{duration} 0.5 gain -6")
    when :bandpass
      sox("_sub_raw.wav #{output_file} bandpass #{cutoff} #{resonance}q fade h 0.01 #{duration} 0.5 gain -6")
    else
      sox("_sub_raw.wav #{output_file} lowpass #{cutoff} fade h 0.01 #{duration} 0.5 gain -6")
    end
    
    cleanup("_sub_raw.wav")
  end

  # Additive synthesis - build complex tones from sine harmonics
  def self.additive_synth(freq, duration, output_file, harmonics: [1.0, 0.5, 0.25, 0.125])
    temp_files = []
    
    harmonics.each_with_index do |level, i|
      harmonic_freq = freq * (i + 1)
      harm_file = "_harm#{i}.wav"
      
      sox("-n #{harm_file} synth #{duration} sine #{harmonic_freq} gain #{-12 + (level * 12)}")
      temp_files << harm_file
    end
    
    sox("-m #{temp_files.join(' ')} _add_raw.wav")
    sox("_add_raw.wav #{output_file} fade h 0.01 #{duration} 0.5 gain -n -3")
    
    cleanup(*temp_files, "_add_raw.wav")
  end

  # Wavetable synthesis using custom waveforms
  def self.wavetable_synth(freq, duration, output_file, waveform: :sine, harmonics: 3)
    case waveform
    when :pulse
      # PWM pulse wave
      sox("-n #{output_file} synth #{duration} pulse #{freq} gain -6")
    when :triangle
      sox("-n #{output_file} synth #{duration} triangle #{freq} gain -6")
    when :noise_filtered
      # Filtered noise for wind/breath sounds
      sox("-n _noise.wav synth #{duration} whitenoise")
      sox("_noise.wav #{output_file} bandpass #{freq} 100q gain -3")
      cleanup("_noise.wav")
    else
      sox("-n #{output_file} synth #{duration} #{waveform} #{freq} gain -6")
    end
  end

  # Generate bass with sub-harmonics
  def self.bass_synth(freq, duration, output_file, sub_octaves: 1)
    temp_files = []
    
    # Main bass frequency
    sox("-n _bass_main.wav synth #{duration} sine #{freq} gain -8")
    temp_files << "_bass_main.wav"
    
    # Add sub-octaves
    sub_octaves.times do |i|
      sub_freq = freq / (2 ** (i + 1))
      sub_file = "_bass_sub#{i}.wav"
      sox("-n #{sub_file} synth #{duration} sine #{sub_freq} gain #{-6 - i * 3}")
      temp_files << sub_file
    end
    
    sox("-m #{temp_files.join(' ')} #{output_file} gain -n")
    cleanup(*temp_files)
  end
end
