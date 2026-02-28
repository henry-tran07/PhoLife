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
│   └── StoryPanel.swift                # 10-panel narrative data
├── Services/
│   ├── AudioManager.swift              # 3-layer audio system (music/ambient/SFX)
│   └── HapticManager.swift             # Impact + notification haptics
├── Features/
│   ├── Splash/
│   │   └── SplashView.swift            # Animated intro (convergence effect)
│   ├── Story/
│   │   ├── StoryView.swift             # Horizontal paging container
│   │   └── StoryPanelView.swift        # Individual panel (typewriter text)
│   ├── Minigames/
│   │   ├── MinigameContainerView.swift # Phase controller (intro → playing → score)
│   │   ├── MinigameIntroCard.swift     # Pre-game overlay
│   │   ├── MinigameScoreCard.swift     # Post-game results overlay
│   │   └── Scenes/
│   │       ├── CharAromaticsScene.swift      # [0] Timing bar game (IMPLEMENTED)
│   │       ├── ToastSpicesScene.swift        # [1] Swipe-catch game (IMPLEMENTED)
│   │       ├── CleanBonesScene.swift         # [2] Placeholder
│   │       ├── SimmerBrothScene.swift        # [3] Placeholder
│   │       ├── SliceBeefScene.swift          # [4] Placeholder
│   │       ├── SeasonBrothScene.swift        # [5] Placeholder
│   │       ├── AssembleBowlScene.swift       # [6] Placeholder
│   │       ├── TopItOffScene.swift           # [7] Placeholder
│   │       └── PlaceholderMinigameScene.swift # Fallback scene
│   ├── Completion/
│   │   └── CompletionView.swift        # Results summary + earned title
│   └── Shared/
│       ├── GlassContainer.swift        # Frosted glass ViewModifier
│       ├── ProgressBarView.swift       # 8-dot step progress
│       ├── StarRatingView.swift        # 1-3 animated gold stars
│       └── PhoIngredientIcon.swift     # 8 procedural Canvas icons
└── Resources/
    ├── Assets.xcassets/                # Images + colors
    │   ├── AppIcon.appiconset/
    │   ├── AccentColor.colorset/       # Orange
    │   ├── splash-bowl.imageset/
    │   ├── completion-bowl.imageset/
    │   └── story-panel-1 through 10.imageset/  # 10 JPG story images
    └── Sounds/
        └── Music/
            └── background-music.mp3
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

### Phase 2: Story (`StoryView` + `StoryPanelView`)
- Horizontal `ScrollView` with `.scrollTargetBehavior(.paging)`
- 10 panels telling pho's history (pre-colonial → modern diaspora)
- Each panel: background image with Ken Burns zoom (1.08x over 8s)
- Body text uses typewriter effect (25ms per character)
- Final panel shows "Let's Cook" CTA button
- Progress dots overlay at bottom

### Phase 3: Minigames (`MinigameContainerView`)
- Orchestrates 8 SpriteKit minigames with 3 sub-phases each:
  - **Intro card** → **Playing** (SpriteKit scene) → **Score reveal**
- Scene factory pattern instantiates correct SKScene by index
- Fixed scene size: 1194×834 with `.aspectFill` scaling
- Dynamic blur (0/3/4 pts) applied to scene during overlays
- ProgressBarView shows 8-step progress at top
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

### MinigameResult
- `id: UUID`, `minigameIndex: Int`, `stars: Int` (1-3), `score: Int`

### StoryPanel
- 10 static panels with `id`, `title`, `bodyText`, `imageName`, `ambientAudioFile`

### PhoIngredient
- 8 ingredients: onion, star anise, bone, pot, beef slice, fish sauce, noodles, herbs
- Each has `name`, `contribution` text, `icon: PhoIngredientIcon` enum

### CulturalFact
- 8 facts paired 1:1 with minigames
- Each has `stepTitle`, `description`, `mechanicHint`, `culturalNote`

---

## Minigame Scenes (SpriteKit)

### Implementation Status

| # | Scene | Mechanic | Status |
|---|-------|----------|--------|
| 0 | CharAromaticsScene | Timing bar — tap when cursor hits golden zone | **Fully implemented** |
| 1 | ToastSpicesScene | Swipe-catch falling spices over 40s | **Fully implemented** |
| 2 | CleanBonesScene | Bubble tapping | **Placeholder** (auto 85pts, 2★ after 1.5s) |
| 3 | SimmerBrothScene | Heat gauge control | **Placeholder** |
| 4 | SliceBeefScene | Precision slicing | **Placeholder** |
| 5 | SeasonBrothScene | Slider balancing | **Placeholder** |
| 6 | AssembleBowlScene | Layer sequencing | **Placeholder** |
| 7 | TopItOffScene | Card matching | **Placeholder** |

### CharAromaticsScene (Minigame 0) — Detailed
- **4 rounds**: 2 onions + 2 ginger slices charred on a skillet
- **Timing bar**: Left-right oscillating cursor, tap to release
- **Difficulty ramp**: Target zone shrinks (18% → 12%), cursor speed increases (0.55 → 0.79)
- **Scoring**: Perfect (within 9% of center) = 3pts, Good (within 18%) = 2pts, Miss = 1pt
- **Score formula**: `Int((totalPoints / 12.0) * 100)`, stars: ≥10=3★, ≥7=2★, else 1★
- **Visual layers**: Floor glow (-10) → skillet (0.5-2) → ingredient (2) → smoke (3) → timing bar (9.5-12) → feedback (15) → particles (85) → curtains (500)
- **Effects**: Particle bursts, expanding rings, golden flash, ingredient color darkening, grill marks

### ToastSpicesScene (Minigame 1) — Detailed
- **40-second timer** with 10 spice types (5 correct, 5 decoys)
- **Falling arcs**: Spices spawn from top in parabolic arcs, player swipes to catch
- **Difficulty ramp**: Spawn interval decreases (1.5s → 0.8s), correct probability decreases (60% → 50%)
- **Scoring**: +2 per correct catch, -1 per wrong catch; combo tracking (displayed at ≥2)
- **Score formula**: `max(0, correctCatches * 20 - wrongCatches * 10)`
- **Stars**: ≥5 correct = 3★, ≥4 = 2★, else 1★
- **Effects**: Golden expanding rings for correct, red X + shake for wrong

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

**Key SFX used**: `"button-tap"`, `"sizzle"`, `"success-chime"`, `"star-reveal"`, `"error-buzz"`

### HapticManager (Singleton, `@MainActor`)
- **Impact**: `light()`, `medium()`, `heavy()` via UIImpactFeedbackGenerator
- **Notification**: `success()`, `error()` via UINotificationFeedbackGenerator

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
- **Typewriter**: Task-based character-by-character with 25ms delay

---

## Data Flow

```
PhoLifeApp
  └── ContentView (@State gameState: GameState)
        ├── SplashView
        │     └── onComplete → gameState.currentPhase = .story
        ├── StoryView
        │     └── onComplete → gameState.currentPhase = .minigames
        ├── MinigameContainerView(gameState)
        │     ├── MinigameIntroCard → user taps Start → phase = .playing
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

| Phase | Music | Ambient |
|-------|-------|---------|
| Splash | "background-music" | — |
| Story | "background-music" | — |
| Minigames (intro/score) | "background-music" | — |
| Minigames (playing) | "background-music" | "kitchen-ambient" |
| Completion | "background-music" | — |

---

## Key Architectural Patterns

1. **`@Observable` + `@MainActor`**: GameState uses Swift's modern observation for fine-grained reactivity
2. **Feature-based folder structure**: Splash, Story, Minigames, Completion organized independently
3. **Scene factory**: MinigameContainerView switches on index to instantiate correct SKScene
4. **Singleton services**: AudioManager and HapticManager for global access
5. **ViewModifier composition**: GlassContainer for consistent styling across all views
6. **Callback pattern**: SpriteKit scenes communicate results back to SwiftUI via closures
7. **Procedural drawing**: Canvas-based icons avoid external image dependencies
8. **Staggered animation sequencing**: Complex reveal choreography using Task + sleep + withAnimation

---

## Assets Summary

| Type | Count | Details |
|------|-------|---------|
| Story images | 10 | JPG format in asset catalog (story-panel-1 through 10) |
| Bowl images | 2 | splash-bowl, completion-bowl |
| App icon | 1 | AppIcon.png |
| Music | 1 | background-music.mp3 |
| Accent color | 1 | Orange system preset |
| Procedural icons | 8 | Canvas-drawn ingredient icons |
