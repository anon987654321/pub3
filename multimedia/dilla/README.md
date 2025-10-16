# J Dilla Music Generation
**Pure Ruby + SoX synthesis** - No DAWs, no plugins. Generates J Dilla-style chord progressions, Berlin techno drums, and surreal atmospheric mixes with music theory analysis.
## Quick Start (Cygwin)
```bash
cd /g/pub/dilla

# 1. Generate Dilla chords with theory analysis
ruby chords.rb                           # SoX synthesis (default)

ruby chords_compare.rb --engine=both     # A/B test SoX vs FluidSynth

# 2. Generate Berlin techno drums (proper GoldBaby 808 integration)
ruby drums.rb

# 3. Create ultimate mix with surreal atmospheric effects
ruby mix.rb          # Single ethereal mix

ruby mix.rb all      # All 5 atmospheric variations

```

## Dual Audio Engine System (NEW!)
Choose between two audio generation methods:
### **SoX Synthesis** (Default - No Build Required)
- Pure Ruby waveform synthesis (sawtooth, square, sine)

- 5 custom instruments: Rhodes, Wurlitzer, Dark Piano, Organ, Analog Pad

- Vintage analog character with microtonality

- Perfect for lofi/experimental/Flying Lotus aesthetics

- **Command**: `ruby chords.rb`

### **FluidSynth + Soundfonts** (Professional Quality)
- Real sampled instruments via SoundFont 2/3 files

- Multi-velocity layers for realistic dynamics

- 3-5 velocity layers per note

- Professional timbres (Rhodes MKII, Hammond B3, etc.)

- **Command**: `ruby chords_compare.rb --engine=fluidsynth`

### **A/B Comparison Mode**
Generate both versions side-by-side to choose your preferred sound:

```bash

ruby chords_compare.rb --engine=both

# Creates: chords.wav (SoX) + chords_fluidsynth.wav (FluidSynth)

# Listen to both and decide which fits your aesthetic

```

**When to use each:**
- **SoX**: Lofi, vintage warmth, J Dilla "imperfections", experimental

- **FluidSynth**: Jazz, neo-soul, polished productions, realistic instruments

- **Both**: A/B test to find the sweet spot for your track

## Output
**chords.rb** creates:
- 16 individual progressions (Ahmad Jamal, Isley Brothers, Ethiojazz)

- `chords.wav` (all concatenated)

- Music theory analysis (modal classification, voice leading scores, tension curves)

- **FIXED**: No clipping warnings - proper gain staging with normalization

**drums.rb** creates:
- 5 Berlin techno patterns (8-16 bars, proper club length)

- `drums.wav` (all concatenated)

- **NEW**: Proper GoldBaby ROM808 sample selection + kick tuning

- Styles: Berlin Minimal, Deep Hypnotic, Acid 303, Industrial Hard, Ambient Drift

**mix.rb** creates:
- `ultimate.wav` - Combined chords + drums + surreal atmospheric pad

- **5 atmospheric styles**: ethereal, cosmic, dreamy, dark_ambient, vocal_lush

- **NEW vocal_lush**: Alternating vocal harmonies (ooh/aah) and lush synth pads every 8 seconds

- Spatial effects: huge reverb, dual echo, phasing, tremolo

## Features
### Chord Theory Analysis
- **Modal classification**: Dorian, Phrygian, Lydian detection

- **Voice leading quality**: Smoothness scoring (0-10)

- **Tension curves**: Harmonic tension over time

- **Uniqueness scoring**: Composite metric (modal rarity + voice leading + tension dynamics)

**What makes a timeless progression?**
1. **Uncommon modes** (30% weight): Dorian (7/10), Phrygian (8/10) > Ionian (3/10)

2. **Smooth voice leading** (30% weight): <3 semitone movement between chords

3. **Tension dynamics** (40% weight): Strong arc (low → high → low)

### J Dilla Techniques
- **Golden ratio swing**: 54.2% offbeat timing

- **Microtonality**: ±0.5% frequency detuning for analog warmth

- **Voice dynamics**: Bass (-14dB), melody (-12dB), inner voices (-17dB)

- **3-layer synthesis**: Sawtooth + square + sine per voice

- **FX chains**: warm_tape, lofi_dream, dilla_butter, analog_lush

### Berlin Techno Drums (FIXED)
- **Berghain sound**: Proper club-ready techno (8-16 bar patterns, not 32s)

- **Kick tuning**: Pitch shifting (-7st to +2st) for proper sub bass

- **808 sample selection**: Best GoldBaby ROM808 samples per style

- **303 acid bass**: TB-303 emulation with filter sweep + resonance

- **Atmosphere layers**: Style-specific (deep/acidic/minimal/industrial/ambient)

- **Proper mastering**: No clipping, compression→EQ→normalize chain

### Surreal Atmospheric Mixing (NEW)
- **5 pad styles**: Ethereal (sine harmonies), Cosmic (sawtooth flanger), Dreamy (triangle chorus), Dark Ambient (brown noise + drone), Vocal/Lush (alternating)

- **Vocal/Lush alternating**: "Singers Unlimited" style vocal harmonies (ooh/aah formant synthesis) alternating with lush detuned synth pads every 8 seconds

- **Formant synthesis**: Authentic vowel sounds using bandpass filters at vocal formant frequencies (300Hz, 870Hz, 2240Hz for "ooh"; 700Hz, 1220Hz, 2600Hz for "aah")

- **Lush pads**: 6 detuned sawtooth oscillators with double chorus for extreme thickness

- **Spatial processing**: 95% reverb, dual echo (400ms + 800ms), phasing, tremolo

- **Intelligent mixing**: Chords (60%) + Drums (50%) + Pad (25%) with proper gain staging

- **Beautiful effects**: Creates deep, hypnotic, surreal soundscapes

## Requirements
- **Ruby**: 3.2.2+ (Cygwin)
- **SoX**: effects/sox/sox.exe (included)

- **FluidSynth**: instruments/fluidsynth/ (source included - build with cmake)

- **Soundfonts**: instruments/soundfonts/ (5 professional soundfonts included)

  - FluidR3_GM.sf2 (3.3MB) - General MIDI standard

  - MuseScore_General.sf3 (9.3MB) - High-quality compressed soundfont

  - VintageDreamsWaves-v2.sf2/sf3 - Vintage analog emulation

- **Optional**: GoldBaby ROM808 samples at `/g/music/samples/drums/goldbaby/rom808/`

## Theory Scoring Example
```
Ethiojazz Nights:

  Uniqueness: 8.5/10

  Mode: phrygian (85.0% confidence)

  Voice Leading: 8.7/10

  Tension Curve: 6.2 → 8.1 → 5.4 → 7.9

Neo-Soul Classic:
  Uniqueness: 5.2/10

  Mode: ionian (92.0% confidence)

  Voice Leading: 9.1/10

  Tension Curve: 3.1 → 3.4 → 3.2 → 3.8

```

**Why Ethiojazz scores higher**: Exotic Phrygian mode + dynamic tension arc vs. predictable Ionian harmony + flat tension.
## Dilla's Secret Formula
1. **Dorian dominance**: Natural minor + raised 6th (familiar yet intriguing)
2. **Minimal voice movement**: 1-2 semitones per transition

3. **Golden ratio swing**: 54.2% offbeat push/pull

4. **Analog emulation**: Microtonality + tape saturation

## Customization
Edit `PROGRESSIONS` hash in `chords.rb`:
```ruby

my_prog: {

  name: "My Progression",

  tempo: 80,

  duration: 3.5,

  fx: :dilla_butter,

  chords: [

    { name: 'Dm9', freqs: [146.83, 174.61, 220.00, 261.63, 329.63] },

    # Add more chords...

  ]

}

```

Edit `PATTERNS` hash in `drums.rb` for custom techno rhythms.
## Performance
- **chords.rb**: ~5-8 minutes (16 progressions × 4 chords × 3-layer synthesis × FX)
- **drums.rb**: ~1-3 minutes (5 patterns × proper length, 8-16 bars not 32s)

- **mix.rb**: ~1-2 minutes (analysis + mixing + atmospheric generation)

- **Total workflow**: ~10 minutes for complete production

## Workflow
**Complete production in 3 steps:**
```bash
# Step 1: Generate chords (~5-8 min)

ruby chords.rb

# Output: 16 progression files + chords.wav + theory analysis

# No clipping warnings = proper gain staging ✓

# Step 2: Generate drums (~1-3 min)
ruby drums.rb

# Output: 5 pattern files + drums.wav

# Proper Berlin techno with GoldBaby 808s ✓

# Step 3: Create ultimate mix (~1-2 min)
ruby mix.rb

# Output: ultimate.wav (chords + drums + ethereal pad by default)

# Deep, hypnotic, club-ready ✓

# Optional: Create with vocal/lush alternating pads
ruby mix.rb chords.wav drums.wav ultimate_vocal_lush.wav vocal_lush

# Output: ultimate_vocal_lush.wav (with "Singers Unlimited" harmonies + lush synth pads)

# Optional: Create all 5 atmospheric variations
ruby mix.rb all

# Output: ultimate_ethereal.wav, ultimate_cosmic.wav, ultimate_dreamy.wav,

#         ultimate_dark_ambient.wav, ultimate_vocal_lush.wav

```

## Troubleshooting
**Clipping warnings on chords:**
- FIXED in latest version

- Chains now use: compression → moderate EQ → normalize → dither

- All gains reduced, reverb wet levels lowered

**Drums don't sound like techno:**
- FIXED in latest version

- Now uses proper 8-16 bar patterns (was 32 seconds)

- Proper kick tuning with pitch shifting

- Best GoldBaby ROM808 sample selection per style

**Ruby not found:**
```bash

which ruby

ruby --version

```

**SoX missing:**
```bash

ls effects/sox/sox.exe

# Download from: http://sox.sourceforge.net/

```

**808 samples missing:** Script synthesizes drums automatically (fallback works fine).
## Directory Structure
Following master.json anti-fragmentation principles, all audio tools are organized by domain:
```
dilla/

├── instruments/          # Synthesis and instrument tools

│   ├── fluidsynth/      # FluidSynth source (build with cmake)

│   └── soundfonts/      # Professional SoundFont 2/3 files

│       ├── FluidR3_GM.sf2 (3.3MB) - General MIDI

│       ├── MuseScore_General.sf3 (9.3MB) - High-quality

│       └── VintageDreamsWaves-v2.sf2/sf3 - Analog emulation

├── effects/              # Audio processing tools

│   └── sox/             # SoX audio processing suite

├── chords.rb            # Main chord generator with 27 progressions

├── drums.rb             # Berlin techno drum generator

├── mix.rb               # Surreal atmospheric mixer

├── CHORD_THEORY.md      # Music theory analysis documentation

└── studio_master.sh     # Mastering chain scripts

```

## References
- Music theory: Dorian/Phrygian modal analysis, voice leading optimization
- J Dilla: Donuts (2006), golden ratio swing timing research

- HATE Collective: Filip Xavi's deep techno aesthetic

- GoldBaby ROM808: Analog TR-808 sample pack

---
Generated: 2025-10-10
