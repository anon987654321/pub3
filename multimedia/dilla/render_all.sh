#!/usr/bin/env zsh
# Full render with maximum variety

# Runs chords, drums, then creates varied final mixes

set -e
echo "======================================================================"
echo "J DILLA AUDIO GENERATOR - FULL RENDER WITH VARIETY"

echo "======================================================================"

# Clean old outputs
rm -rf chords bass drums final

mkdir -p chords bass drums final

# Step 1: Render all chord progressions (uses chord_theory_expanded.json)
echo

echo "📊 STEP 1: RENDERING CHORD PROGRESSIONS + BASS"

echo "----------------------------------------------------------------------"

/usr/bin/ruby pads.rb

# Step 2: Render all drum patterns
echo

echo "📊 STEP 2: RENDERING INTRICATE DRUMS"

echo "----------------------------------------------------------------------"

/usr/bin/ruby drums_fixed.rb

# Step 3: Create varied final mixes (rotates through all drums)
echo

echo "📊 STEP 3: CREATING FINAL MIXES (ROTATING DRUMS FOR VARIETY)"

echo "----------------------------------------------------------------------"

# Get all drum files
DRUM_FILES=(drums/*.wav(N))

DRUM_COUNT=${#DRUM_FILES}

if [[ $DRUM_COUNT -eq 0 ]]; then
  echo "⚠ No drum files found - skipping final mixes"

  exit 1

fi

echo "   Using $DRUM_COUNT drum patterns in rotation"
# Rotate through drums for each chord progression
DRUM_INDEX=0

for CHORD_FILE in chords/*.wav(N); do

  PROG_NAME=$(basename "$CHORD_FILE" .wav)

  DRUM_FILE=${DRUM_FILES[$(( ($DRUM_INDEX % $DRUM_COUNT) + 1 ))]}

  DRUM_NAME=$(basename "$DRUM_FILE" .wav | sed 's/_intricate//')

  BASS_FILE="bass/${PROG_NAME}.wav"
  if [[ -f "$CHORD_FILE" && -f "$BASS_FILE" && -f "$DRUM_FILE" ]]; then
    # Get chord duration for looping drums

    CHORD_DUR=$(G:/pub/dilla/effects/sox/sox.exe --info -D "$CHORD_FILE")

    DRUM_DUR=$(G:/pub/dilla/effects/sox/sox.exe --info -D "$DRUM_FILE")

    DRUM_REPEATS=$(( int(${CHORD_DUR} / ${DRUM_DUR}) + 2 ))

    # Loop drums to match chord length
    G:/pub/dilla/effects/sox/sox.exe "${(@)${(s: :)$(printf '%s ' "${(r:${DRUM_REPEATS}::${DRUM_FILE}:}")}" }}" _drums_loop.wav trim 0 ${CHORD_DUR}

    # Final mix with mastering
    G:/pub/dilla/effects/sox/sox.exe -m "$CHORD_FILE" "$BASS_FILE" _drums_loop.wav "final/${PROG_NAME}_${DRUM_NAME}.wav" \

      gain -n -2 \

      compand 0.02,0.20 -60,-60,-30,-24,-20,-18,-4,-12,-2,-9,0,-6 -6 0 0.05 \

      overdrive 5 \

      reverb 18 10 \

      equalizer 80 0.5q +2 \

      equalizer 3000 1.2q +1.5 \

      equalizer 10000 0.6q +1.5 \

      gain -n -0.5

    rm -f _drums_loop.wav
    echo "✓ final/${PROG_NAME}_${DRUM_NAME}.wav"

  fi

  DRUM_INDEX=$(( $DRUM_INDEX + 1 ))
done

echo
echo "======================================================================"

echo "✅ RENDER COMPLETE"

echo "======================================================================"

echo

echo "📁 Outputs:"

echo "  chords/ - $(ls chords/*.wav 2>/dev/null | wc -l) files"

echo "  bass/   - $(ls bass/*.wav 2>/dev/null | wc -l) files"

echo "  drums/  - $(ls drums/*.wav 2>/dev/null | wc -l) files"

echo "  final/  - $(ls final/*.wav 2>/dev/null | wc -l) files"

echo

