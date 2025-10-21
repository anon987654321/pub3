#!/usr/bin/env ruby
# frozen_string_literal: true
# TTS - Text-to-Speech with Malaysian Voice
# Version: 3.0.0 - Consolidated (zero sprawl per master.json)
#
# Usage:
#   ruby tts.rb "Hello world"           # Speak text (deep Malay voice)
#   ruby tts.rb --interactive           # Interactive mode
#   ruby tts.rb --test                  # Test voice

require "net/http"
require "uri"
require "cgi"
require "fileutils"

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = "G:/pub/multimedia/tts"
CACHE_DIR = "#{BASE_DIR}/cache"
SOX = "G:/pub/multimedia/dilla/effects/sox/sox.exe"

FileUtils.mkdir_p(CACHE_DIR)

# Voice profiles
VOICES = {
  malay_deep: {
    lang: "ms",           # Malaysian
    tld: "com.my",        # .my TLD for Malaysian accent
    pitch: -12.5,         # Deep voice (-12.5 semitones)
    bass: 8,              # Bass boost
    treble: -2,           # Treble reduction for warmth
    reverb: 20,           # Room reverb
    name: "Deep Soothing Malaysian"
  },
  malay_normal: {
    lang: "ms",
    tld: "com.my",
    pitch: 0,
    bass: 0,
    treble: 0,
    reverb: 10,
    name: "Natural Malaysian"
  },
  english_deep: {
    lang: "en",
    tld: "com",
    pitch: -10,
    bass: 6,
    treble: -1,
    reverb: 15,
    name: "Deep English"
  }
}.freeze

DEFAULT_VOICE = :malay_deep

# ============================================================================
# CORE TTS ENGINE
# ============================================================================

def fetch_tts(text, voice = DEFAULT_VOICE)
  config = VOICES[voice]
  hash = "#{text}#{config[:lang]}#{config[:tld]}".hash.abs.to_s
  mp3 = "#{CACHE_DIR}/#{hash}.mp3"
  return mp3 if File.exist?(mp3)

  url = "https://translate.google.com/translate_tts?" \
        "ie=UTF-8&client=tw-ob&tl=#{config[:lang]}&ttsspeed=0.85&tld=#{config[:tld]}&q=#{CGI.escape(text)}"

  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    req["Referer"] = "https://translate.google.com/"

    res = http.request(req)
    if res.code == "200" && res.body.size > 1000
      File.binwrite(mp3, res.body)
      return mp3
    else
      warn "❌ TTS API error: #{res.code}"
      return nil
    end
  end
rescue => e
  warn "❌ Network error: #{e.message}"
  nil
end

def apply_effects(mp3, voice = DEFAULT_VOICE)
  # SoX in Cygwin lacks libmad for MP3 decoding
  # Skip effects and use MP3 directly
  # TODO: Install libmad or use ffmpeg to convert MP3→WAV→process→WAV
  mp3
end

def play(file)
  return unless File.exist?(file)

  # Convert to Windows path
  win_path = file.sub('G:/', 'G:\\').gsub('/', '\\')

  if file.end_with?(".wav")
    # WAV: Direct soundcard playback via SoX
    system(%Q("#{SOX}" "#{file}" -t waveaudio -d 2>/dev/null))
  else
    # MP3: Use cmd.exe with start (most reliable on Windows)
    system(%Q(cmd.exe /c start /min "" "#{win_path}" 2>/dev/null))
    sleep((File.size(file) / 8000.0).ceil)
  end
end

def speak(text, voice: DEFAULT_VOICE, effects: true)
  return false if text.nil? || text.empty?

  mp3 = fetch_tts(text, voice)
  return false unless mp3

  audio = effects ? apply_effects(mp3, voice) : mp3
  play(audio)
  true
end

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

def show_menu
  puts "\n" + "=" * 60
  puts "🎤 TTS - Text-to-Speech (Malaysian Voice)"
  puts "=" * 60
  puts
  puts "Current voice: #{VOICES[DEFAULT_VOICE][:name]}"
  puts
  puts "1. Speak Text"
  puts "2. Test Voice"
  puts "3. List Voices"
  puts "4. Clear Cache"
  puts "5. Exit"
  puts
  print "Choose [1-5]: "
  gets.chomp
end

def test_voice(voice = DEFAULT_VOICE)
  config = VOICES[voice]
  puts "\n🎤 Testing: #{config[:name]}"
  puts "   Language: #{config[:lang]}"
  puts "   Pitch: #{config[:pitch]} semitones"
  puts "   Bass: +#{config[:bass]} dB"

  if config[:lang] == "ms"
    speak("Selamat datang. Ini adalah suara Malaysia yang dalam dan menenangkan.", voice: voice)
  else
    speak("Welcome. This is a deep and soothing voice.", voice: voice)
  end
end

def list_voices
  puts "\n📋 Available Voices:"
  puts "-" * 60
  VOICES.each do |key, config|
    current = key == DEFAULT_VOICE ? " (current)" : ""
    puts "  #{key}#{current}"
    puts "    #{config[:name]} (#{config[:lang]})"
    puts "    Pitch: #{config[:pitch]}, Bass: +#{config[:bass]}"
    puts
  end
end

def clear_cache
  count = Dir["#{CACHE_DIR}/*"].size
  FileUtils.rm_rf(CACHE_DIR)
  FileUtils.mkdir_p(CACHE_DIR)
  puts "\n✓ Cleared #{count} cached files"
end

def interactive_mode
  loop do
    choice = show_menu

    case choice
    when "1"
      print "\nText to speak: "
      text = gets.chomp
      speak(text) unless text.empty?

    when "2"
      test_voice

    when "3"
      list_voices

    when "4"
      clear_cache

    when "5", "q", "quit", "exit"
      puts "\n👋 Goodbye!"
      exit 0

    else
      puts "\n⚠️  Invalid choice"
    end
  end
end

# ============================================================================
# CLI
# ============================================================================

if __FILE__ == $PROGRAM_NAME
  case ARGV[0]
  when "--interactive", "-i"
    interactive_mode

  when "--test", "-t"
    voice = ARGV[1]&.to_sym || DEFAULT_VOICE
    test_voice(voice)

  when "--voices", "-v"
    list_voices

  when "--clear-cache"
    clear_cache

  when "--help", "-h"
    puts <<~HELP
      TTS - Text-to-Speech with Malaysian Voice

      Usage:
        ruby tts.rb "text to speak"    # Speak with default voice
        ruby tts.rb --interactive      # Interactive mode
        ruby tts.rb --test             # Test voice
        ruby tts.rb --voices           # List all voices
        ruby tts.rb --clear-cache      # Clear audio cache

      Voices:
        #{VOICES.keys.join(', ')}

      Default: #{DEFAULT_VOICE} (#{VOICES[DEFAULT_VOICE][:name]})
    HELP

  when nil
    puts "❌ No text provided. Use --help for usage."

  else
    text = ARGV.join(" ")
    speak(text)
  end
end
