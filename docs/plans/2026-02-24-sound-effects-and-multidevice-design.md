# Sound Effects & Multi-Device Support Design

## Summary

Two features for PhoLife:
1. Programmatic sound effects for all 8 minigames using AVAudioEngine real-time synthesis
2. Mac support via "Designed for iPad" (keep iPad-only device family, no iPhone)

## Sound System Architecture

### SoundSynthesizer Service

New `SoundSynthesizer` class using `AVAudioEngine` with three mixer nodes:

- **Music mixer**: Existing file-based `AVAudioPlayer` for `background-music.mp3` (unchanged)
- **Ambient mixer**: `AVAudioSourceNode` generating continuous audio via callback, swappable per minigame
- **SFX mixer**: Pre-rendered `AVAudioPCMBuffer` objects generated at init, played via pooled `AVAudioPlayerNode` instances

### Synthesis Primitives

- White/pink noise (filtered) — sizzling, frying, charring
- Sine wave clusters with randomized timing — bubbling, boiling
- Short enveloped tones — chimes, success/fail indicators
- Noise bursts with pitch envelope — pops, slices, card flips
- Filtered noise + resonance — liquid pouring, splashing

### AudioManager Changes

- `playSFX(_ name:)` routes to `SoundSynthesizer` instead of loading files
- `playAmbient(_ name:)` starts/crossfades the ambient source node
- `stopAmbient()` fades out the ambient source node
- Music layer unchanged (keeps file-based playback)

## Global SFX

| Sound | Synthesis | Duration | Context |
|-------|-----------|----------|---------|
| `successChime` | Rising 3-note sine arpeggio (C5-E5-G5), soft attack | 0.4s | Perfect/correct action |
| `failBuzz` | Low square wave (80Hz) + noise burst, fast decay | 0.2s | Miss/wrong action |
| `starReveal` | Ascending bell tone with shimmer (sine + harmonics) | 0.5s | Score card star |
| `buttonTap` | Filtered noise impulse | 0.05s | UI button press |
| `completionFanfare` | 4-note ascending major chord with sustain | 1.2s | Game completion |

## Per-Minigame Sounds

### 0 — Char Aromatics
- **Ambient**: Crackling fire (filtered noise + random pops)
- **Action SFX**: `sizzle` — burst of filtered noise on tap
- **Success/Fail**: Global successChime / failBuzz

### 1 — Toast Spices
- **Ambient**: Gentle flame crackle (low-freq noise)
- **Action SFX**: `toastCrackle` — short snap on catch
- **Success/Fail**: Global successChime / failBuzz

### 2 — Clean Bones
- **Ambient**: Bubbling water (sine clusters, randomized)
- **Action SFX**: `pop` — quick pitched noise burst
- **Success/Fail**: Global successChime / failBuzz

### 3 — Simmer Broth
- **Ambient**: Rolling boil (deep bubbling + steam hiss)
- **Action SFX**: `simmerEntry` — warm tone on zone entry
- **Success/Fail**: Global successChime / failBuzz

### 4 — Slice Beef
- **Ambient**: Cutting board ambience (subtle hum)
- **Action SFX**: `slice` — sharp noise sweep, fast decay
- **Success/Fail**: Global successChime / failBuzz

### 5 — Season Broth
- **Ambient**: Gentle steam (soft filtered noise)
- **Action SFX**: `pourLiquid` — filtered noise with pitch drop on slider
- **Success/Fail**: Global successChime / failBuzz

### 6 — Assemble Bowl
- **Ambient**: Kitchen ambience (low warm hum)
- **Action SFX**: `place` — soft thud + resonance on placement
- **Success/Fail**: Global successChime / failBuzz

### 7 — Top It Off
- **Ambient**: Light ambient air (very subtle)
- **Action SFX**: `cardFlip` — short pitched click; `sparkle` — high shimmer
- **Success/Fail**: Global successChime / failBuzz

## Multi-Device Support

### Changes
- Keep `.pad` in `supportedDeviceFamilies` (no `.phone`)
- Mac runs via "Designed for iPad" on Apple Silicon — no Catalyst needed
- Wrap `AVAudioSession` calls with `#if os(iOS)` for macOS compatibility
- No layout changes — iPad landscape layout is the canonical design

### What stays the same
- Landscape-locked orientation
- SpriteKit scenes scale dynamically (positions computed from `size.width`/`size.height`)
- SwiftUI overlays use `.ignoresSafeArea()` and fill available space
