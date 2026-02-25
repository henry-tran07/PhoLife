# PhoLife — Implementation Plan
## Apple Swift Student Challenge 2026

**Deadline:** February 28, 2026, 11:59 PM PST
**Current State:** Zero code. PRD complete. Git repo initialized.
**Prior Art:** Previous project (same tech stack, key learnings below)

---

## 1. What We're Building

An iPad-exclusive educational game about Vietnamese phở: 10 cinematic story panels followed by 8 arcade-style minigames teaching authentic phở cooking, culminating in a score/completion screen. Feels like a polished indie game, not a school project.

```
SPLASH → STORY (10 panels) → MINIGAMES (8 games) → COMPLETION
```

---

## 2. Hard Constraints

| Constraint | Detail |
|---|---|
| Format | `.swiftpm` App Playground (NOT .xcodeproj) |
| Platform | iPad-only, iOS 26+, landscape-locked |
| Size limit | ≤ 25 MB ZIP |
| Offline | Zero network calls at runtime |
| Frameworks | SwiftUI + SpriteKit + AVFoundation only (no external deps) |
| Concurrency | Swift 6 strict concurrency (`@MainActor` on all observable classes) |

---

## 3. Architecture

### 3.1 Navigation: Enum-Driven Phase Machine

```
ContentView (ZStack, switches on gameState.currentPhase)
  ├── .splash     → SplashView (auto-advances after animation)
  ├── .story      → StoryView (10 panels, horizontal paging, "Skip to Cook")
  ├── .minigames  → MinigameContainerView (wraps SpriteView + overlays)
  └── .completion  → CompletionView (bowl reveal, score, facts carousel, replay)
```

No NavigationStack. Linear flow with animated ZStack transitions.

### 3.2 State: @Observable MVVM

- `GameState` — central `@Observable @MainActor` class: current phase, current minigame index, results array, total stars, earned title
- Created as `@State` in ContentView, passed down as plain parameter
- `MinigameResult` — per-game struct (stars 1-3, score, cultural fact)
- `StoryPanel` — static data model for 10 narrative panels
- `CulturalFact` — static data model for 8 facts

### 3.3 SpriteKit ↔ SwiftUI Integration

- Each minigame is an `SKScene` subclass displayed via `SpriteView`
- Scene communicates completion via closure: `var onComplete: ((Int, Int) -> Void)?`
- `MinigameContainerView` manages lifecycle: intro card → playing → score card → advance
- **CRITICAL:** All non-interactive SwiftUI overlays on SpriteView MUST have `.allowsHitTesting(false)` (without this, touches never reach SpriteKit)
- Scene size: `1194 × 834` (iPad Pro 11-inch logical), `scaleMode = .aspectFill`
- Only ONE SpriteView instance at a time
- Use `.id(currentMinigameIndex)` to control SpriteView recreation when switching games

### 3.4 Audio: 3-Layer System

`AudioManager` singleton with AVFoundation:
- **Layer 1 — Music:** Looping tracks, crossfade between phases
- **Layer 2 — Ambient:** Per-scene loops, crossfade on transition
- **Layer 3 — SFX:** Fire-and-forget pool, max 8 concurrent players

---

## 4. Project Structure

```
PhoLife.swiftpm/                          ← Submission root
├── Package.swift                          ← SPM manifest with AppleProductTypes
├── .swiftpm/xcode/package.xcworkspace/    ← Xcode workspace glue
├── PhoLifeApp.swift                       ← @main entry point
├── ContentView.swift                      ← Phase router (ZStack switch)
│
├── Models/
│   ├── GameState.swift                    ← Central @Observable state
│   ├── MinigameResult.swift
│   ├── StoryPanel.swift
│   └── CulturalFact.swift
│
├── Features/
│   ├── Splash/
│   │   └── SplashView.swift
│   ├── Story/
│   │   ├── StoryView.swift                ← Horizontal paging container
│   │   └── StoryPanelView.swift           ← Single panel with parallax
│   ├── Minigames/
│   │   ├── MinigameContainerView.swift    ← SpriteView wrapper + overlays
│   │   ├── MinigameIntroCard.swift        ← Recipe card overlay
│   │   ├── MinigameScoreCard.swift        ← Stars + cultural fact overlay
│   │   ├── Shared/
│   │   │   ├── ParticleFactory.swift      ← Reusable particle emitters
│   │   │   └── ScoreAnimator.swift        ← Floating "+1", "Perfect!" popups
│   │   └── Scenes/
│   │       ├── CharAromaticsScene.swift   ← Game 1: Hold-release timing
│   │       ├── ToastSpicesScene.swift     ← Game 2: Swipe-to-catch
│   │       ├── CleanBonesScene.swift      ← Game 3: Tap bubbles
│   │       ├── SimmerBrothScene.swift     ← Game 4: Zone keeper
│   │       ├── SliceBeefScene.swift       ← Game 5: Precision swipe
│   │       ├── SeasonBrothScene.swift     ← Game 6: Slider mixing
│   │       ├── AssembleBowlScene.swift    ← Game 7: Drop stacking
│   │       └── TopItOffScene.swift        ← Game 8: Memory match
│   ├── Completion/
│   │   └── CompletionView.swift
│   └── Shared/
│       ├── ProgressBarView.swift          ← 8-step minigame timeline
│       ├── StarRatingView.swift
│       └── GlassContainer.swift           ← Liquid Glass modifier
│
├── Services/
│   ├── AudioManager.swift
│   └── HapticManager.swift
│
└── Resources/
    ├── Assets.xcassets/                   ← Images (auto-processed by SPM)
    ├── Sounds/                            ← Audio files (.m4a)
    │   ├── Music/
    │   ├── Ambient/
    │   └── SFX/
    └── Data/
```

### Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PhoLife",
    platforms: [.iOS("26.0")],
    products: [
        .iOSApplication(
            name: "PhoLife",
            targets: ["AppModule"],
            bundleIdentifier: "com.henrytran.PhoLife",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .bowl),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.pad],
            supportedInterfaceOrientations: [.landscapeRight, .landscapeLeft]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources/Sounds"),
                .process("Resources/Data")
            ]
        )
    ]
)
```

Key: `path: "."` compiles all Swift files. `Assets.xcassets` auto-processed. Sounds/Data declared as `.process` resources.

---

## 5. The 8 Minigames

### Build Order (easiest → hardest):

| Build # | Game | PRD # | Mechanic | Complexity |
|---|---|---|---|---|
| 1st | Clean the Bones | #3 | Tap rising bubbles (Whack-a-Mole) | Low |
| 2nd | Top It Off | #8 | Card flip memory match | Low |
| 3rd | Char the Aromatics | #1 | Hold-release power meter | Low-Med |
| 4th | Toast the Spices | #2 | Swipe-to-catch (Fruit Ninja) | Medium |
| 5th | Slice the Beef | #5 | Precision horizontal swipes | Medium |
| 6th | Season the Broth | #6 | 3-slider balancing | Medium |
| 7th | Simmer the Broth | #4 | Zone keeper (Flappy Bird) | Med-High |
| 8th | Assemble the Bowl | #7 | Drop-stacking + hero broth pour | High |

### Shared Infrastructure

- `MinigameContainerView` manages intro → play → score lifecycle for all 8 games
- Each scene has `var onComplete: ((score: Int, stars: Int) -> Void)?` closure
- `ParticleFactory` provides reusable emitters: steam, smoke, sparkle, splash, fire, celebration
- `ScoreAnimator` shows floating "+N" and quality feedback ("Perfect!", "Good")
- Star calculation: 90%+ = 3 stars, 70-89% = 2 stars, <70% = 1 star (always at least 1 — no hard blocking for judges)

### Per-Game Specs

**Game 1 — Char the Aromatics:** Power meter fills while touching. Release in green zone = perfect char. 4 rounds (2 onions + 2 ginger). Smoke particles increase with heat. Green zone narrows each round.

**Game 2 — Toast the Spices:** 5 correct spices + 5 decoys fly upward with arcs. Swipe across correct ones. Golden sparkle on catch, red flash on wrong. 3 wrong = game ends with current score. Action-based arcs, no physics engine.

**Game 3 — Clean the Bones:** Overhead pot view. Scum bubbles rise from bottom. Tap to pop. Spawn rate increases over time. Water transitions murky → clear as score rises. Multi-touch enabled.

**Game 4 — Simmer the Broth:** Side view of pot on stove. Tap = raise flame, release = lower. Keep temperature indicator in narrowing "simmer" zone. Random gusts perturb flame. Score = time-in-zone / total-time.

**Game 5 — Slice the Beef:** Cutting board with beef. Horizontal swipes slice. Score based on thickness consistency and evenness. Slices fan out visually. 8 slices per round.

**Game 6 — Season the Broth:** 3 draggable sliders (fish sauce, salt, sugar). Hit target flavor profile. Bowl color/glow shifts in real-time. "Taste" button to confirm. 3 attempts, best score counts.

**Game 7 — Assemble the Bowl:** Ingredients hover above bowl. Tap correct one to drop in order: noodles → brisket → raw beef → broth. **Hero moment:** broth pour is cinematic — golden stream, massive steam burst, raw beef changes red → pink. Camera zoom.

**Game 8 — Top It Off:** 12 cards (6 pairs). Topping image ↔ role text (heterogeneous matching). Flip animation with x-scale trick. Matched pairs float to bowl in background. Score by flip efficiency.

---

## 6. Asset Strategy

### Images (via /nano-banana-pro)
- **Style prompt prefix:** "Warm hand-painted watercolor illustration, Vietnamese food and culture theme, soft atmospheric lighting, muted earth tones with warm amber and golden highlights."
- 10 story panels at 1K resolution (~200KB each)
- 8 minigame backgrounds (~150KB each)
- ~40 sprite assets (~30KB each)
- Generate all story panels in one session for style consistency

### Audio
- 3 music tracks (.m4a, 96kbps mono, ~800KB each)
- 5 ambient loops (.m4a, 64kbps mono, ~200KB each)
- ~30 SFX (.m4a, 128kbps, ~30KB each)
- Sources: freesound.org, mixkit.co (CC0/royalty-free)

### Size Budget

| Category | Estimated |
|---|---|
| Story images | ~2 MB |
| Minigame art | ~2.8 MB |
| Music | ~2.4 MB |
| Ambient + SFX | ~1.9 MB |
| Code + metadata | ~0.5 MB |
| **Total** | **~9.6 MB** |
| **Headroom** | **~15.4 MB** |

---

## 7. Five-Day Schedule

### Day 1 (Feb 23): SCAFFOLD + END-TO-END SKELETON

**Goal:** Compiling app with all 4 phases navigable using placeholder content.

1. Create `PhoLife.swiftpm/` directory structure with `Package.swift` and workspace files
2. Create `CLAUDE.md` with build/run instructions
3. `PhoLifeApp.swift` + `ContentView.swift` with phase switching
4. `GameState.swift`, `MinigameResult.swift`, `CulturalFact.swift`, `StoryPanel.swift`
5. Placeholder `SplashView` (color background + title, auto-advances 3s)
6. Placeholder `StoryView` (TabView with 10 colored panels + "Let's Cook" button)
7. `MinigameContainerView` with one working SpriteKit scene (Clean the Bones placeholder)
8. `MinigameIntroCard` + `MinigameScoreCard` overlays
9. Placeholder `CompletionView` with score display + "Cook Another Bowl"
10. `AudioManager` stub + `HapticManager`
11. **Build + run on iPad Simulator — verify full flow**

### Day 2 (Feb 24): MINIGAMES 1-4

**Goal:** First 4 minigames playable with scoring.

1. Shared infrastructure: `ParticleFactory`, `ScoreAnimator`, `ProgressBarView`
2. **Clean the Bones** (tap bubbles) — reference implementation
3. **Top It Off** (memory match)
4. **Char the Aromatics** (hold-release timing)
5. **Toast the Spices** (swipe-to-catch)
6. Wire star scoring to GameState
7. Cultural facts data (all 8)
8. Test all 4 end-to-end

### Day 3 (Feb 25): MINIGAMES 5-8 + STORY

**Goal:** All 8 minigames playable. Story phase has real structure.

1. **Slice the Beef** (precision swipe)
2. **Season the Broth** (slider mixing)
3. **Simmer the Broth** (zone keeper)
4. **Assemble the Bowl** (drop-stacking + hero broth pour)
5. `StoryView` with horizontal paging TabView
6. `StoryPanelView` with parallax (zoom/pan on single image)
7. "Skip to Cook" button on all panels
8. Test full flow: all 8 minigames → completion → replay

### Day 4 (Feb 26): ASSETS + AUDIO + POLISH

**Goal:** Real images, integrated audio, visual polish.

- Generate story panel images via /nano-banana-pro (10 panels)
- Generate minigame backgrounds (8 scenes)
- Generate splash/completion bowl images
- Generate key sprite assets
- Source royalty-free music + ambient + SFX
- Implement AudioManager crossfading
- Wire audio into all scenes
- Splash animation, Liquid Glass styling, transitions, haptics
- Completion screen bowl reveal animation

### Day 5 (Feb 27): TEST + FIX + SUBMIT

**Goal:** Ship-ready. No crashes. Under 25 MB.

- Full end-to-end playthrough on iPad Simulator
- Fix bugs and crashes
- Test replay flow
- Accessibility pass (VoiceOver labels)
- ZIP size verification + compression if needed
- App icon generation
- Cold launch + kill/relaunch test
- Essay + AI disclosure prep
- Submit (buffer into Feb 28)

---

## 8. Scope Cuts (If Behind Schedule)

| Level | Cut | Time Saved |
|---|---|---|
| 1 | Single image per story panel (no parallax layers) | ~4h |
| 2 | Simplify Simmer (slider) + Assemble (tap order only) | ~5h |
| 3 | Reduce story from 10 to 7 panels | ~3h |
| 4 | Skip audio entirely, haptics only | ~4h |
| 5 | Procedural shapes / SF Symbols instead of images | ~8h |

---

## 9. Known Risks & Mitigations

| Risk | Mitigation |
|---|---|
| SwiftUI overlay blocks SpriteKit touches | `.allowsHitTesting(false)` on all non-interactive overlays |
| SwiftUI state change re-renders SpriteView | `.id(currentMinigameIndex)` to control recreation; closures not reactive bindings |
| Exceeds 25 MB | Conservative budget (est. 9.6 MB). Compress images. AAC audio at low bitrate. Check ZIP after every asset batch. |
| SpriteKit perf in Simulator | Max 50-100 particles per emitter. Load story images lazily. |
| Style inconsistency in /nano-banana-pro images | Identical style prompt prefix. Generate story panels in one batch. |
| Swift 6 strict concurrency | `@MainActor` on all Observable classes. Wrap callbacks in `Task { @MainActor in }`. |
| Crashes during judging | No force unwraps. Always at least 1 star. Cold launch test. |

---

## 10. Verification

1. **Build:** `build_sim` via XcodeBuildMCP — zero errors
2. **Run:** `build_run_sim` on iPad Pro 13-inch (M5) simulator
3. **Screenshot:** Every phase
4. **Full playthrough:** Splash → Story → All 8 minigames → Completion → Replay
5. **Skip path:** Story → "Skip to Cook" → Minigames → Completion
6. **Cold launch:** Kill app, relaunch, verify clean start
7. **ZIP size:** Verify ≤ 25 MB
8. **Logs:** Check for crashes/warnings

### XcodeBuildMCP Config
- Workspace: `PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace`
- Scheme: `PhoLife`
- Simulator: iPad Pro 13-inch (M5)
- Bundle ID: `com.henrytran.PhoLife`
