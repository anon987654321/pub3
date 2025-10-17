#!/usr/bin/bash
# Continuous Dilla Chord Progression Playback
# Loops all chord progressions to local soundcard

SOX="G:/pub/multimedia/dilla/effects/sox/sox.exe"
CHORDS_DIR="G:/pub/multimedia/dilla/chords"

# Concatenate all chord progressions
CHORD_FILES=(
  "${CHORDS_DIR}/blade_runner_dystopia.wav"
  "${CHORDS_DIR}/midnight_ritual.wav"
  "${CHORDS_DIR}/donuts_redux.wav"
  "${CHORDS_DIR}/organic_dilla.wav"
  "${CHORDS_DIR}/vienna_strings.wav"
  "${CHORDS_DIR}/industrial_techno_dilla.wav"
)

# Check if files exist
for file in "${CHORD_FILES[@]}"; do
  [[ -f "$file" ]] || { echo "Missing: $file"; exit 1; }
done

echo "Playing Dilla chords continuously to soundcard..."
echo "Press Ctrl+C to stop"
echo ""

# Play in infinite loop using SoX's repeat function
# -d = default audio device (soundcard)
"$SOX" "${CHORD_FILES[@]}" -d repeat 999
