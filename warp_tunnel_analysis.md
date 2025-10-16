# Warp Tunnel Visualization Analysis (master.json lens)

## Current State

**PixelTunnel** at index.html:756-778
- Classic warp tunnel: rotating rings with z-depth perspective
- Audio-reactive: bass/mid/high affect radius, colors
- Parallax input: mouse + device orientation
- 8 visualizers total, auto-switch on track change
- Performance optimization: trig table caching, dynamic scaling

## master.json Principles Applied

### ✓ Achieved

**ultraminimal**:
- Single file, inline everything
- Minimal dependencies (canvas 2D only)
- ~300 LOC for core tunnel

**performance**:
- Pre-computed trig tables (lines 812-848)
- Uint32Array for pixels (line 760)
- Dynamic scale adjustment (line 972)
- Culling (ringPxCull line 759)

**reversible**:
- Multiple viz modes (V key)
- Theme switching (C key)
- Intensity controls ([/])

### ⚠ Violations & Opportunities

**complexity > 10** (line 776):
- `frame()` method: ~80 LOC, cyclomatic complexity ≈15
- Violates master.json execution.limits.complexity:10
- **Fix**: Extract methods: `projectRing()`, `updateCenters()`, `cullParticles()`

**duplication**:
- Color calculation scattered: line 772, plus 7 other visualizers
- **Fix**: Central `ColorEngine` class with themes

**magic numbers**:
- fov:250, baseRadius:75, speed:.75, zStep:4 (line 759)
- **Fix**: Config object with semantic names

**nesting > 3**:
- Triple loop: particles/row/segments (lines 776)
- **Fix**: Flatten with particle pool, spatial hash

## Improvement Ideas (Hostile QA Applied)

### 1. **Skeptic**: Why separate visualizers?
**Current**: 8 classes, duplicate structure
**Propose**: Composable effect pipeline
```js
tunnel.addEffect('spiral', {mix: 0.3})
tunnel.addEffect('chromatic', {shift: 5})
```

### 2. **Minimalist**: Remove everything
**Keep**:
- Core projection math (essential)
- Audio reactivity (defines purpose)
- Input handling (interaction)

**Remove**:
- Psychedelic modes (use CSS filters)
- Separate viz classes (merge to effects)
- Particle structs (use Float32Array pool)

### 3. **Security**: Input validation
**Missing**:
- Canvas bounds check (line 764 ≤/>= but mouse can exceed)
- Audio data sanitization (NaN/Infinity crash)
- **Add**: Clamp all external inputs

### 4. **Performance**: Milliseconds matter
**Optimize**:
- drawLine32: Bresenham allocates (line 766)
  - Pre-allocate line buffer
- Particle sort: O(n log n) every frame when zooming (line 776)
  - Use insertion/bucket sort
- getCirclePos: Still calls % operator (line 838)
  - Pre-wrap indices

### 5. **Junior**: Simplify
**Complex**:
- Projection math inline (line 776)
- Trig caching patch (lines 790-856)
**Fix**:
- Comment formulas: `// Project 3D→2D: x' = x * (fov/(fov+z))`
- Extract `class Camera` for projection

### 6. **Architect**: 10yr implications
**Current**: Monolithic class
**Risk**: Adding depth effects, lighting, post-process
**Propose**: Separate concerns
```
Geometry → Projection → Rasterizer → Compositor
```

### 7. **Strunk & White**: Prose violations
**Needless words**:
- "Classic warp tunnel" → "Warp tunnel"
- "Tilt device for parallax" → "Tilt for parallax"

**Vague**:
- "multiple views" → "8 visualizers"

## Concrete Improvements

### Priority 1: Reduce Complexity
```js
// Extract from frame()
updateCenters(center, row, mouse, ori) { /* 10 LOC */ }
projectParticles(row, center, audioData) { /* 15 LOC */ }
renderRing(row, color) { /* 8 LOC */ }
```

### Priority 2: Config-driven
```js
const CONFIG = {
  camera: {fov: 250, near: -250, far: 250},
  geometry: {rings: 64, segments: 64, radius: 75},
  motion: {speed: 0.75, zStep: 4},
  culling: {minRingPx: 0.15}
}
```

### Priority 3: Effect System
```js
class EffectPipeline {
  constructor() { this.effects = [] }
  add(effect, params) { this.effects.push({effect, params}) }
  apply(geometry, audio) {
    return this.effects.reduce((g, {effect, params}) =>
      effect(g, audio, params), geometry)
  }
}
```

### Priority 4: Spatial Optimization
```js
// Replace particle array-of-arrays with flat pool
class ParticlePool {
  constructor(maxParticles) {
    this.pos = new Float32Array(maxParticles * 3)  // xyz
    this.proj = new Float32Array(maxParticles * 2) // x2d,y2d
    this.meta = new Uint32Array(maxParticles * 2)  // ring,segment
    this.count = 0
  }
}
```

## SoX Drone Integration

Visualizer responds to 8 frequency bands. Drone provides:
- **Sub-bass** (20-60Hz): Ring expansion
- **Bass** (60-250Hz): Z-depth modulation
- **Mid** (250-2kHz): Rotation speed
- **High** (2k-8kHz): Color saturation
- **Treble** (8k+): Noise/grain

Continuous drone = steady visual baseline, music = deviations.

## Decision Record

**Date**: 2025-10-16
**Decision**: warp_tunnel_refactor_config_driven
**Rationale**: complexity_limit_violated_duplication_high
**Status**: proposed
