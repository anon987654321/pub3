#!/usr/bin/env ruby
# Bomoh Hang Tuah voice - Mystical kampong shaman per master.json v337.3.0
# Pure Ruby Google TTS (quality voices) - no Python, no SAPI, no espeak

require_relative 'gtts_ruby'

text = ARGV.join(" ")

unless text.empty?
  # Bomoh Hang Tuah: Indian English accent (co.in), deep pitch (-150)
  GoogleTTS.speak(text, lang: 'en', tld: 'co.in', pitch_adjust: 0)
end

