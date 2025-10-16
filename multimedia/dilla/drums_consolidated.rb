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
  full_cmd = "#{SOX} #{cmd}"
  puts "  → #{full_cmd[0..120]}" if ENV["DEBUG"]
  result = system(full_cmd)
  puts "  ⚠ SoX command failed" unless result
  result
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

# SP-1200 kick
def make_kick
  sox("-n -r 48000 _kick.wav synth 0.16 sine 58 fade h 0.001 0.16 0.06 overdrive 10 gain -3")
  "_kick.wav"
end

# SP-1200 snare
def make_snare
  sox("-n -r 48000 _snare.wav synth 0.12 noise lowpass 4000 highpass 200 fade h 0.001 0.12 0.04 overdrive 8 gain -6")
  "_snare.wav"
end

# Closed hi-hat
def make_hat_closed
  sox("-n -r 48000 _hat.wav synth 0.06 noise highpass 7000 fade h 0.001 0.06 0.02 gain -12")
  "_hat.wav"
end

# Open hi-hat
def make_hat_open
  sox("-n -r 48000 _hat_open.wav synth 0.25 noise highpass 6000 fade h 0.001 0.25 0.15 gain -10")
  "_hat_open.wav"
end

# TR-909 kick
def make_kick_909
  sox("-n -r 48000 _kick909.wav synth 0.18 sine 65 fade h 0.001 0.18 0.08 overdrive 15 gain -1")
  "_kick909.wav"
end

# Generate techno pattern - simple 4-on-floor with intricate hats
def generate_techno(tempo, bars)
  puts "🔊 Techno #{tempo} BPM (#{bars} bars)..."
  beat_sec = 60.0 / tempo
  bar_sec = beat_sec * 4
  total_sec = bar_sec * bars

  # Make samples
  kick = make_kick_909
  hat = make_hat_closed

  # Build kick sequence (4 on floor repeated)
  kick_seq = []
  bars.times do |bar|
    4.times do |beat|
      offset = bar * bar_sec + beat * beat_sec
      sox("#{kick} _k#{bar}_#{beat}.wav pad #{offset} 0")
      kick_seq << "_k#{bar}_#{beat}.wav"
    end
  end

  # Build intricate hat sequence (16th notes with dynamics)
  hat_seq = []
  bars.times do |bar|
    16.times do |sixteenth|
      offset = bar * bar_sec + sixteenth * (beat_sec / 4)
      dyn = (sixteenth % 4 == 0) ? 0 : -6  # Accent every 4th
      sox("#{hat} _h#{bar}_#{sixteenth}.wav pad #{offset} 0 gain #{dyn}")
      hat_seq << "_h#{bar}_#{sixteenth}.wav"
    end
  end

  # Mix all
  sox("-m #{kick_seq.join(' ')} _kicks.wav pad 0 #{total_sec}")
  sox("-m #{hat_seq.join(' ')} _hats.wav pad 0 #{total_sec}")
  sox("-m _kicks.wav _hats.wav drums/techno_intricate_#{tempo}bpm.wav gain -n -3")

  # Cleanup
  cleanup(*kick_seq, *hat_seq, "_kicks.wav", "_hats.wav", kick, hat)
  puts "✓ drums/techno_intricate_#{tempo}bpm.wav"
end

# Generate hip-hop pattern with swing and ghost notes
def generate_hiphop(tempo, swing_pct, bars)
  puts "🎵 Hip-Hop #{tempo} BPM #{swing_pct}% swing (#{bars} bars)..."
  beat_sec = 60.0 / tempo
  bar_sec = beat_sec * 4
  total_sec = bar_sec * bars

  # Calculate swing offset
  swing_factor = (swing_pct - 50) / 100.0
  swing_offset = (beat_sec / 8) * swing_factor

  # Make samples
  kick = make_kick
  snare = make_snare
  hat = make_hat_closed

  # Kick pattern: 1, 2-and, 3 (with swing on offbeats)
  kick_seq = []
  bars.times do |bar|
    base = bar * bar_sec
    # Beat 1
    sox("#{kick} _k#{bar}_0.wav pad #{base} 0")
    kick_seq << "_k#{bar}_0.wav"
    # Beat 2-and (swung)
    sox("#{kick} _k#{bar}_1.wav pad #{base + beat_sec + beat_sec/2 + swing_offset} 0 gain -2")
    kick_seq << "_k#{bar}_1.wav"
    # Beat 3
    sox("#{kick} _k#{bar}_2.wav pad #{base + beat_sec * 2} 0")
    kick_seq << "_k#{bar}_2.wav"
  end

  # Snare pattern: 2, 4 + ghost notes
  snare_seq = []
  bars.times do |bar|
    base = bar * bar_sec
    # Main snares on 2 and 4
    sox("#{snare} _s#{bar}_0.wav pad #{base + beat_sec} 0")
    snare_seq << "_s#{bar}_0.wav"
    sox("#{snare} _s#{bar}_1.wav pad #{base + beat_sec * 3} 0")
    snare_seq << "_s#{bar}_1.wav"
    # Ghost notes (swung 8th notes between)
    [0.5, 1.5, 2.5, 3.5].each_with_index do |beat_pos, idx|
      offset = base + beat_pos * beat_sec + (idx.odd? ? swing_offset : 0)
      sox("#{snare} _sg#{bar}_#{idx}.wav pad #{offset} 0 gain -18")
      snare_seq << "_sg#{bar}_#{idx}.wav"
    end
  end

  # Hat pattern: swung 8th notes
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

  # Mix all
  sox("-m #{kick_seq.join(' ')} _kicks.wav pad 0 #{total_sec}")
  sox("-m #{snare_seq.join(' ')} _snares.wav pad 0 #{total_sec}")
  sox("-m #{hat_seq.join(' ')} _hats.wav pad 0 #{total_sec}")
  sox("-m _kicks.wav _snares.wav _hats.wav drums/hiphop_intricate_#{tempo}bpm_#{swing_pct}swing.wav gain -n -3")

  # Cleanup
  cleanup(*kick_seq, *snare_seq, *hat_seq, "_kicks.wav", "_snares.wav", "_hats.wav", kick, snare, hat)
  puts "✓ drums/hiphop_intricate_#{tempo}bpm_#{swing_pct}swing.wav"
end

# Main
if __FILE__ == $0
  puts "\n" + ("=" * 70)
  puts "🥁 CONSOLIDATED DRUM GENERATOR (unified from drums.rb + drums_fixed.rb)"
  puts "=" * 70

  system("mkdir -p drums 2>/dev/null")
  
  puts "\n📊 TECHNO PATTERNS"
  [128, 130, 135, 140].each { |t| generate_techno(t, 4) }

  puts "\n📊 HIP-HOP PATTERNS"
  [[90, 58], [92, 58], [95, 62], [85, 54]].each { |t, s| generate_hiphop(t, s, 4) }

  puts "\n" + ("=" * 70)
  puts "✅ DRUM GENERATION COMPLETE"
  puts "=" * 70
  puts "\n📁 Created 8 intricate patterns in drums/"
  puts ""
end
