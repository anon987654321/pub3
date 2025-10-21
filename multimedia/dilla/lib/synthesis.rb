#!/usr/bin/env ruby
# Dilla Synthesis Library - Extract from duplicated code
# Provides 7 synth types used across multiple scripts

module Dilla
  module Synthesis
    # Rhodes electric piano: 3 sine harmonics (bright, melodic)
    def self.rhodes(i, freq, gain, duration, sox_cmd)
      system("#{sox_cmd} -n sin1_#{i}.wav synth #{duration} sine #{freq} fade h 0.01 #{duration} 0.5 gain #{gain}")
      system("#{sox_cmd} -n sin2_#{i}.wav synth #{duration} sine #{freq * 2} fade h 0.01 #{duration} 0.5 gain #{gain - 8}")
      system("#{sox_cmd} -n sin3_#{i}.wav synth #{duration} sine #{freq * 3} fade h 0.01 #{duration} 0.5 gain #{gain - 12}")
      system("#{sox_cmd} -m sin1_#{i}.wav sin2_#{i}.wav sin3_#{i}.wav rhodes_raw_#{i}.wav")
      system("#{sox_cmd} rhodes_raw_#{i}.wav voice_#{i}.wav tremolo 5.5 30 chorus 0.6 0.9 45 0.4 2 -t")
      cleanup("sin1_#{i}.wav", "sin2_#{i}.wav", "sin3_#{i}.wav", "rhodes_raw_#{i}.wav")
    end

    # FM synthesis: sawtooth + square + sine (warm, rich)
    def self.fm(i, freq, gain, duration, sox_cmd)
      system("#{sox_cmd} -n saw#{i}.wav synth #{duration} sawtooth #{freq} gain #{gain}")
      system("#{sox_cmd} -n sqr#{i}.wav synth #{duration} square #{freq} gain #{gain - 2}")
      system("#{sox_cmd} -n sin#{i}.wav synth #{duration} sine #{freq} gain #{gain + 2}")
      system("#{sox_cmd} -m saw#{i}.wav sqr#{i}.wav sin#{i}.wav voice_#{i}.wav")
      cleanup("saw#{i}.wav", "sqr#{i}.wav", "sin#{i}.wav")
    end

    # CS-80 Vangelis style: Detuned saws with slow envelopes (Blade Runner)
    def self.cs80(i, freq, gain, duration, sox_cmd)
      detune = freq * 1.0091  # ~8 cents detune
      system("#{sox_cmd} -n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 3 #{duration} 4 gain #{gain}")
      system("#{sox_cmd} -n saw2_#{i}.wav synth #{duration} sawtooth #{detune} fade h 3 #{duration} 4 gain #{gain - 2}")
      system("#{sox_cmd} -m saw1_#{i}.wav saw2_#{i}.wav cs80_raw_#{i}.wav")
      system("#{sox_cmd} cs80_raw_#{i}.wav voice_#{i}.wav lowpass 600 chorus 0.7 0.9 50 0.4 2 -t")
      cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "cs80_raw_#{i}.wav")
    end

    # Minimoog brass: Saw + detuned square with filter envelope (Pink Floyd)
    def self.minimoog(i, freq, gain, duration, sox_cmd)
      detune = freq * 1.0029  # ~5 cents
      system("#{sox_cmd} -n saw#{i}.wav synth #{duration} sawtooth #{freq} fade h 1 #{duration} 4 gain #{gain}")
      system("#{sox_cmd} -n sqr#{i}.wav synth #{duration} square #{detune} fade h 1 #{duration} 4 gain #{gain - 3}")
      system("#{sox_cmd} -m saw#{i}.wav sqr#{i}.wav moog_raw_#{i}.wav")
      system("#{sox_cmd} moog_raw_#{i}.wav voice_#{i}.wav lowpass 1200 overdrive 5 chorus 0.6 0.9 40 0.4 2 -t")
      cleanup("saw#{i}.wav", "sqr#{i}.wav", "moog_raw_#{i}.wav")
    end

    # String ensemble: 3-voice detuned saws (ARP Solina / Ultravox Vienna)
    def self.strings(i, freq, gain, duration, sox_cmd)
      detune1 = freq * 1.0012  # ~2 cents
      detune2 = freq * 1.0023  # ~4 cents
      system("#{sox_cmd} -n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 0.5 #{duration} 2 gain #{gain}")
      system("#{sox_cmd} -n saw2_#{i}.wav synth #{duration} sawtooth #{detune1} fade h 0.5 #{duration} 2 gain #{gain - 1}")
      system("#{sox_cmd} -n saw3_#{i}.wav synth #{duration} sawtooth #{detune2} fade h 0.5 #{duration} 2 gain #{gain - 2}")
      system("#{sox_cmd} -m saw1_#{i}.wav saw2_#{i}.wav saw3_#{i}.wav strings_raw_#{i}.wav")
      system("#{sox_cmd} strings_raw_#{i}.wav strings_chorus_#{i}.wav lowpass 3000 chorus 0.7 0.9 55 0.5 2 -t")
      system("#{sox_cmd} strings_chorus_#{i}.wav voice_#{i}.wav overdrive 3")
      cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "saw3_#{i}.wav", "strings_raw_#{i}.wav", "strings_chorus_#{i}.wav")
    end

    # Ambient pad: Sine + saw blend with ultra-slow envelopes (Brian Eno)
    def self.ambient(i, freq, gain, duration, sox_cmd)
      detune = freq * 1.0006  # ~1 cent (subtle)
      system("#{sox_cmd} -n sine#{i}.wav synth #{duration} sine #{freq} fade h 5 #{duration} 6 gain #{gain}")
      system("#{sox_cmd} -n saw#{i}.wav synth #{duration} sawtooth #{detune} fade h 5 #{duration} 6 gain #{gain - 8}")
      system("#{sox_cmd} -m sine#{i}.wav saw#{i}.wav voice_#{i}.wav highpass 80")
      cleanup("sine#{i}.wav", "saw#{i}.wav")
    end

    # Oberheim OB-X: Unison detuned saws (Frank Ocean, Van Halen)
    def self.oberheim(i, freq, gain, duration, sox_cmd)
      detune = freq * 1.0046  # ~8 cents
      system("#{sox_cmd} -n saw1_#{i}.wav synth #{duration} sawtooth #{freq} fade h 1.5 #{duration} 3.5 gain #{gain}")
      system("#{sox_cmd} -n saw2_#{i}.wav synth #{duration} sawtooth #{detune} fade h 1.5 #{duration} 3.5 gain #{gain - 2}")
      system("#{sox_cmd} -m saw1_#{i}.wav saw2_#{i}.wav ob_raw_#{i}.wav")
      system("#{sox_cmd} ob_raw_#{i}.wav voice_#{i}.wav lowpass 1500 chorus 0.7 0.85 48 0.5 2 -t")
      cleanup("saw1_#{i}.wav", "saw2_#{i}.wav", "ob_raw_#{i}.wav")
    end

    private

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
  end
end
