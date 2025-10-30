# Audio Generation System
Complete audio generation system with SoX-based synthesis, per-note swing timing, FM synthesis, and J Dilla Donuts chord progressions database.

## Overview

This repository includes a comprehensive audio generation system built entirely in Ruby with SoX (Sound eXchange) for audio synthesis. No DAWs, no plugins - just pure code-based music generation.

## Features

### 1. SoX-Based Synthesis

- Pure waveform synthesis (sine, sawtooth, square, noise)

- Cross-platform support (Linux, macOS, Windows/Cygwin, OpenBSD)
- Industrial techno drum synthesis
- Neo-soul chord progressions with extended voicings
### 2. FM Synthesis
- 3-layer synthesis combining sawtooth + square + sine waves

- Warm, analog character
- Implemented in `multimedia/dilla/pads.rb` and `multimedia/dilla/chords.rb`
- Multiple instrument presets: Rhodes, Wurlitzer, CS-80, Minimoog
### 3. Per-Note Swing Timing
- J Dilla-style micro-timing implementation

- Configurable swing percentage (50-70%)
- Evidence-based timing from analysis of Donuts (2006)
- Implemented in `multimedia/dilla/drums_consolidated.rb`
### 4. J Dilla Donuts Chord Progressions Database
- Comprehensive database in `multimedia/dilla/dilla_data.json`

- 30+ chord progressions including:
  - `dilla_life` - J Dilla "Life" progression from Donuts
  - `donut_shop` - Donuts-inspired progression
  - Ahmad Jamal, Isley Brothers, Erykah Badu progressions
  - Modal jazz, neo-soul, and experimental progressions
## Entry Points
### Burst - Industrial Techno Generator

```bash

ruby multimedia/burst.rb                    # Default: 135 BPM, 16 bars
ruby multimedia/burst.rb --rate 140         # Custom BPM
ruby multimedia/burst.rb --bars 8           # Custom length
ruby multimedia/burst.rb --out custom.wav   # Custom output
```
### Dilla - J Dilla-Style Beats and Chords
```bash

ruby multimedia/dilla.rb                    # Delegates to master.rb
```
### Master - Complete Workflow Orchestrator
```bash

cd multimedia/dilla
ruby master.rb                              # Full render (chords + drums + mixes)
ruby master.rb --chords-only                # Just chord progressions
ruby master.rb --drums-only                 # Just drum patterns
ruby master.rb --quick                      # Quick test (5 progressions)
```
### Chords - Chord Progression Generator
```bash

cd multimedia/dilla
ruby chords.rb                              # Generate all chord progressions with FM synthesis
```
### Drums - Drum Pattern Generator with Swing
```bash

cd multimedia/dilla
ruby drums_consolidated.rb                  # Generate techno + hip-hop patterns with swing
```
### Pads - FM Synthesis Pads and Atmospheric Sounds
```bash

cd multimedia/dilla
ruby pads.rb                                # Generate atmospheric pads with FM synthesis
```
## Technical Implementation
### FM Synthesis Implementation

Located in `multimedia/dilla/chords.rb` and `multimedia/dilla/pads.rb`:

```ruby
def generate_chord(freqs, duration, output)

  voices = freqs.each_with_index.map do |freq, i|
    # Layer 1: Sawtooth (rich harmonics)
    sox("-n saw#{i}.wav synth #{duration} sawtooth #{freq} gain -18")
    # Layer 2: Square (warmth)
    sox("-n sqr#{i}.wav synth #{duration} square #{freq} gain -20")
    # Layer 3: Sine (fundamental)
    sox("-n sin#{i}.wav synth #{duration} sine #{freq} gain -16")
    # Mix all 3 layers per voice
    sox("-m saw#{i}.wav sqr#{i}.wav sin#{i}.wav v#{i}.wav")
  end
  sox("-m #{voices.join(' ')} #{output}")
end
```
### Swing Timing Implementation
Located in `multimedia/dilla/drums_consolidated.rb`:

```ruby
# Calculate swing offset based on swing percentage

swing_factor = (swing_pct - 50) / 100.0
swing_offset = (beat_sec / 8) * swing_factor
# Apply swing to offbeat notes
offset = base + eighth * (beat_sec / 2) + (eighth.odd? ? swing_offset : 0)

```
## Data Structure
### dilla_data.json

Unified database containing:

- Chord types (triads, sevenths, extended chords)
- Jazz progressions (ii-V-I, modal progressions)
- Neo-soul progressions (30+ progressions)
- Drum patterns with evidence-based timing
- FX presets (warm_tape, lofi_dream, dilla_butter, analog_lush)
## Requirements
- Ruby 2.7+

- SoX (Sound eXchange)

  - Linux: `apt-get install sox libsox-fmt-all`
  - macOS: `brew install sox`
  - Windows: Use Cygwin or WSL
## Testing
Run the test suite:

```bash

# Test industrial techno generation
ruby multimedia/burst.rb --out test.wav --rate 130 --bars 2
# Test drum generation with swing
cd multimedia/dilla

ruby drums_consolidated.rb
# Test FM synthesis chord generation
cd multimedia/dilla

ruby chords.rb
```
## Evidence Base
- **Donuts (2006)** - J Dilla's masterwork, analyzed for timing patterns

- **arXiv 1904.03442** - Research on consistent swing ratios vs random jitter

- Jazz standards - Ahmad Jamal, John Coltrane
- Neo-soul classics - Erykah Badu, D'Angelo
## Documentation in master.json
The audio generation system is documented in `master.json` under the `tools.audio_generation` section:

```json

"audio_generation": {

  "engine": "SoX",
  "description": "Complete audio generation system with pure Ruby + SoX synthesis",
  "capabilities": [
    "SoX-based waveform synthesis (sine, sawtooth, square, noise)",
    "FM synthesis for warm analog character",
    "Per-note swing timing (J Dilla-style micro-timing)",
    "J Dilla Donuts chord progressions database",
    "Industrial techno drum synthesis",
    "Neo-soul chord progressions with extended voicings"
  ]
}
```
## License
See LICENSE file in repository root.

