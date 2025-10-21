#!/data/data/com.termux/files/usr/bin/bash
# Background TTS Service
# Keeps talking even when you leave Termux

echo "🔊 Starting background talking service..."
# Start in background with nohup
nohup ruby ~/natural_talk.rb > ~/tts_background.log 2>&1 &

# Save PID
echo $! > ~/tts_service.pid

echo "✅ Background service started! PID: $(cat ~/tts_service.pid)"
echo "📝 Logs: ~/tts_background.log"

echo ""

echo "To stop: kill \$(cat ~/tts_service.pid)"

echo "Or run: ~/stop_talk.sh"

