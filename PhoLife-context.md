# PhoLife - Complete Codebase Context

## Overview

PhoLife is an educational iPad game that teaches Vietnamese pho preparation through an interactive 4-phase experience: animated splash → narrative story → 8 cooking minigames → completion summary. Built with SwiftUI + SpriteKit, targeting iOS 17+ / macOS 14+.

- **Bundle ID**: com.henrytran.PhoLife
- **Team ID**: YLL2K7Q88J
- **Swift Version**: 6.0
- **Platforms**: iPad and Mac only (no iPhone)
- **Category**: Education
- **Orientations**: Portrait, Landscape Left, Landscape Right, Portrait Upside Down

---

## Project Structure

```
PhoLife.swiftpm/
├── PhoLifeApp.swift                    # @main entry point
├── ContentView.swift                   # Root phase router
├── Package.swift                       # SPM manifest
├── Models/
│   ├── GameState.swift                 # Observable state controller
│   ├── MinigameResult.swift            # Game outcome struct
│   ├── PhoIngredient.swift             # 8 ingredients + icon enum
│   ├── CulturalFact.swift              # 8 educational facts
│   └── StoryPanel.swift                # 10-panel narrative data + narrator expressions
├── Services/
│   ├── AudioManager.swift              # 3-layer audio system (music/ambient/SFX)
│   ├── SoundSynthesizer.swift          # Programmatic SFX engine (AVAudioEngine)
│   └── HapticManager.swift             # Impact + notification haptics
├── Features/
│   ├── Splash/
│   │   └── SplashView.swift            # Animated intro (convergence effect)
│   ├── Story/
│   │   ├── StoryView.swift             # Sequential panel navigator
│   │   ├── StoryPanelView.swift        # Individual panel (typewriter + narrator)
│   │   ├── NarratorPortraitView.swift  # Animated narrator portrait
│   │   └── StoryBackgroundView.swift   # Ken Burns background images
│   ├── Minigames/
│   │   ├── MinigameContainerView.swift # Phase controller (intro → playing → score)
│   │   ├── MinigameIntroCard.swift     # Pre-game overlay with narrator dialogue
│   │   ├── MinigameScoreCard.swift     # Post-game results overlay
│   │   └── Scenes/
│   │       ├── CharAromaticsScene.swift      # [0] Timing bar game
│   │       ├── ToastSpicesScene.swift        # [1] Swipe-catch game
│   │       ├── CleanBonesScene.swift         # [2] Bubble tapping game
│   │       ├── SimmerBrothScene.swift        # [3] Hold-to-rise gauge game
│   │       ├── SliceBeefScene.swift          # [4] Tap-timing slice game
│   │       ├── SeasonBrothScene.swift        # [5] Triple slider balancing
│   │       ├── AssembleBowlScene.swift       # [6] Sequence ordering game
│   │       ├── TopItOffScene.swift           # [7] Memory card matching
│   │       └── PlaceholderMinigameScene.swift # Fallback scene (index ≥8)
│   ├── Completion/
│   │   └── CompletionView.swift        # Results summary + earned title
│   └── Shared/
│       ├── GlassContainer.swift        # Frosted glass ViewModifier
│       ├── ProgressBarView.swift       # 8-dot step progress
│       ├── StarRatingView.swift        # 1-3 animated gold stars
│       ├── SceneEffects.swift          # SpriteKit SKScene extensions
│       └── PhoIngredientIcon.swift     # 8 procedural Canvas icons
└── Resources/
    ├── Assets.xcassets/                # Images + colors
    │   ├── AppIcon.appiconset/
    │   ├── AccentColor.colorset/       # Orange
    │   ├── splash-bowl.imageset/
    │   ├── completion-bowl.imageset/
    │   ├── narratorHappy.imageset/     # Narrator happy expression
    │   ├── narratorNeutral.imageset/   # Narrator neutral expression
    │   ├── narratorSpeak.imageset/     # Narrator speaking expression
    │   └── story-panel-1 through 10.imageset/  # 10 JPG story images
    └── Sounds/
        └── Music/
            ├── background-music.mp3    # Story/splash background track
            └── minigame-music.mp3      # Minigames background track
```

---

## App Flow & Phases

ContentView manages 4 phases via `GameState.AppPhase` enum:

```
Splash (auto ~5.5s) → Story (10 paging panels) → Minigames (8 sequential) → Completion
```

### Phase 1: Splash (`SplashView`)
- 6+ second animated introduction
- Bowl image with steam particle wisps (5 primary + 3 secondary)
- 8 ingredient icons converge from off-screen in 4 staggered waves
- "PhoLife" title in glass container with gradient text
- Landscape orientation hint at bottom
- Auto-advances via `onComplete` callback

### Phase 2: Story (`StoryView` + `StoryPanelView` + `NarratorPortraitView` + `StoryBackgroundView`)
- Sequential panel navigation with tap-to-advance and progress bar
- 10 panels telling pho's history (pre-colonial → modern diaspora)
- **StoryBackgroundView**: Full-screen images with Ken Burns zoom (1.0→1.08x over 8s), 0.6s crossfade
- **NarratorPortraitView**: Animated portrait with expression changes (happy/neutral/speak)
  - Breathing animation: 2.5s scale cycle (1.0→1.02)
  - Speaking animation: y-offset oscillation (-3px) when `isSpeaking=true`
  - Expression crossfade: 0.35s transition
- **Typewriter effect**: 25ms per character with text-blip SFX (3 pitch variants)
  - Shows "speak" expression during typing, "happy" otherwise
  - Skips whitespace/punctuation from SFX
  - Tapping during typewriter skips to full text
- **Dialogue segments**: Each panel has multiple `DialogueSegment` entries with per-segment expressions
- Final panel shows "Let's Cook" CTA button
- Skip button: "Skip to Cook" in top-right

### Phase 3: Minigames (`MinigameContainerView`)
- Orchestrates 8 SpriteKit minigames with 3 sub-phases each:
  - **Intro card** (with narrator dialogue) → **Playing** (SpriteKit scene) → **Score reveal**
- Scene factory pattern instantiates correct SKScene by index
- Fixed scene size: 1194×834 with `.aspectFill` scaling
- Dynamic blur (0/3/4 pts) applied to scene during overlays
- ProgressBarView shows 8-step progress at top
- **Audio management per sub-phase**:
  - Intro: `duckMusic()` (volume → 0.15), `stopAmbient()`
  - Playing: `unduckMusic()` (restore full volume)
  - Score reveal: `playSFX("star-reveal")`
- Callback pattern: `onComplete: (Int, Int) -> Void` passes (score, stars)

### Phase 4: Completion (`CompletionView`)
- 3-column layout: Performance | Hero Bowl | Ingredients
- Left: Per-minigame results table (name, score, stars)
- Center: Bowl image, title, overall stars, earned title, replay button
- Right: 8 ingredients with contribution descriptions
- Confetti particles for ≥2 star average completion
- Staggered reveal animation sequence (~2.6s total)

---

## Data Models

### GameState (`@Observable @MainActor`)
Central state container for entire app:
- `currentPhase: AppPhase` — splash, story, minigames, completion
- `currentMinigameIndex: Int` — 0-7
- `minigameResults: [MinigameResult]` — collected scores
- `hasSeenStory: Bool` — skip story on replay
- `totalStars: Int` — computed sum of all stars (max 24)
- `earnedTitle: String` — computed from total stars:
  - 0-8: "Street Food Curious"
  - 9-16: "Hanoi Home Cook"
  - 17-21: "Saigon Street Vendor"
  - 22-24: "Pho Master"
- **Methods**: `completeMinigame(result:)`, `resetForReplay()`, `skipToMinigames()`

### MinigameResult
- `id: UUID`, `minigameIndex: Int`, `stars: Int` (1-3), `score: Int`

### StoryPanel
- 10 static panels with `id`, `title`, `bodyText`, `imageName`, `ambientAudioFile`
- `expression: NarratorExpression` — default expression for the panel
- `dialogueSegments: [DialogueSegment]` — multi-segment narrator dialogue

### NarratorExpression (enum)
- Cases: `happy`, `neutral`, `speak`
- Maps to image assets: `"narratorHappy"`, `"narratorNeutral"`, `"narratorSpeak"`

### DialogueSegment
- `id: UUID`, `text: String`, `expression: NarratorExpression`

### PhoIngredient
- 8 ingredients: onion, star anise, bone, pot, beef slice, fish sauce, noodles, herbs
- Each has `name`, `contribution` text, `icon: PhoIngredientIcon` enum

### CulturalFact
- 8 facts paired 1:1 with minigames
- Each has `minigameTitle`, `fact`

---

## Minigame Scenes (SpriteKit)

### Implementation Status — All 8 Fully Implemented

| # | Scene | Mechanic | Key Details |
|---|-------|----------|-------------|
| 0 | CharAromaticsScene | Timing bar — tap when cursor hits golden zone | 4 rounds, difficulty ramp |
| 1 | ToastSpicesScene | Swipe-catch falling spices | 40s timer, combo tracking |
| 2 | CleanBonesScene | Tap rising bubbles before they escape | 35s, water clarity meter |
| 3 | SimmerBrothScene | Hold-to-rise gauge (Stardew-style) | 35s, moving green zone |
| 4 | SliceBeefScene | Tap when scissors line crosses beef | Speed increases per cut |
| 5 | SeasonBrothScene | Adjust 3 sliders to target values | Single "Taste" attempt |
| 6 | AssembleBowlScene | Tap ingredients in correct order | 4-step sequence with hints |
| 7 | TopItOffScene | Memory card matching (6 pairs) | Flip efficiency scoring |

### CharAromaticsScene (Minigame 0)
- **4 rounds**: 2 onions + 2 ginger slices charred on a skillet
- **Timing bar**: Left-right oscillating cursor, tap to release
- **Difficulty ramp**: Target zone shrinks (18% → 12%), cursor speed increases (0.55 → 0.79)
- **Scoring**: Perfect (within 9% of center) = 3pts, Good (within 18%) = 2pts, Miss = 1pt
- **Score formula**: `Int((totalPoints / 12.0) * 100)`, stars: ≥10=3★, ≥7=2★, else 1★
- **Visual layers**: Floor glow (-10) → skillet (0.5-2) → ingredient (2) → smoke (3) → timing bar (9.5-12) → feedback (15) → particles (85) → curtains (500)
- **Effects**: Particle bursts, expanding rings, golden flash, ingredient color darkening, grill marks

### ToastSpicesScene (Minigame 1)
- **40-second timer** with 10 spice types (5 correct, 5 decoys)
- **Falling arcs**: Spices spawn from top in parabolic arcs, player swipes to catch
- **Difficulty ramp**: Spawn interval decreases (1.5s → 0.8s), correct probability decreases (60% → 50%)
- **Scoring**: +2 per correct catch, -1 per wrong catch; combo tracking (displayed at ≥2)
- **Score formula**: `max(0, correctCatches * 20 - wrongCatches * 10)`
- **Stars**: ≥5 correct = 3★, ≥4 = 2★, else 1★
- **Effects**: Golden expanding rings for correct, red X + shake for wrong

### CleanBonesScene (Minigame 2)
- **35-second timer**: Tap bubbles before they rise and escape
- **Bubbles**: Spawn, rise with wobble animation, auto-pop if not tapped
- **Water clarity meter**: Overlay alpha decreases as bubble-tap percentage increases (0.6 → 0.0)
- **Clarity sparkles**: Special visual effect at 50% and 75% completion thresholds
- **Scoring**: Score = percentage tapped × 100
- **Stars**: ≥90% = 3★, ≥70% = 2★, else 1★

### SimmerBrothScene (Minigame 3)
- **35-second timer**: Stardew Valley-style hold-to-rise gauge with gravity physics
- **Gauge**: Green zone moves autonomously, speed increases over time
- **Mechanic**: Hold screen to raise gauge level, release to let it fall
- **Scoring**: Based on time spent inside the green zone
- **Stars**: Proportional to percentage of time in zone

### SliceBeefScene (Minigame 4)
- **Mechanic**: Scissors line moves up/down across beef, tap to cut
- **Difficulty ramp**: Scissors speed increases after each successful cut
- **Quality**: Depends on proximity to top (thinner slices = better quality)
- **Scoring**: Score = number of slices × 10
- **Stars**: >5 slices = 3★, >3 slices = 2★, else 1★

### SeasonBrothScene (Minigame 5)
- **3 sliders**: Fish Sauce (target 0.6), Salt (target 0.4), Sugar (target 0.2)
- **Visual feedback**: Broth color changes based on slider positions
- **Harmony meter**: Arc display (0 = red, perfect balance = green)
- **Single attempt**: One "Taste" button press to lock in
- **Scoring**: Error-based (perfect = 100 pts)
- **Stars**: ≥100 = 3★, ≥75 = 2★, else 1★

### AssembleBowlScene (Minigame 6)
- **Correct order**: Noodles → Brisket → Raw Beef → Broth
- **Hint system**: Glowing pulse on the correct next ingredient
- **Visual layers**: Each correct tap adds a visual ingredient layer with animation
- **Scoring**: Based on number of incorrect attempts
- **Stars**: 0-1 mistakes = 3★, ≤2 mistakes = 2★, else 1★

### TopItOffScene (Minigame 7)
- **12 cards** = 6 pairs (topping name ↔ role description with emoji)
- **Mechanic**: Flip two cards to find matching pairs
- **Scoring**: Based on flip efficiency (fewer total flips = better)
- **Stars**: Determined by flip count relative to optimal

### Scene Interface Pattern
All scenes follow the same contract:
```swift
class SomeScene: SKScene {
    var onComplete: ((Int, Int) -> Void)?  // (score, stars)
    // Scene triggers onComplete when gameplay finishes
}
```

---

## Services

### AudioManager (Singleton, `@Observable @MainActor`)
Three independent audio layers with smart resource management:

| Layer | Implementation | Default Volume | Usage |
|-------|---------------|----------------|-------|
| **Music** | Dual AVAudioPlayer with crossfade | 0.4 | Background loop (continuous) |
| **Ambient** | Dual AVAudioPlayer with crossfade | 0.3 | Kitchen sounds during gameplay |
| **SFX** | Pool of 8 fire-and-forget players | 0.7 | Button taps, sizzles, chimes, errors |

- File loading tries `.m4a`, `.mp3`, `.caf` extensions in order
- Crossfade: Timer-driven 50ms steps for smooth transitions
- AVAudioSession category: `.playback` with `.mixWithOthers`
- **Music ducking**: `duckMusic(to: 0.15)` reduces volume during minigame intros, `unduckMusic()` restores
- **SFX routing**: `playSFX()` tries `SoundSynthesizer` first, falls back to file-based playback

**Key SFX used**: `"button-tap"`, `"success-chime"`, `"star-reveal"`, `"error-buzz"`, `"slice"`, `"swipe"`, `"pop"`, `"sparkle"`, `"card-flip"`, `"text-blip-0"`, `"text-blip-1"`, `"text-blip-2"`

### SoundSynthesizer (Singleton, `@MainActor`)
Programmatic SFX engine using AVAudioEngine — generates all sounds at init time:

- **Engine**: AVAudioEngine with mixer node at 44100 Hz sample rate
- **Player pool**: 10 pre-allocated AVAudioPlayerNode instances (fire-and-forget)
- **Pre-generated buffers** for all SFX:

| Sound | Generation Method |
|-------|-------------------|
| `"button-tap"` | 800Hz sine, 50ms exponential decay |
| `"success-chime"` | Ascending two-tone C5→E5 |
| `"error-buzz"` | 150Hz square wave |
| `"slice"` | Filtered noise with pitch sweep down |
| `"swipe"` | Breathy noise sweep |
| `"pop"` | 400→100Hz pitch drop sine burst |
| `"sparkle"` | Multiple staggered high tones (shimmer) |
| `"card-flip"` | Filtered noise whoosh |
| `"star-reveal"` | Ascending multi-harmonic chime with shimmer |
| `"text-blip-0/1/2"` | Three pitch variants (380/440/500Hz) for typewriter |

### HapticManager (Singleton, `@MainActor`)
- **Impact**: `light()`, `medium()`, `heavy()` via UIImpactFeedbackGenerator
- **Notification**: `success()`, `error()` via UINotificationFeedbackGenerator

---

## Narrator System

The narrator guides players through both story panels and minigame introductions.

### Components
- **NarratorExpression** (enum in StoryPanel.swift): `happy`, `neutral`, `speak` → image assets
- **DialogueSegment** (struct in StoryPanel.swift): text + per-segment expression
- **NarratorPortraitView**: Animated portrait with breathing + speaking animations
- **Typewriter engine**: Shared pattern in StoryPanelView and MinigameIntroCard

### Behavior
- **During typing**: Shows `speak` expression, y-offset bob animation
- **After typing**: Switches to `happy` expression, breathing animation only
- **Text blips**: Plays randomized `"text-blip-0/1/2"` SFX per non-whitespace character
- **Tap to skip**: Tapping during typewriter reveals full text instantly

### MinigameIntroCard Integration
- Each minigame intro shows 2 dialogue segments:
  1. Cultural fact about the cooking step
  2. Mechanic hint explaining how to play
- "Start" button appears only after all dialogue completes
- Music is ducked during narrator dialogue

---

## Shared UI Components

### GlassContainer (`ViewModifier`)
Frosted glass styling applied via `.glassContainer()`:
- `.ultraThinMaterial` background
- Warm amber border with directional gradient
- Inner glow highlight (top-left bias)
- Outer shadow for depth
- Also `.glassEffect24()` variant for story panel text

### ProgressBarView
- 8 dots connected by lines showing minigame progress
- States: Completed (filled amber + checkmark), Current (pulsing dark), Future (outlined dim)
- Icons per step: flame, star, bubbles, gauge, scissors, slider, stack, leaf

### StarRatingView
- 1-3 gold stars with gradient fill and dual shadows
- Animated reveal: spring scale-in + radiating glow + sparkle particles
- Idle shimmer breathing animation
- Configurable via `earnedStars`, `animated`, `starSize`

### SceneEffects (SKScene Extensions)
Reusable SpriteKit visual effect functions:
- `shakeCamera()`: 4-step horizontal shake
- `flashOverlay()`: Full-screen color flash
- `burstParticles()`: Radial particle burst at position
- `expandingRing()`: Scaling circle outline
- `floatingScoreText()`: "+N" floating labels
- `addAmbientParticles()`: Persistent dust emitter
- `addVignette()`: Edge-darkening overlay
- `addEntranceCurtain()` / `addExitCurtain()`: Fade-in/out overlays

### PhoIngredientIcon
- 8 procedural `Canvas`-based icons (no image assets):
  - Onion (layered semi-circles), Star Anise (8-pointed star), Bone (capsule + knobs), Pot (body + handles + lid), Beef Slice (rect + marbling), Fish Sauce (bottle), Noodles (wavy lines), Herbs (leaf + veins)

---

## Design System

### Color Palette
| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Warm Background | `#140805` | (0.08, 0.05, 0.03) | App background |
| Warm Amber | `#D4A574` | (212, 165, 116) | Primary accent, borders |
| Cream | `#FFF8DC` | (255, 248, 220) | Text, highlights |
| Deep Amber | `~#BF8C59` | (0.75, 0.55, 0.35) | Gradients, darker accents |
| Gold | `#FFD700` | (255, 215, 0) | Stars, celebration |
| Dark Brown | `~#8B2500` | — | Current step indicator |

### Typography
- System `.rounded` font family throughout SwiftUI
- SF Pro Rounded in SpriteKit scenes
- Bold weights for headings, regular/medium for body
- `ViewThatFits` for responsive font size cascading

### Animation Patterns
- **Phase transitions**: Asymmetric (different in vs out) with `.smooth(duration: 0.7, extraBounce: 0.02)`
- **Card reveals**: Spring(response: 0.55, dampingFraction: 0.78) + staggered delays
- **Button pulses**: EaseInOut(1.4s) repeatForever autoreverses
- **Breathing loops**: EaseInOut repeatForever autoreverses for ambient glows
- **Particle effects**: SpriteKit SKEmitterNode for smoke, sparks, confetti
- **Typewriter**: Task-based character-by-character with 25ms delay + text-blip SFX
- **Narrator breathing**: 2.5s scale cycle (1.0→1.02), speaking y-offset (-3px)

---

## Data Flow

```
PhoLifeApp
  └── ContentView (@State gameState: GameState)
        ├── SplashView
        │     └── onComplete → gameState.currentPhase = .story
        ├── StoryView
        │     ├── StoryBackgroundView (Ken Burns images)
        │     ├── StoryPanelView (typewriter + narrator)
        │     │     └── NarratorPortraitView (animated expressions)
        │     └── onComplete → gameState.currentPhase = .minigames
        ├── MinigameContainerView(gameState)
        │     ├── MinigameIntroCard (narrator dialogue + cultural fact)
        │     │     ├── NarratorPortraitView
        │     │     └── duckMusic() → user taps Start → unduckMusic() → phase = .playing
        │     ├── SKScene (SpriteView)
        │     │     └── onComplete(score, stars) → phase = .scoreReveal
        │     └── MinigameScoreCard → user taps Continue
        │           └── gameState.completeMinigame(result)
        │                 ├── appends to minigameResults
        │                 ├── increments currentMinigameIndex
        │                 └── if index == 8 → currentPhase = .completion
        └── CompletionView(gameState)
              └── "Cook Another Bowl" → gameState.resetForReplay()
```

---

## Phase-Based Audio

| Phase | Music | Ambient | Notes |
|-------|-------|---------|-------|
| Splash | "background-music" | — | |
| Story | "background-music" | — | |
| Minigames (intro) | "minigame-music" (ducked to 0.15) | — | Ducked for narrator dialogue |
| Minigames (playing) | "minigame-music" (full volume) | — | Unducked when gameplay starts |
| Minigames (score) | "minigame-music" | — | star-reveal SFX plays |
| Completion | "background-music" | — | |

---

## Key Architectural Patterns

1. **`@Observable` + `@MainActor`**: GameState uses Swift's modern observation for fine-grained reactivity
2. **Feature-based folder structure**: Splash, Story, Minigames, Completion organized independently
3. **Scene factory**: MinigameContainerView switches on index to instantiate correct SKScene
4. **Singleton services**: AudioManager, SoundSynthesizer, and HapticManager for global access
5. **Programmatic audio**: SoundSynthesizer generates all SFX from code (no audio file dependencies for effects)
6. **ViewModifier composition**: GlassContainer for consistent styling across all views
7. **Callback pattern**: SpriteKit scenes communicate results back to SwiftUI via closures
8. **Procedural drawing**: Canvas-based icons avoid external image dependencies
9. **Staggered animation sequencing**: Complex reveal choreography using Task + sleep + withAnimation
10. **Narrator system**: Shared typewriter engine + portrait animations in both Story and Minigame phases
11. **Audio ducking**: Music volume reduced during narrative sections, restored for gameplay
12. **SceneEffects extensions**: Reusable SpriteKit effects (shake, flash, particles, vignette, curtains)

---

## Assets Summary

| Type | Count | Details |
|------|-------|---------|
| Story images | 10 | JPG format in asset catalog (story-panel-1 through 10) |
| Bowl images | 2 | splash-bowl, completion-bowl |
| Narrator portraits | 3 | narratorHappy, narratorNeutral, narratorSpeak (PNG) |
| App icon | 1 | AppIcon.png |
| Music tracks | 2 | background-music.mp3, minigame-music.mp3 |
| Accent color | 1 | Orange system preset |
| Procedural icons | 8 | Canvas-drawn ingredient icons |
| Programmatic SFX | 12 | Generated by SoundSynthesizer (no audio files) |
