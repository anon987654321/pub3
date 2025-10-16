#!/usr/bin/env zsh
# Continuous 8-layer drone for warp tunnel experimentation
# Generated with Claude Code

SOX="G:/pub/dilla/effects/sox/sox.exe"
OUT_DIR="G:/pub/dilla/drones"
mkdir -p "$OUT_DIR"

# Duration: infinite loop (use Ctrl+C to stop)
# Each layer targets specific frequency band for visualizer

echo "🎛️  Generating continuous 8-layer drone..."
echo "   Sub-bass, Bass, Low-mid, Mid, High-mid, High, Treble, Air"
echo ""

# Layer 1: Sub-bass (20-60Hz) - deep rumble for ring expansion
echo "🔊 Layer 1: Sub-bass (20-60Hz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer1_subbass.wav" \
  synth 300 sine 40 sine 48 \
  tremolo 0.13 12 \
  gain -18

# Layer 2: Bass (60-250Hz) - warmth for z-depth modulation
echo "🔊 Layer 2: Bass (60-250Hz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer2_bass.wav" \
  synth 300 sine 110 sine 165 sine 220 \
  tremolo 0.08 7 \
  gain -14

# Layer 3: Low-mid (250-500Hz) - body
echo "🔊 Layer 3: Low-mid (250-500Hz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer3_lowmid.wav" \
  synth 300 sine 330 sine 440 \
  tremolo 0.05 4 \
  gain -16

# Layer 4: Mid (500-2kHz) - presence for rotation speed
echo "🔊 Layer 4: Mid (500-2kHz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer4_mid.wav" \
  synth 300 sine 880 sine 1320 \
  tremolo 0.11 5 \
  gain -17

# Layer 5: High-mid (2k-4kHz) - clarity
echo "🔊 Layer 5: High-mid (2k-4kHz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer5_highmid.wav" \
  synth 300 sine 2640 sine 3520 \
  tremolo 0.07 8 \
  gain -19

# Layer 6: High (4k-8kHz) - brightness for color saturation
echo "🔊 Layer 6: High (4k-8kHz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer6_high.wav" \
  synth 300 sine 5280 sine 6600 \
  tremolo 0.09 11 \
  gain -20

# Layer 7: Treble (8k-12kHz) - air
echo "🔊 Layer 7: Treble (8k-12kHz)"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer7_treble.wav" \
  synth 300 sine 9240 sine 11000 \
  tremolo 0.14 6 \
  gain -22

# Layer 8: Air (12k+) - shimmer with noise for grain
echo "🔊 Layer 8: Air (12k+) + Noise"
"$SOX" -n -r 48000 -c 2 "${OUT_DIR}/layer8_air.wav" \
  synth 300 sine 13200 pinknoise \
  highpass 10000 \
  tremolo 0.06 3 \
  gain -24

echo ""
echo "🎚️  Mixing layers..."

# Mix all layers
"$SOX" -m \
  "${OUT_DIR}/layer1_subbass.wav" \
  "${OUT_DIR}/layer2_bass.wav" \
  "${OUT_DIR}/layer3_lowmid.wav" \
  "${OUT_DIR}/layer4_mid.wav" \
  "${OUT_DIR}/layer5_highmid.wav" \
  "${OUT_DIR}/layer6_high.wav" \
  "${OUT_DIR}/layer7_treble.wav" \
  "${OUT_DIR}/layer8_air.wav" \
  "${OUT_DIR}/drone_raw.wav"

echo "✨ Applying spatial effects..."

# Add subtle chorus for width
"$SOX" "${OUT_DIR}/drone_raw.wav" "${OUT_DIR}/drone_chorus.wav" \
  chorus 0.6 0.9 55 0.4 0.25 2 -t 60 0.32 0.4 1.3 -s

# Add reverb for depth
"$SOX" "${OUT_DIR}/drone_chorus.wav" "${OUT_DIR}/drone_verb.wav" \
  reverb 60 50 100 100 0 5

# Normalize and compress
"$SOX" "${OUT_DIR}/drone_verb.wav" "${OUT_DIR}/drone_final.wav" \
  compand 0.1,0.3 -60,-40,-10 5 -5 0.1 \
  gain -n -3

echo ""
echo "✓ Drone generated: ${OUT_DIR}/drone_final.wav"
echo ""
echo "🎧 Play infinite loop:"
echo "   ${SOX} ${OUT_DIR}/drone_final.wav -d repeat 999"
echo ""
echo "🎛️  Experiment:"
echo "   1. Play drone in background"
echo "   2. Open index.html warp tunnel"
echo "   3. Adjust visualizer intensity with [ ]"
echo "   4. Try different visualizers with V key"
echo "   5. Watch how each frequency band affects motion"
echo ""
echo "📊 Frequency map:"
echo "   20-60Hz   → Ring expansion (sub-bass)"
echo "   60-250Hz  → Z-depth pulse (bass)"
echo "   250-2kHz  → Rotation speed (mid)"
echo "   2k-8kHz   → Color saturation (high)"
echo "   8kHz+     → Grain/shimmer (treble)"
