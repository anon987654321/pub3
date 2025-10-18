#!/usr/bin/bash
# Generate single chord WAV and play using winsound or mplay32

SOX="G:/pub/multimedia/dilla/effects/sox/sox.exe"
OUT="G:/pub/multimedia/dilla/temp_chord.wav"

echo "Generating J Dilla Dm9 chord progression..."

# Generate Dm9 chord to file with stereo output
"$SOX" -n -r 44100 -c 2 "$OUT" synth 2.0 \
  sine 146.83 sine 174.61 sine 220.00 sine 261.63 sine 329.63 \
  channels 2 gain -12 norm -3

echo "Generated: $OUT"

# Try to play with Windows Media Player command line
if [[ -f "$OUT" ]]; then
  echo "Playing with mplay32..."
  /cygdrive/c/Windows/System32/mplay32.exe /play /close "$OUT" &
  sleep 3

  echo "Looping..."
  while true; do
    /cygdrive/c/Windows/System32/mplay32.exe /play /close "$OUT" &
    sleep 2.5
  done
fi
