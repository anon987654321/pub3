# Multimedia Subsystems

Complete multimedia generation toolkit with 4 integrated subsystems for audio, image processing, AI generation, and text-to-speech.

## Overview

| Subsystem | Purpose | Entry Point | Output Formats |
|-----------|---------|-------------|----------------|
| **dilla** | Algorithmic music generation | `master.rb` | WAV, MP3 |
| **postpro** | Professional image post-processing | `postpro.rb` | PNG, JPG |
| **repligen** | AI image generation workflows | `repligen.rb` | PNG |
| **tts** | Multi-engine text-to-speech | `smart_say.rb` | WAV, MP3 |

## Quick Start

### Dependencies

**System packages:**
```bash
# macOS
brew install sox ffmpeg imagemagick vips python ruby

# Ubuntu/Debian
sudo apt install sox ffmpeg imagemagick libvips-dev python3 ruby

# OpenBSD
doas pkg_add sox ffmpeg imagemagick vips python ruby-3.3
```

**Ruby gems:**
```bash
gem install ruby-vips tty-prompt json logger fileutils
```

### Usage Examples

#### Generate Music (dilla)
```bash
cd multimedia/dilla
ruby master.rb              # Interactive mode
./render_all.sh            # Batch render all tracks
./play_continuous.sh       # Live playback loop
```

#### Process Images (postpro)
```bash
cd multimedia/postpro
ruby postpro.rb input.jpg   # Interactive processing
ruby postpro.rb --preset portrait input.jpg
ruby postpro.rb --auto input.jpg
```

#### Generate AI Images (repligen)
```bash
cd multimedia/repligen
ruby repligen.rb "a cinematic portrait"
./lora_masterpiece_workflow.sh
```

#### Text-to-Speech (tts)
```bash
cd multimedia/tts
ruby smart_say.rb "Hello world"
ruby claude_speak.rb        # Interactive AI narration
./install_voice_system.sh   # Setup TTS engines
```

## Subsystem Details

### 1. dilla - Music Generation

**Location:** `multimedia/dilla/`

Algorithmic music composition system inspired by J Dilla's production style.

**Key Features:**
- Multi-track generation (bass, chords, pads, drums, effects)
- Real-time parameter modulation
- Musical data library (94KB JSON database)
- Cross-platform playback (Unix + Windows)

**Architecture:**
- `master.rb` - Main orchestrator
- `chords.rb`, `pads.rb`, `drums_consolidated.rb`, `mix_consolidated.rb` - Generators
- `dilla_data.json` - Musical patterns and parameters
- `render_all.sh`, `play_continuous.sh` - Automation scripts

**Output:** WAV files @ 44.1kHz/16-bit/stereo

**Documentation:** See [dilla/README.md](dilla/README.md)

### 2. postpro - Image Post-Processing

**Location:** `multimedia/postpro/`

Professional cinematic post-processing with camera profiles.

**Key Features:**
- Camera-specific color profiles
- Film stock emulation (Kodak, Fuji)
- Cinematic color grading (teal/orange, vintage lens)
- Recipe-based batch processing

**Architecture:**
- `postpro.rb` - Main processing engine (28KB, requires ruby-vips)
- `camera_profiles/` - Camera-specific color matrices
- `recipes/` - Saved processing recipes

**Presets:**
- `portrait` - Skin-aware, warm tones
- `landscape` - Vibrant colors, enhanced contrast
- `street` - High contrast, film grain
- `blockbuster` - Teal/orange, bloom effects

**Documentation:** See [postpro/README.md](postpro/README.md)

### 3. repligen - AI Image Generation

**Location:** `multimedia/repligen/`

AI-powered image generation with Stable Diffusion and LoRA workflows.

**Key Features:**
- Replicate API integration
- LoRA model workflows
- Automated prompt engineering
- Integration with postpro for refinement

**Architecture:**
- `repligen.rb` - Main generator
- `lora_masterpiece_workflow.sh` - Advanced workflow automation
- `bin/`, `lib/` - Supporting utilities
- `archive/` - Generated image archives

**Documentation:** See [repligen/README.md](repligen/README.md)

### 4. tts - Text-to-Speech

**Location:** `multimedia/tts/`

Multi-engine TTS system with AI narrator integration.

**Key Features:**
- Multiple TTS engines (Piper, Sherpa-ONNX, gTTS, Replicate)
- Claude AI integration for narration
- Multi-language support (English, Malay)
- Specialized scripts (reasoning narration, humor)

**Architecture:**
- `smart_say.rb` - Intelligent engine selection
- `claude_speak.rb` - AI narrator
- `install_piper.rb`, `install_sherpa.rb` - Engine installers
- 18 Ruby scripts for different use cases

**Engines:**
- **Piper** - Fast, offline, high-quality
- **Sherpa-ONNX** - Real-time, low-latency
- **gTTS** - Google TTS, cloud-based
- **Replicate** - AI voices via API

**Documentation:** See [tts/README.md](tts/README.md)

## Integration with master.json

All subsystems are governed by `master.json` standards:

- **File size limits:** 20KB per Ruby file (exception: postpro.rb)
- **No backup files:** Version control via git only
- **Gitignored output:** Generated audio/images excluded
- **Documentation required:** Every subsystem has README
- **Code quality:** Follows master.json principles

Validate compliance:
```bash
cd multimedia
./validate_all.sh
```

## Cross-Subsystem Workflows

### Workflow 1: AI Image → Post-Processing
```bash
cd multimedia/repligen
ruby repligen.rb "cinematic portrait"
cd ../postpro
ruby postpro.rb --preset blockbuster ../repligen/output/*.png
```

### Workflow 2: Music → Narration
```bash
cd multimedia/dilla
./render_all.sh
cd ../tts
ruby narrate_reasoning.rb "Describing the music generation process"
```

### Workflow 3: Full Multimedia Production
```bash
# 1. Generate images
cd multimedia/repligen
ruby repligen.rb "story scene"

# 2. Post-process
cd ../postpro
ruby postpro.rb --preset cinematic ../repligen/output/*.png

# 3. Generate soundtrack
cd ../dilla
ruby master.rb

# 4. Add narration
cd ../tts
ruby claude_speak.rb < script.txt
```

## Output Management

All generated files are gitignored by default:

```
multimedia/
├── dilla/       → *.wav, *.mp3, *.log, bass/, chords/, drums/
├── postpro/     → *.png, *.jpg, output/
├── repligen/    → *.png, *.jpg, output/
└── tts/         → *.wav, *.mp3, *.log, output/
```

Archives and binaries (*.tar.gz, *.zip) are also gitignored.

## Development

### File Organization
- Entry points: `*_main.rb` or descriptive names
- Libraries: `lib/` subdirectories
- Configuration: JSON files with schemas
- Scripts: Executable `.sh` files with zsh shebang

### Code Standards
- Ruby 3.3+ required
- Follow master.json conventions
- Maximum file size: 20KB (with documented exceptions)
- No backup files without permission
- Comprehensive error handling

### Testing
```bash
# Test each subsystem
cd multimedia/dilla && ruby master.rb --test
cd multimedia/postpro && ruby postpro.rb --test
cd multimedia/repligen && ruby repligen.rb --test
cd multimedia/tts && ruby smart_say.rb "test"
```

### Validation
```bash
cd multimedia
./validate_all.sh  # Run all compliance checks
```

## Troubleshooting

### dilla
- **No audio output:** Check SoX/FFmpeg installation
- **Render errors:** Verify dilla_data.json integrity
- **Windows playback:** Use PowerShell scripts (.ps1)

### postpro
- **libvips errors:** Install system package (`brew install vips` or `apt install libvips-dev`)
- **ruby-vips missing:** Run `gem install ruby-vips`
- **Camera profile not found:** Check `camera_profiles/*.json` exists

### repligen
- **API errors:** Verify Replicate API key in environment
- **Slow generation:** Check API rate limits
- **Output quality:** Adjust LoRA weights in workflow

### tts
- **Engine not found:** Run appropriate installer script
- **No audio:** Check system audio device
- **Claude errors:** Verify API credentials

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for:
- Code style guidelines
- Commit conventions
- Pull request process

## License

See [LICENSE](../LICENSE) for terms.

## Links

- **Master governance:** [master.json](../master.json)
- **Project overview:** [README.md](../README.md)
- **Validation script:** [validate_all.sh](validate_all.sh)
