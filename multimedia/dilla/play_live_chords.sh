#!/usr/bin/bash
# Live J Dilla chord generation and playback via SoX
# Generates chords on-the-fly and plays continuously

SOX="G:/pub/multimedia/dilla/effects/sox/sox.exe"

echo "Generating and playing J Dilla chords live..."
echo "Press Ctrl+C to stop"
echo ""

# Dm9 progression (Life by J Dilla)
while true; do
  echo "Playing: Dm9 -> F9 -> Bbmaj7 -> C9"

  # Generate and play Dm9 (146.83 174.61 220.00 261.63 329.63)
  "$SOX" -n -p synth 2.0 sine 146.83 sine 174.61 sine 220.00 sine 261.63 sine 329.63 \
    gain -18 reverb 30 50 85 compand 0.1,0.3 -inf,-70,-55,-20 -6 -90 0.15 norm -2 | \
  "$SOX" -p -d

  # Generate and play F9
  "$SOX" -n -p synth 2.0 sine 174.61 sine 220.00 sine 261.63 sine 329.63 sine 392.00 \
    gain -18 reverb 30 50 85 compand 0.1,0.3 -inf,-70,-55,-20 -6 -90 0.15 norm -2 | \
  "$SOX" -p -d

  # Generate and play Bbmaj7
  "$SOX" -n -p synth 2.0 sine 116.54 sine 174.61 sine 220.00 sine 261.63 \
    gain -18 reverb 30 50 85 compand 0.1,0.3 -inf,-70,-55,-20 -6 -90 0.15 norm -2 | \
  "$SOX" -p -d

  # Generate and play C9
  "$SOX" -n -p synth 2.0 sine 130.81 sine 164.81 sine 196.00 sine 246.94 sine 329.63 \
    gain -18 reverb 30 50 85 compand 0.1,0.3 -inf,-70,-55,-20 -6 -90 0.15 norm -2 | \
  "$SOX" -p -d
done
