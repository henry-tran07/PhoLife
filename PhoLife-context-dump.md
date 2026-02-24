# PhoLife — Full Context Dump

## Project Overview

**What:** PhoLife is an iPad-exclusive educational game about Vietnamese pho for the **Apple Swift Student Challenge 2026**. It combines cinematic visual storytelling (10 illustrated narrative panels) with 8 arcade-style minigames that teach authentic pho cooking, culminating in a completion screen with scoring and cultural facts.

**Deadline:** February 28, 2026, 11:59 PM PST

**Developer:** Henry

**Current State:** All 28 Swift files compile and the app runs on iPad Pro 13-inch (M5) simulator. Full flow: Splash -> Story -> 8 Minigames -> Completion is wired and functional with placeholder art.

---

## Constraints

| Constraint | Detail |
|---|---|
| Format | `.swiftpm` App Playground (NOT .xcodeproj) |
| Platform | iPad-only, iOS 26+, landscape-locked |
| Size limit | 25 MB ZIP |
| Offline | Zero network calls at runtime |
| Frameworks | SwiftUI + SpriteKit + AVFoundation only (no external deps) |
| Concurrency | Swift 6 strict concurrency (`@MainActor` on all observable classes) |

---

## Build & Run Configuration

| Setting | Value |
|---|---|
| Workspace | `PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace` |
| Scheme | `PhoLife` |
| Simulator | iPad Pro 13-inch (M5) |
| Simulator ID | `C7059300-23FE-4962-80BE-0E9ED1AC3462` |
| Bundle ID | `com.henrytran.PhoLife` |
| DerivedData App | `/Users/henryct/Library/Developer/Xcode/DerivedData/PhoLife-dcvtgpnshrpuhkedczltdsgonkhq/Build/Products/Debug-iphonesimulator/PhoLife.app` |

**Build command:** `build_sim` via XcodeBuildMCP (or `xcodebuild` against the workspace)

**Known build warning:** `warning: Skipping duplicate build file in Compile Sources build phase: .../Resources/Assets.xcassets` (harmless)

**Known quirk:** `build_run_sim` has trouble finding the app path for `.swiftpm` projects. Workaround: use `xcrun simctl install` + `launch_app_sim` manually.

---

## Architecture

### Navigation: Enum-Driven Phase Machine

```
ContentView (ZStack, switches on gameState.currentPhase)
  |-- .splash    -> SplashView (auto-advances after 3.5s animation)
  |-- .story     -> StoryView (10 panels, horizontal paging, "Skip to Cook")
  |-- .minigames -> MinigameContainerView (wraps SpriteView + overlays)
  |-- .completion -> CompletionView (bowl reveal, score, facts carousel, replay)
```

No NavigationStack. Linear flow with animated ZStack transitions.

### State: @Observable MVVM

- `GameState` -- central `@Observable @MainActor` class owning: current phase, current minigame index, results array, total stars, earned title
- Created as `@State` in ContentView, passed down as plain parameter
- `MinigameResult` -- per-game struct: stars (1-3), score
- `StoryPanel` -- static data for 10 narrative panels
- `CulturalFact` -- static data for 8 facts (one per minigame)

### SpriteKit-SwiftUI Integration

- Each minigame is an `SKScene` subclass displayed via `SpriteView`
- Scene communicates completion back via closure: `var onComplete: ((Int, Int) -> Void)?`
- `MinigameContainerView` manages lifecycle: intro card -> playing -> score card -> advance
- **CRITICAL:** All non-interactive SwiftUI overlays on SpriteView must have `.allowsHitTesting(false)` (without this, touches never reach SpriteKit)
- Scene size: `1194 x 834` (iPad Pro 11-inch logical), `scaleMode = .aspectFill`
- `.id(gameState.currentMinigameIndex)` on SpriteView to force recreation when switching games
- Only ONE SpriteView instance at a time

### Audio: 3-Layer System (STUB - not yet implemented)

- `AudioManager` singleton with AVFoundation
- Layer 1: Music (looping, crossfade between phases)
- Layer 2: Ambient (per-scene loops, crossfade on transition)
- Layer 3: SFX (fire-and-forget pool, max 8 concurrent)
- Currently all methods are empty stubs

---

## Project File Structure

```
PhoLife/
|-- .env                                    # Gemini API key (NOT committed)
|-- .gitignore
|-- CLAUDE.md                               # Build/run instructions for Claude Code
|-- PhoLife-prd.md                          # Product Requirements Document (565 lines)
|-- PhoLife-implementation-plan.md          # Full implementation plan
|-- PhoLife-context-dump.md                 # THIS FILE
|
|-- PhoLife.swiftpm/                        # Submission root
    |-- Package.swift                       # SPM manifest with AppleProductTypes
    |-- .swiftpm/xcode/package.xcworkspace/ # Xcode workspace glue
    |-- PhoLifeApp.swift                    # @main entry point
    |-- ContentView.swift                   # Phase router (ZStack switch)
    |
    |-- Models/
    |   |-- GameState.swift                 # Central @Observable state
    |   |-- MinigameResult.swift            # Per-game result struct
    |   |-- StoryPanel.swift                # Static panel data (10 panels)
    |   |-- CulturalFact.swift              # Static fact data (8 facts)
    |
    |-- Features/
    |   |-- Splash/
    |   |   |-- SplashView.swift            # Animated splash, auto-advances 3.5s
    |   |
    |   |-- Story/
    |   |   |-- StoryView.swift             # Horizontal paging TabView container
    |   |   |-- StoryPanelView.swift        # Single panel with placeholder image
    |   |
    |   |-- Minigames/
    |   |   |-- MinigameContainerView.swift  # SpriteView wrapper + overlays (KEY FILE)
    |   |   |-- MinigameIntroCard.swift      # Recipe card overlay before each game
    |   |   |-- MinigameScoreCard.swift      # Stars + cultural fact after each game
    |   |   |-- Scenes/
    |   |       |-- PlaceholderMinigameScene.swift  # Fallback (tap to complete)
    |   |       |-- CharAromaticsScene.swift        # Game 1: Hold-release timing
    |   |       |-- ToastSpicesScene.swift           # Game 2: Swipe-to-catch
    |   |       |-- CleanBonesScene.swift            # Game 3: Tap bubbles
    |   |       |-- SimmerBrothScene.swift           # Game 4: Zone keeper
    |   |       |-- SliceBeefScene.swift             # Game 5: Precision swipe
    |   |       |-- SeasonBrothScene.swift           # Game 6: Slider mixing
    |   |       |-- AssembleBowlScene.swift          # Game 7: Drop stacking (1353 lines)
    |   |       |-- TopItOffScene.swift              # Game 8: Memory match
    |   |
    |   |-- Completion/
    |   |   |-- CompletionView.swift        # Bowl reveal, score, facts, replay
    |   |
    |   |-- Shared/
    |       |-- ProgressBarView.swift       # 8-step minigame timeline dots
    |       |-- StarRatingView.swift        # 1-3 star display with animation
    |       |-- GlassContainer.swift        # Liquid Glass modifier (iOS 26+)
    |
    |-- Services/
    |   |-- AudioManager.swift              # STUB - empty methods, needs implementation
    |   |-- HapticManager.swift             # UIKit haptic feedback wrapper
    |
    |-- Resources/
        |-- Assets.xcassets/                # Images (currently empty)
        |-- Sounds/                         # Audio files (currently empty)
        |-- Data/                           # JSON data (currently empty)
```

**Total: 28 Swift files, all compiling successfully.**

---

## File Details

### Package.swift
- swift-tools-version: 6.0
- Uses `AppleProductTypes` for `.iOSApplication` product
- iPad-only (`supportedDeviceFamilies: [.pad]`)
- Landscape-locked (`supportedInterfaceOrientations: [.landscapeRight, .landscapeLeft]`)
- iOS 26.0+
- Bundle ID: `com.henrytran.PhoLife`
- `path: "."` -- all Swift files under .swiftpm root are compiled
- Resources: `.process("Resources/Sounds")`, `.process("Resources/Data")`
- `Assets.xcassets` auto-processed by SPM

### PhoLifeApp.swift (13 lines)
- `@main` entry point
- Dark mode forced: `.preferredColorScheme(.dark)`
- System overlays hidden: `.persistentSystemOverlays(.hidden)`

### ContentView.swift (33 lines)
- `@State private var gameState = GameState()`
- ZStack switch on `gameState.currentPhase`
- Phase transitions animated with `.easeInOut(duration: 0.6)`
- `.ignoresSafeArea()` and `.statusBarHidden(true)`

### GameState.swift (66 lines)
- `@Observable @MainActor final class`
- `AppPhase` enum: `.splash`, `.story`, `.minigames`, `.completion`
- Properties: `currentPhase`, `currentMinigameIndex`, `minigameResults`, `hasSeenStory`
- Computed: `totalStars` (sum of all result stars), `earnedTitle` (4 tiers: "Street Food Curious" through "Pho Master")
- Methods: `completeMinigame(result:)` (appends result, advances index or goes to completion), `resetForReplay()` (resets to minigames, skips story), `skipToMinigames()`

### MinigameResult.swift (9 lines)
- Simple struct: `id` (UUID), `minigameIndex`, `stars` (1-3), `score`

### StoryPanel.swift (83 lines)
- Struct: `id`, `title`, `bodyText`, `imageName`, `ambientAudioFile`
- 10 panels telling the history of pho:
  1. "Every great bowl has a story."
  2. "Before it had a name" (Red River villages)
  3. "Where worlds collided" (French influence)
  4. "Alchemy in a pot" (charred aromatics, toasted spices)
  5. "The streets came alive" (Hanoi mornings)
  6. "A country divided" (1954, North vs South pho)
  7. "Carried across oceans" (post-1975 diaspora)
  8. "New roots" (Houston, Sydney, Paris, San Jose)
  9. "More than soup" (cultural significance)
  10. "Your turn" (transition to cooking)

### CulturalFact.swift (50 lines)
- Struct: `id`, `minigameTitle`, `fact`
- 8 facts, one per minigame, shown on score cards after each game

### SplashView.swift (64 lines)
- Staggered fade-in animation: bowl emoji -> "PhoLife" title (warm amber) -> subtitle
- Auto-advances to story after 3.5 seconds via `Task.sleep`
- Warm dark background (#140D08)

### StoryView.swift (86 lines)
- `TabView` with `.page(indexDisplayMode: .never)` for horizontal paging
- "Skip to Cook" button always visible (top-right, glass container)
- Page indicator dots at bottom
- "Let's Cook" CTA button on final panel (id=10)
- Tracks `currentIndex` starting at 1

### StoryPanelView.swift (72 lines)
- Placeholder image area (dark rounded rectangle showing `imageName`)
- Title at top in glass container
- Body text at bottom in glass container
- Text fades in on appear

### MinigameContainerView.swift (141 lines) -- KEY FILE
- **Routes to correct scene** via switch on `gameState.currentMinigameIndex`:
  - 0: CharAromaticsScene
  - 1: ToastSpicesScene
  - 2: CleanBonesScene
  - 3: SimmerBrothScene
  - 4: SliceBeefScene
  - 5: SeasonBrothScene
  - 6: AssembleBowlScene
  - 7: TopItOffScene
  - default: PlaceholderMinigameScene
- Manages 3-phase lifecycle: `.intro` -> `.playing` -> `.scoreReveal`
- ProgressBarView overlay with `.allowsHitTesting(false)` (CRITICAL)
- SpriteView with `.id(gameState.currentMinigameIndex)` for forced recreation
- Scene size: `CGSize(width: 1194, height: 834)`, `.scaleMode = .aspectFill`

### MinigameIntroCard.swift (113 lines)
- Dimmed background overlay
- Glass container card with: minigame title, cooking step description, mechanic hint, "Start" button
- 8 hardcoded descriptions and 8 mechanic hints
- Safe array subscript extension

### MinigameScoreCard.swift (81 lines)
- Dimmed background overlay
- Glass container card with: animated star rating, score text, cultural fact, "Continue" button

### CompletionView.swift (127 lines)
- Bowl emoji, "Your Bowl is Ready!" title
- Overall star rating (3 stars if >21 total, 2 if >15, else 1)
- Total stars out of 24
- Earned title
- Horizontal scrolling facts carousel (all 8 cultural facts in glass containers)
- "Cook Another Bowl" replay button -> `gameState.resetForReplay()`

### ProgressBarView.swift (102 lines)
- Horizontal row of 8 numbered dots
- Completed: warm amber (#D4A574), Current: deep red (#8B2500) with shadow, Future: outlined
- Glass container background

### StarRatingView.swift (100 lines)
- 1-3 star display using SF Symbol `star.fill` / `star`
- Optional sequential scale-in animation with spring physics

### GlassContainer.swift (34 lines)
- `ViewModifier` using `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))` on iOS 26+
- Fallback to `.ultraThinMaterial` on earlier versions
- Extension: `view.glassContainer()`

### AudioManager.swift (47 lines) -- STUB
- `@Observable @MainActor` singleton
- Methods: `playMusic(_:fadeDuration:)`, `stopMusic(fadeDuration:)`, `playAmbient(_:fadeDuration:)`, `stopAmbient(fadeDuration:)`, `playSFX(_:)`, `stopAll(fadeDuration:)`
- **ALL METHODS ARE EMPTY** -- needs AVFoundation implementation

### HapticManager.swift (58 lines)
- `@MainActor` singleton using `import UIKit`
- Methods: `light()`, `medium()`, `heavy()` (UIImpactFeedbackGenerator), `success()`, `error()` (UINotificationFeedbackGenerator)

---

## The 8 Minigames -- Implementation Details

All scenes are `SKScene` subclasses with `var onComplete: ((Int, Int) -> Void)?` callback.

### Game 1: Char the Aromatics (CharAromaticsScene.swift, 603 lines)
- **Mechanic:** Hold-release power meter timing
- **Gameplay:** Power meter fills while touching. Release in green zone = perfect char. 4 rounds (2 onions + 2 ginger). Green zone narrows each round.
- **Visuals:** Skillet with ingredient (ellipse for onion with concentric rings, rounded rect for ginger), power meter on right side with color-coded zones (blue/raw -> yellow -> green -> yellow -> red/burned), programmatic smoke particles that increase with heat, progressive ingredient darkening via color blending
- **Scoring:** Green zone = 3pts, yellow = 2pts, raw/burned = 1pt. Total out of 12. Stars: 10+ = 3, 7+ = 2, else 1
- **Duration:** 4 rounds, self-paced

### Game 2: Toast the Spices (ToastSpicesScene.swift, 630 lines)
- **Mechanic:** Swipe-to-catch (Fruit Ninja style)
- **Gameplay:** 5 correct spices (Star Anise, Cinnamon, Cardamom, Cloves, Coriander) + 5 decoys fly upward in arcs. Swipe across correct ones. 3 wrong = game ends early.
- **Visuals:** Warm kitchen background, colored circles for spices (warm brown for correct, reddish for decoy), golden particle burst on correct catch, red flash + X mark on wrong, swipe trail with glow, screen flash on wrong
- **Scoring:** +2 per correct, -1 per wrong. Stars: 5+ correct & 0 wrong = 3, 4+ & <=1 wrong = 2, else 1
- **Duration:** 30 seconds, spawn rate increases from ~1.5s to ~0.8s

### Game 3: Clean the Bones (CleanBonesScene.swift, 489 lines)
- **Mechanic:** Whack-a-Mole tap bubbles
- **Gameplay:** Overhead view of pot. Scum bubbles rise from bottom. Tap to pop. Spawn rate increases over time. Water transitions murky -> clear as score rises. Multi-touch enabled.
- **Visuals:** Elliptical pot with 3D rim effect, murky water overlay that clears with progress, semi-transparent yellowish-brown bubbles with glow and specular highlight, wobble + pulse animation, pop particle splatter, steam wisps above pot
- **Scoring:** Percentage of bubbles popped. Stars: 90%+ = 3, 70%+ = 2, else 1
- **Duration:** 25 seconds

### Game 4: Simmer the Broth (SimmerBrothScene.swift, 970 lines)
- **Mechanic:** Zone keeper (Flappy Bird style)
- **Gameplay:** Side view of pot on stove. Touch = raise flame/temperature, release = lower. Keep temperature indicator in narrowing "simmer" zone. Random gusts perturb temperature.
- **Visuals:** Temperature gauge on left with color-coded bands, stove with pot and rim, animated triangular flames (blue pilot light -> orange -> red), broth surface color changes, bubble emitter (gentle at simmer, aggressive when boiling), steam emitter, wind arrow warning indicator for gusts
- **Scoring:** Score = time-in-zone / total-time * 100. Stars: 80%+ = 3, 65%+ = 2, else 1
- **Duration:** 25 seconds. Simmer zone narrows: starts 0.40-0.65, ends 0.45-0.60. Gusts every 3-6 seconds.

### Game 5: Slice the Beef (SliceBeefScene.swift, 525 lines)
- **Mechanic:** Precision horizontal swipes
- **Gameplay:** Cutting board with beef block. Horizontal swipes slice. Score based on thickness consistency (deviation from ideal 12% spacing). Slices fan out to the right. 8 slices per round.
- **Visuals:** Wooden cutting board with grain lines, deep red beef block with marbling detail, white cut flash with glow, sliced pieces fan out with slight rotation, quality feedback ("Perfect!", "Good", "Uneven")
- **Scoring:** Perfect (<=15% deviation) = 3pts, Good (<=30%) = 2pts, Uneven = 1pt. Total out of 24. Stars: 20+ = 3, 14+ = 2, else 1
- **Duration:** Self-paced, 8 slices

### Game 6: Season the Broth (SeasonBrothScene.swift, 797 lines)
- **Mechanic:** 3-slider balancing
- **Gameplay:** 3 draggable sliders (Fish Sauce target 60%, Salt target 40%, Sugar target 20%). Bowl color shifts in real-time based on slider values. "Taste" button to confirm. 3 attempts, best score counts. Perfect score (100) ends game early.
- **Visuals:** Broth bowl with rim and glow that changes color (golden = balanced, dark = too much fish sauce, washed out = too much salt, orange = too much sugar), harmony arc meter (semicircle, green/yellow/red), colored slider tracks with thumb nodes, celebratory particles on good scores
- **Scoring:** Error < 0.15 = 100 (3 stars), < 0.3 = 75 (2 stars), < 0.5 = 50 (1 star), else 25 (1 star)
- **Duration:** Up to 3 attempts, self-paced

### Game 7: Assemble the Bowl (AssembleBowlScene.swift, 1353 lines)
- **Mechanic:** Drop-stacking with correct ordering
- **Gameplay:** Ingredients hover above bowl as tappable cards. Must tap in correct order: Noodles -> Brisket -> Raw Beef -> Broth. Wrong order = shake + penalty. Hero moment: broth pour is cinematic with golden stream, massive steam burst, and raw beef changing red -> pink.
- **Visuals:** Large bowl with layered ingredient visualization, ingredient cards with custom icons (noodle swirls, brisket slices, raw beef pieces, broth droplet), drop animation into bowl, hero broth pour with golden stream particles and screen flash, celebration particles, "step X of 4" HUD
- **Scoring:** First try = 3pts per step, 2nd attempt = 2pts, 3+ = 1pt. Total out of 12. Stars: 10+ = 3, 7+ = 2, else 1
- **Duration:** Self-paced, 4 steps

### Game 8: Top It Off (TopItOffScene.swift, 593 lines)
- **Mechanic:** Card flip memory match
- **Gameplay:** 12 cards (6 pairs). Heterogeneous matching: topping name+emoji <-> role description. Flip two cards; if same pairID but different type = match. Score by flip efficiency.
- **Visuals:** 4x3 card grid with entrance stagger animation, card backs with decorative diamond pattern and bowl icon, front faces with emoji+name (toppings) or sparkle+quote (roles), flip animation via scaleX, golden glow outline on matches, sparkle particles, celebratory wave on completion
- **Pairs:** Bean Sprouts/Crunch & Freshness, Thai Basil/Aromatic Sweetness, Cilantro/Bright Herbiness, Lime/Acidity & Brightness, Hoisin/Rich Sweetness, Sriracha/Heat & Kick
- **Scoring:** Score = max(0, 100 - (flips - 12) * 5). Stars: <=12 flips = 3, <=18 = 2, else 1

---

## Bugs Fixed During Development

1. **GlassContainer `.interactive` error**: `Member 'interactive' is a function that produces expected type 'Glass'` -> Fixed by adding parentheses: `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))`

2. **HapticManager import**: `import SwiftUI` doesn't export UIKit haptic types (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`). Must use `import UIKit`.

3. **`@escaping` on stored properties**: MinigameIntroCard `let onStart: @escaping () -> Void` and MinigameScoreCard `let onContinue: @escaping () -> Void` -> Removed `@escaping` (only valid on function parameters, not stored properties).

4. **Closure type inference in MinigameContainerView**: `scene.onComplete = { score, stars in` -> Added explicit types: `{ (score: Int, stars: Int) in`

5. **`isMultipleTouchEnabled` in CleanBonesScene**: `cannot find 'isMultipleTouchEnabled' in scope` -> Changed to `view.isMultipleTouchEnabled = true` (it's a property of SKView, not SKScene)

6. **Simulator name**: "iPad Pro 13-inch (M4)" didn't exist -> Changed to "iPad Pro 13-inch (M5)"

7. **SourceKit false positives**: Many "Cannot find type" errors (UITouch, UIEvent, HapticManager, GameState, etc.) were SourceKit indexing issues in `.swiftpm` projects, NOT real compiler errors. Always verify with actual `build_sim` builds.

8. **`build_run_sim` app path issue**: XcodeBuildMCP couldn't find app path for `.swiftpm` projects -> Workaround: manually `xcrun simctl install` + `launch_app_sim`

---

## Key Design Patterns

### Color Palette
- Warm background: `Color(red: 0.08, green: 0.05, blue: 0.03)` (#140D08)
- Warm amber: `Color(red: 212/255, green: 165/255, blue: 116/255)` (#D4A574)
- Cream: `Color(red: 1.0, green: 248/255, blue: 220/255)` (#FFF8DC)
- Deep red (current step): `Color(red: 0x8B/255, green: 0x25/255, blue: 0x00/255)` (#8B2500)

### Common Scene Structure
Every SpriteKit minigame scene follows this pattern:
```swift
class FooScene: SKScene {
    var onComplete: ((Int, Int) -> Void)?
    // Game state vars
    // Node references

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(...)
        // Setup nodes
        // Start game
    }

    override func update(_ currentTime: TimeInterval) {
        // Game loop: timing, spawning, physics
    }

    override func touchesBegan/touchesMoved/touchesEnded(...)  {
        // Input handling
    }

    private func endGame() {
        // Calculate score and stars
        // Show "Time's Up!" / "Complete!" label
        // Wait, then call onComplete?(score, stars)
    }
}
```

### Star Calculation Convention
- 90%+ = 3 stars
- 70-89% = 2 stars
- <70% = 1 star
- Always at least 1 star (no hard blocking)

---

## Remaining Work (Not Yet Started)

### Critical Path
1. **Real AudioManager implementation** -- AVFoundation with crossfading, music/ambient/SFX playback (currently empty stubs)
2. **Story panel images** -- Generate 10 images via `/nano-banana-pro` skill
3. **Minigame background/sprite images** -- Generate via `/nano-banana-pro`
4. **Splash/completion bowl images** -- Generate via `/nano-banana-pro`

### Polish
5. **SplashView enhancement** -- Add SpriteKit steam particles, better entrance animation
6. **StoryPanelView parallax** -- Zoom/pan animation on single oversized image
7. **CompletionView enhancement** -- Bowl reveal animation with particles
8. **Transition animations** -- Between phases and minigames
9. **Liquid Glass polish** -- Apply `.glassContainer()` more consistently

### Quality
10. **Accessibility pass** -- VoiceOver labels on all interactive elements
11. **App icon** -- Generate via `/nano-banana-pro`
12. **ZIP size verification** -- Verify <= 25 MB after assets added
13. **Full playthrough testing** -- All 8 minigames completable, replay works
14. **Cold launch test** -- Kill and relaunch app

### Submission
15. **Audio sourcing** -- Royalty-free music (3 tracks), ambient loops (5), SFX (~30) from freesound.org/mixkit.co
16. **Wire audio into all scenes and phases**
17. **Submission essay** -- 500 words
18. **AI disclosure documentation**
19. **Final ZIP export and submit**

---

## Image Generation Strategy

- Use `/nano-banana-pro` Claude Code skill for all images
- **Style prompt prefix:** "Warm hand-painted watercolor illustration, Vietnamese food and culture theme, soft atmospheric lighting, muted earth tones with warm amber and golden highlights."
- Generate all story panels in one session for style consistency
- 10 story panels at 1K resolution (~200KB each = ~2 MB)
- 8 minigame backgrounds (~150KB each = ~1.2 MB)
- ~40 sprite assets (~30KB each = ~1.2 MB)
- Splash + completion bowl images (~200KB each = ~0.4 MB)

### Asset Budget
| Category | Estimated |
|---|---|
| Story panel images | ~2 MB |
| Minigame art | ~2.8 MB |
| Music | ~2.4 MB |
| Ambient + SFX | ~1.9 MB |
| Code + metadata | ~0.5 MB |
| **Total** | **~9.6 MB** |
| **Headroom** | **~15.4 MB** |

---

## Orchestration Notes

- The user explicitly instructed: **"you are the orchestrator, do not write any code yourself and delegate tasks to teammates"**
- All code was written by delegated teammate agents running in parallel
- Day 1: 3 parallel agents (project scaffold, core views + models, services + shared UI) + 3 more (fix errors + create missing views)
- Day 2: 4 parallel agents (CleanBones, TopItOff, CharAromatics, ToastSpices)
- Day 3: 5 parallel agents (wire scenes, SliceBeef, SeasonBroth, SimmerBroth, AssembleBowl)
- Two agents hit API rate limits on Day 3 (SimmerBroth, AssembleBowl) but files were written before limits hit
- All 28 files compile as verified by `build_sim`
