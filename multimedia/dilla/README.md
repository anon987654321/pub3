# J Dilla Music Generation
**Pure Ruby + SoX synthesis** - No DAWs, no plugins. Generates J Dilla-style chord progressions, Berlin techno drums, and surreal atmospheric mixes with music theory analysis.

## Quick Start
```bash
cd /path/to/multimedia/dilla

# List all available progressions
./dilla list

# Generate complete production (chords + bass + drums + mixes)
./dilla generate

# Quick demo (5 progressions only)
./dilla quick

# Render specific components
./dilla render --chords      # Just chord progressions
./dilla render --drums       # Just drum patterns  
./dilla render --mix         # Just final mixes

# Alternative: Use master.rb directly
ruby master.rb               # Full render
ruby master.rb --chords      # Chords only
ruby master.rb --drums       # Drums only
ruby master.rb --quick       # Quick test

# Create atmospheric mixes
ruby mix.rb                  # Single ethereal mix
ruby mix.rb all              # All 5 atmospheric variations
```

## Consolidated Architecture (NEW!)
Following master.json anti-fragmentation principles, all code and data have been consolidated:

### **Data Consolidation**
- **dilla_data.json**: Single source of truth containing:
  - 42 chord progressions (neo-soul, jazz, funk-soul)
  - 15 iconic pad synthesis recipes
  - 15 drum patterns (hip-hop, jazz, reggae, techno-house)
  - Vintage FX chains and swing theory

### **Code Consolidation**  
- **master.rb**: Single orchestrator for all generation
- **lib/synthesis.rb**: DRY synthesis library with 7 synth types (rhodes, fm, cs80, minimoog, strings, ambient, oberheim)
- **dilla CLI**: Simple command-line interface wrapper
- **mix.rb**: Preserved for distinct atmospheric mixing purpose

### **7 Synth Types Available**
- **Rhodes**: Electric piano with tremolo and chorus
- **FM**: Sawtooth + square + sine layering (warm, rich)
- **CS-80**: Detuned saws (Blade Runner/Vangelis style)
- **Minimoog**: Saw + square brass (Pink Floyd style)
- **Strings**: 3-voice detuned ensemble (ARP Solina)
- **Ambient**: Sine + saw blend (Brian Eno style)
- **Oberheim**: Unison detuned (Frank Ocean/Van Halen)

## Output
**master.rb** (or `./dilla generate`) creates:
- **chords/**: 42 chord progressions with proper gain staging
- **bass/**: Bass layers (root + sub-bass)
- **drums/**: Intricate drum patterns with swing
- **final/**: Complete mixed tracks (chords + bass + drums)

**mix.rb** creates:
- `ultimate.wav` - Combined chords + drums + surreal atmospheric pad
- **5 atmospheric styles**: ethereal, cosmic, dreamy, dark_ambient, vocal_lush
- **vocal_lush**: Alternating vocal harmonies (ooh/aah) and lush synth pads every 8 seconds
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
**Complete production workflow:**
```bash
# One-command full generation
./dilla generate              # Generates everything (chords + bass + drums + mixes)

# Or step-by-step
./dilla render --chords       # Step 1: Generate chord progressions
./dilla render --drums        # Step 2: Generate drum patterns
./dilla render --mix          # Step 3: Create final mixes

# Quick testing
./dilla quick                 # Generate only 5 progressions for testing

# Browse available content
./dilla list                  # See all 42 progressions

# Atmospheric mixing (separate tool)
ruby mix.rb                   # Create ethereal mix
ruby mix.rb all               # Create all 5 atmospheric variations
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
Following master.json anti-fragmentation principles, consolidated and DRY:
```
dilla/
├── lib/
│   └── synthesis.rb         # DRY synthesis library (7 synth types)
├── dilla                    # CLI wrapper (executable)
├── master.rb                # Main orchestrator (consolidated entry point)
├── mix.rb                   # Atmospheric mixer (distinct purpose)
├── dilla_data.json          # Consolidated data (progressions, drums, FX)
├── README.md
├── chords/                  # Generated chord progressions
├── bass/                    # Generated bass layers
├── drums/                   # Generated drum patterns
└── final/                   # Complete mixed tracks
```

**Removed files** (consolidated into master.rb + lib/):
- ~~chords.rb~~ → `./dilla render --chords`
- ~~pads.rb~~ → `master.rb` (using lib/synthesis.rb)
- ~~drums.rb~~ → `./dilla render --drums`
- ~~drums_fixed.rb~~ → `./dilla render --drums`
- ~~create_final_mixes.rb~~ → `./dilla render --mix`
- ~~chord_theory.json~~ → `dilla_data.json`
- ~~chord_theory_expanded.json~~ (duplicate)
- ~~drum_patterns.json~~ → `dilla_data.json`

## References
- Music theory: Dorian/Phrygian modal analysis, voice leading optimization
- J Dilla: Donuts (2006), golden ratio swing timing research

- HATE Collective: Filip Xavi's deep techno aesthetic

- GoldBaby ROM808: Analog TR-808 sample pack

---
Generated: 2025-10-10
