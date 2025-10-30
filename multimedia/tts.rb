#!/usr/bin/env ruby
# frozen_string_literal: true

# Organisk Rytmegenerator v60.10 - Malaysisk TTS + Norske Kommentarer (master.json v43.0.0)

# Integrert TTS v3.0.0 med dyp malaysisk stemme, norske kommentarer

require 'fileutils'
require 'net/http'

require 'uri'

require 'cgi'

CHECKPOINT_DIR = '/tmp/dilla_checkpoints'
STEMS_DIR = "#{Dir.pwd}/stems"

TTS_CACHE_DIR = "#{Dir.pwd}/tts_cache"

LOG_FILE = "#{CHECKPOINT_DIR}/tts_debug.log"

[CHECKPOINT_DIR, STEMS_DIR, TTS_CACHE_DIR].each { |d| FileUtils.mkdir_p(d) }
# === TTS v3.0.0 INTEGRASJON ===
# Malaysisk stemme: dyp, beroligende, -12.5 halvtoner

MALAY_VOICE = {

  lang: "ms",

  tld: "com.my",

  pitch: -12.5,

  bass: 8,

  treble: -2,

  reverb: 20,

  name: "Deep Soothing Malaysian"

}.freeze

def fetch_tts(text)
  # Generer hash for caching

  hash = "#{text}#{MALAY_VOICE[:lang]}#{MALAY_VOICE[:tld]}".hash.abs.to_s

  mp3 = "#{TTS_CACHE_DIR}/#{hash}.mp3"

  return mp3 if File.exist?(mp3)

  # Hent fra Google Translate TTS API
  url = "https://translate.google.com/translate_tts?" \

        "ie=UTF-8&client=tw-ob&tl=#{MALAY_VOICE[:lang]}&ttsspeed=0.85&tld=#{MALAY_VOICE[:tld]}&q=#{CGI.escape(text)}"

  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|

    req = Net::HTTP::Get.new(uri)

    req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

    req["Referer"] = "https://translate.google.com/"

    res = http.request(req)
    if res.code == "200" && res.body.size > 1000

      File.binwrite(mp3, res.body)

      log_tts("TTS cachet: #{hash}.mp3 (#{res.body.size} bytes)")

      return mp3

    else

      log_tts("TTS API-feil: #{res.code}")

      return nil

    end

  end

rescue => e

  log_tts("Nettverksfeil: #{e.message}")

  nil

end

def play_mp3(file)
  return unless File.exist?(file)

  # Konverter til Windows-sti
  win_path = `cygpath -w "#{file}" 2>/dev/null`.chomp

  win_path = file if win_path.empty?

  # Spill av med cmd.exe (mest pålitelig på Windows)
  system("cmd.exe /c start /min \"\" \"#{win_path}\" 2>/dev/null")

  # Estimer varighet og sov
  sleep((File.size(file) / 8000.0).ceil)

end

def speak(text)
  return unless text

  Thread.new do
    begin

      log_tts("Snakker: #{text[0..50]}...")

      mp3 = fetch_tts(text)

      if mp3

        play_mp3(mp3)

        log_tts("Avspilling fullført")

      else

        log_tts("TTS mislyktes, hopper over")

      end

    rescue => e

      log_tts("Feil: #{e.message}")

    end

  end

end

def log_tts(msg)
  File.open(LOG_FILE, 'a') { |f| f.puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}" }

  puts "[TTS] #{msg}"

end

# Malaysiske fraser for TTS
TTS_PHRASES = {

  intro: "Menjana rentak organik dengan rantai sampingan hantu dan bas jitter langsung. Pad bernafas dengan dram melalui hanyutan masa mikro bersama.",

  drums: "Dram kompleksiti maksimum. Tendangan spektrum sembilan jalur, jerat berbutir, lapisan poliritma, pergerakan spatial.",

  pads: "Pad rantai sampingan hantu. Sampul gempa tersegerak dengan jitter rawak. Pad bernafas secara organik di sekeliling pukulan dram.",

  jitter: "Bas jitter langsung diaktifkan. Dram dan pad berkongsi hanyutan masa mikro. Mencipta tolak-tarik seperti persembahan ensembel langsung.",

  tape: "Mod pita organik. Wow, flutter, mendesis, hanyutan stereo, ketepuan lembut.",

  mix: "Campuran tri-selari. Lima belas peratus bersih, enam puluh lima peratus tepu, dua puluh peratus berbutir."

}

def tempfile(prefix = 'tmp')
  "#{CHECKPOINT_DIR}/#{prefix}_#{Time.now.to_i}_#{rand(10000)}.wav"

end

def valid?(f)
  f && File.exist?(f) && File.size(f) > 1000

end

def cleanup
  Dir.glob("#{CHECKPOINT_DIR}/*.wav").each { |f| File.delete(f) rescue nil }

end

def sox(cmd)
  out = tempfile

  system(cmd.gsub('OUT', out).gsub(/[\r\n\t]+/, ' ').strip + " >/dev/null 2>&1")

  valid?(out) ? out : nil

end

def drift_tempo(base_tempo)
  (base_tempo + rand(-3.5..3.5)).clamp(60, 180)

end

def micro_drift
  rand(-0.025..0.025)

end

# === LIVE JITTER-BUSS ===
# Delt tidsdrift som påvirker både trommer og pads

# Skaper "menneskelig ensemble" der elementer skyver/trekker sammen

$jitter_bus = []

def init_jitter_bus(bars)
  $jitter_bus = bars.times.map { rand(-0.008..0.008) }

end

def get_bar_jitter(bar_num)
  $jitter_bus[bar_num] || 0.0

end

NOTES = {
  'C' => 261.63, 'Db' => 277.18, 'D' => 293.66, 'Eb' => 311.13,

  'E' => 329.63, 'F' => 349.23, 'Gb' => 369.99, 'G' => 392.00,

  'Ab' => 415.30, 'A' => 440.00, 'Bb' => 466.16, 'B' => 493.88

}

def parse_chord(name)
  root = name[0] || 'C'

  quality = name[1..-1].downcase

  intervals = case quality
              when 'm9', 'min9' then [0, 3, 7, 10, 14]

              when 'm7', 'min7' then [0, 3, 7, 10]

              when '9' then [0, 4, 7, 10, 14]

              when '7' then [0, 4, 7, 10]

              when 'maj9' then [0, 4, 7, 11, 14]

              when 'maj7' then [0, 4, 7, 11]

              else [0, 4, 7]

              end

  { root: root, intervals: intervals }
end

def chord_freqs(root_freq, intervals)
  intervals.map { |i| root_freq * (2.0 ** (i / 12.0)) }

end

# Spektral kick (9 frekvensbånd: 20Hz-12kHz)
def gen_kick_spectral

  layers = [

    sox("sox -n OUT synth 0.4 sine 30 fade 0 0.4 0.18 vol 0.9"),      # Dyp sub

    sox("sox -n OUT synth 0.35 sine 50 fade 0 0.35 0.15 vol 0.85"),   # Sub

    sox("sox -n OUT synth 0.3 sine 80 fade 0 0.3 0.12 vol 0.75"),     # Kropp

    sox("sox -n OUT synth 0.25 sine 150 fade 0 0.25 0.1 vol 0.65"),   # Lav-mid

    sox("sox -n OUT synth 0.028 sine 280 fade 0 0.028 0.01 vol 0.6"), # Mid punch

    sox("sox -n OUT synth 0.15 noise band 600 200 fade 0 0.15 0.06 vol 0.4"),    # Øvre-mid

    sox("sox -n OUT synth 0.02 sine 1200 fade 0 0.02 0.008 vol 0.5"),            # Klikk

    sox("sox -n OUT synth 0.018 noise band 3500 2000 fade 0 0.018 0.006 vol 0.35"), # Høyt klikk

    sox("sox -n OUT synth 0.015 noise band 9000 3000 fade 0 0.015 0.005 vol 0.2")  # Luft

  ]

  mixed = sox("sox -m #{layers.join(' ')} OUT")
  layers.each { |f| File.delete(f) rescue nil }

  # Tung kompresjon + metning
  kick = sox("sox #{mixed} OUT compand 0.006,0.18 -inf,-60,-50,-40,-30 -7 -90 0.006 overdrive 28 norm -0.15")

  File.delete(mixed) rescue nil

  kick

end

# Granulær snare (kornsky + stotring)
def gen_snare_granular

  body = sox("sox -n OUT synth 0.18 noise band 200 300 fade 0 0.18 0.07 vol 0.65")

  crack = sox("sox -n OUT synth 0.12 noise band 3800 3000 fade 0 0.12 0.05 vol 0.55")

  base = sox("sox -m #{body} #{crack} OUT")
  [body, crack].each { |f| File.delete(f) rescue nil }

  # Generer 20 mikrokorn
  grains = 20.times.map do

    grain_dur = rand(0.008..0.025)

    grain_start = rand(0..0.1)

    sox("sox #{base} OUT trim #{grain_start} #{grain_dur} fade 0 #{grain_dur} #{grain_dur * 0.3}")

  end.compact

  granular = sox("sox #{grains.join(' ')} OUT")
  grains.each { |f| File.delete(f) rescue nil }

  # Bland base + granulær (70/30)
  base_vol = sox("sox #{base} OUT vol 0.7")

  gran_vol = sox("sox #{granular} OUT vol 0.3")

  mixed = sox("sox -m #{base_vol} #{gran_vol} OUT")
  [base, granular, base_vol, gran_vol].each { |f| File.delete(f) rescue nil }

  snare = sox("sox #{mixed} OUT reverb 22 compand 0.01,0.14 -inf,-55,-45,-35 -4 -90 0.01 norm -1.3")
  File.delete(mixed) rescue nil

  snare

end

def spatial_pan(t, bar_num)
  # Sirkulær panorering basert på tid + takt

  angle = (t * 2.0) + (bar_num * 0.5)

  Math.sin(angle).round(2) * 0.7

end

# Maksimal kompleksitet trommer med live jitter-buss
def drums_maximum_complexity(tempo, bars)

  print "  🥁 Trommer... "

  speak(TTS_PHRASES[:drums])

  kick = gen_kick_spectral
  snare = gen_snare_granular

  # 4 hat-variasjoner
  hats = 4.times.map do |i|

    freq = 8000 + (i * 1500)

    sox("sox -n OUT synth #{0.05 + i * 0.03} noise band #{freq} #{3000 + i * 500} fade 0 #{0.05 + i * 0.03} 0.02 vol #{0.2 - i * 0.03} norm -#{8 + i}")

  end

  shaker = sox("sox -n OUT synth 0.04 noise band 10000 7000 fade 0 0.04 0.015 vol 0.15 norm -11")
  rim = sox("sox -n OUT synth 0.045 noise band 3800 2800 fade 0 0.045 0.018 vol 0.2 norm -9")

  bar_files = bars.times.map do |i|
    t_tempo = drift_tempo(tempo)

    beat_dur = 60.0 / t_tempo

    bar_len = beat_dur * 4

    swing = rand(0.54..0.62)

    bar_jitter = get_bar_jitter(i)  # Delt tidsdrift

    hits = []
    # Kicks med delt jitter + mikrodrift
    [0, 1.75, 2.25, 3.5].each do |beat|

      t = beat * beat_dur + bar_jitter + micro_drift

      hits << sox("sox #{kick} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-2.5..1.5)} pan #{spatial_pan(t, i)}")

    end

    # Snares
    [1.0, 3.0].each do |beat|

      t = beat * beat_dur + bar_jitter + micro_drift

      hits << sox("sox #{snare} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-2.5..1.5)} pan #{spatial_pan(t + 0.5, i)}")

    end

    # Ghost snares
    rand(3..5).times do

      t = rand(0..bar_len)

      hits << sox("sox #{snare} OUT pad #{t} 0 trim 0 #{bar_len} gain -#{rand(13..16)} pan #{rand(-0.6..0.6)}")

    end

    # Polyrytmiske hatter (16-deler, 3-over-4, 5-over-4)
    16.times do |j|

      base_t = j * beat_dur * 0.25

      t = base_t + (j.odd? ? swing * beat_dur * 0.05 : 0) + bar_jitter + micro_drift

      hits << sox("sox #{hats[j % 4]} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-15..-8)} pan #{spatial_pan(t, i)}")

    end

    # 3-over-4 lag
    12.times do |j|

      t = j * (bar_len / 12.0) + bar_jitter + micro_drift

      hits << sox("sox #{hats[(j + 1) % 4]} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-18..-12)} pan #{rand(-0.5..0.5)}")

    end

    # Shakers (14-trinns polymetrisk)
    14.times do |j|

      t = j * (bar_len / 14.0) + bar_jitter + micro_drift

      hits << sox("sox #{shaker} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-18..-12)} pan #{spatial_pan(t, i)}")

    end

    # Rims
    rand(3..6).times do

      t = rand(0..bar_len)

      hits << sox("sox #{rim} OUT pad #{t} 0 trim 0 #{bar_len} gain #{rand(-12..-7)} pan #{spatial_pan(t, i)}")

    end

    bar = sox("sox -m #{hits.compact.join(' ')} OUT")
    hits.each { |f| File.delete(f) rescue nil }

    bar

  end.compact

  base = sox("sox #{bar_files.join(' ')} OUT")
  bar_files.each { |f| File.delete(f) rescue nil }

  # Ekstrem prosessering: bitcrusher + metning
  output = sox("sox #{base} OUT compand 0.012,0.28 -inf,-38,-18,-10 -6 -90 0.012 overdrive 15 rate -s 19000 rate -s 48k equalizer 55 0.7q +5 lowpass 6000 norm -0.6")

  File.delete(base) rescue nil

  [kick, snare, *hats, shaker, rim].each { |f| File.delete(f) rescue nil }
  puts valid?(output) ? "✓" : "✗"
  output

end

# To-lags bass med rørmetting
def bass(freqs, dur)

  print "  🎸 Bass... "

  notes = freqs.map do |f|
    sub = sox("sox -n OUT synth #{dur} sine #{f / 2} fade h 0.05 #{dur} 0.1 vol 0.85")

    mid = sox("sox -n OUT synth #{dur} square #{f} fade h 0.05 #{dur} 0.1 vol 0.48")

    note = sox("sox -m #{sub} #{mid} OUT")

    [sub, mid].each { |file| File.delete(file) rescue nil }

    note

  end.compact

  base = sox("sox #{notes.join(' ')} OUT lowpass 145 equalizer 72 1q +4")
  notes.each { |f| File.delete(f) rescue nil }

  output = sox("sox #{base} OUT overdrive 24 norm -2.3")
  File.delete(base) rescue nil

  puts valid?(output) ? "✓" : "✗"
  output

end

# === SPØKELSE SIDECHAIN KONVOLUTT ===
# Temposynkronisert tremolo-konvolutt med tilfeldig jitter

def ghost_envelope(tempo, bars, depth = 30)

  dur = (60.0 / tempo) * 4 * bars

  beat = 60.0 / tempo

  out = tempfile('ghost_env')

  base_rate = 1.0 / beat
  jitter = rand(0.05..0.12)

  smoothness = rand(0.6..0.9)

  system("sox -n #{out} synth #{dur} sine #{base_rate + jitter} vol #{depth / 100.0} fade 0.1 #{dur} 0.1 tremolo #{base_rate * 4} #{depth * smoothness} >/dev/null 2>&1")
  valid?(out) ? out : nil

end

# Enkelt akkordlag med detuning og tremolo
def pad_chord(freqs, dur)

  layers = freqs.map.with_index do |f, i|

    detune = f * rand(0.995..1.005)

    pan = i.even? ? "-0.2" : "0.2"

    # Bland flere bølgeformer
    sine = sox("sox -n OUT synth #{dur} sine #{detune} vol 0.4")

    tri = sox("sox -n OUT synth #{dur} triangle #{detune * 2} vol 0.25")

    saw = sox("sox -n OUT synth #{dur} sawtooth #{detune * 0.999} vol 0.25")

    base = sox("sox -m #{sine} #{tri} #{saw} OUT tremolo #{rand(0.1..0.25)} #{rand(15..25)} pan #{pan}")
    [sine, tri, saw].each { |f| File.delete(f) rescue nil }

    base

  end.compact

  chord = sox("sox -m #{layers.join(' ')} OUT reverb 85 chorus 0.6 0.9 55 0.25 0.3 2 -t lowpass 7500 norm -6")
  layers.each { |f| File.delete(f) rescue nil }

  chord

end

# Frodige pads med spøkelse sidechain
def pads_ghost_sidechain(chord_names, dur, tempo, bars)

  print "  🎹 Pads... "

  speak(TTS_PHRASES[:pads])

  # Generer akkorder
  chords = chord_names.map do |name|

    parsed = parse_chord(name)

    root = NOTES[parsed[:root]] || 261.63

    freqs = chord_freqs(root, parsed[:intervals])

    pad_chord(freqs, dur)

  end.compact

  pad_mix = sox("sox #{chords.join(' ')} OUT overdrive 8 lowpass 7500 norm -5")
  chords.each { |f| File.delete(f) rescue nil }

  # Generer spøkelseskonvolutt og anvend
  env = ghost_envelope(tempo, bars, 30)

  side = sox("sox #{pad_mix} OUT tremolo #{1.0 / (60.0 / tempo)} 30")

  # Bland ren + sidechained (50/50)
  clean_vol = sox("sox #{pad_mix} OUT vol 0.5")

  side_vol = sox("sox #{side} OUT vol 0.5")

  mixed = sox("sox -m #{clean_vol} #{side_vol} OUT")
  [env, side, clean_vol, side_vol].each { |f| File.delete(f) rescue nil }

  # Frodige effekter
  output = sox("sox #{mixed} OUT norm -4 reverb 60 chorus 0.6 0.9 50 0.3 0.4 2 -t")

  [pad_mix, mixed].each { |f| File.delete(f) rescue nil }

  puts valid?(output) ? "✓" : "✗"
  output

end

# Organisk bånd-modus (wow, flutter, sus, stereodrift)
def tape_mode(input)

  print "  📼 Bånd... "

  speak(TTS_PHRASES[:tape])

  dur = `soxi -D "#{input}" 2>/dev/null`.to_f rescue 20.0
  # Wow & flutter (langsom + rask pitchmodulasjon)
  modulated = sox("sox #{input} OUT tremolo #{rand(0.18..0.28)} #{rand(0.35..0.6)} tremolo #{rand(5.0..7.0)} #{rand(0.05..0.1)}")

  # Myk metning + filtrering
  warm = sox("sox #{modulated} OUT overdrive 4 bass +1 treble -3 lowpass 7500 highpass 40")

  File.delete(modulated) rescue nil

  # Bånd-sus
  hiss = sox("sox -n OUT synth #{dur} noise vol #{rand(-38..-32)}dB")

  mixed = sox("sox -m #{warm} #{hiss} OUT norm -3")

  [warm, hiss].each { |f| File.delete(f) rescue nil }

  # Stereodrift (chorus)
  output = sox("sox #{mixed} OUT chorus 0.6 0.8 55 #{rand(0.2..0.35)} 0.25 2 -t")

  File.delete(mixed) rescue nil

  puts valid?(output) ? "✓" : "✗"
  output

end

# Tri-parallell miksing (ren + mettet + granulær)
def mix(drums, bass, pads)

  print "  🎚️  Miks... "

  speak(TTS_PHRASES[:mix])

  d = sox("sox #{drums} OUT norm -0.4")
  b = sox("sox #{bass} OUT norm -2.3")

  p = sox("sox #{pads} OUT norm -6")

  # Tre parallelle baner
  clean = sox("sox -m #{d} #{b} #{p} OUT vol 0.15")        # 15% ren

  saturated = sox("sox -m #{d} #{b} #{p} OUT overdrive 25 vol 0.65")  # 65% mettet

  granular = sox("sox -m #{d} #{b} #{p} OUT rate -s 16000 rate -s 48k overdrive 18 vol 0.2")  # 20% bitcrushed

  mixed = sox("sox -m #{clean} #{saturated} #{granular} OUT")
  [d, b, p, clean, saturated, granular].each { |f| File.delete(f) rescue nil }

  output = sox("sox #{mixed} OUT norm -0.7")
  File.delete(mixed) rescue nil

  puts valid?(output) ? "✓" : "✗"
  output

end

MODES = {
  modal_ref: { name: 'Modal Jazz Referanse', tempo: 90, dur: 4, chords: ['Cm9', 'Dm7', 'G7', 'F7'] },

  experimental: { name: 'Maksimal Kompleksitet', tempo: 145, dur: 3.5, chords: ['Ebm9', 'Gbmaj9', 'Abm9', 'Dbmaj7'] }

}

def generate(mode_key = :modal_ref, bars = 8)
  speak(TTS_PHRASES[:intro])

  mode = MODES[mode_key]

  puts "\n🎵 #{mode[:name]} (#{mode[:tempo]} BPM, #{bars} takter)"

  puts "   Spøkelse sidechain + live jitter-buss\n"

  # Initialiser live jitter-buss
  init_jitter_bus(bars)

  speak(TTS_PHRASES[:jitter])

  # Generer trommer
  d = drums_maximum_complexity(mode[:tempo], bars)

  return nil unless d

  # Generer pads
  chord_sequence = (mode[:chords] * ((bars / mode[:chords].size) + 1)).take(bars)

  p = pads_ghost_sidechain(chord_sequence, mode[:dur], mode[:tempo], bars)

  return nil unless p

  # Generer bass
  roots = mode[:chords].map { |c| NOTES[parse_chord(c)[:root]] || 261.63 }

  b = bass(roots * 2, mode[:dur])

  return nil unless b

  # Miks alt
  m = mix(d, b, p)

  return nil unless m

  # Anvend organisk bånd-modus
  output = tape_mode(m)

  [d, b, p, m].each { |f| File.delete(f) rescue nil }

  output
end

if __FILE__ == $0
  abort "❌ SoX er ikke installert" unless system("sox --version >/dev/null 2>&1")

  Signal.trap("INT") { cleanup; puts "\n✅ Stoppet"; exit 0 }

  puts "🎧 Organisk Rytmegenerator v60.10 - MALAYSISK STEMME + NORSKE KOMMENTARER ✅"
  puts "✅ Dyp malaysisk stemme (-12.5 halvtoner)"

  puts "✅ Spøkelse sidechain (temposynkronisert tremolo med jitter)"

  puts "✅ Live jitter-buss (delt mikro-tidsdrift)"

  puts "✅ Pads puster organisk med trommer"

  puts "✅ Menneskelig ensemble-følelse (skyv-trekk-timing)"

  puts "✅ Organisk bånd-modus (wow, flutter, sus)"

  puts "✅ 9-bånd spektrale kicks + granulære snares"

  puts "✅ Tri-parallell miks (ren, mettet, granulær)\n"

  puts "TTS-logg: #{LOG_FILE}\n"

  mode = (ARGV[0]&.to_sym && MODES.key?(ARGV[0].to_sym)) ? ARGV[0].to_sym : :modal_ref
  output = generate(mode, 8)
  if output
    final = "organisk_rytme_v60.10_#{mode}_#{Time.now.strftime('%H%M%S')}.wav"

    FileUtils.cp(output, final)

    File.delete(output) rescue nil

    size = (File.size(final) / 1024.0 / 1024.0).round(2)
    puts "\n✅ #{final} (#{size} MB)"
    puts "▶️  Spiller av spøkelse sidechain + live jitter..."

    win = `cygpath -w "#{final}" 2>/dev/null`.chomp
    system("cmd.exe /c start wmplayer \"#{win.empty? ? final : win}\" 2>/dev/null")

  end

  cleanup
end

