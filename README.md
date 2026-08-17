# PhoLife 🍜

> **The story of Vietnamese phở — from a bowl of history to a bowl you cook yourself.**

<p align="left">
  <img src="https://img.shields.io/badge/Swift%20Student%20Challenge-2026%20Winner-FF6B00?style=for-the-badge&logo=apple&logoColor=white" alt="Swift Student Challenge 2026 Winner">
</p>

<p align="left">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/SwiftUI-blue?logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/SpriteKit-orange?logo=apple&logoColor=white" alt="SpriteKit">
  <img src="https://img.shields.io/badge/iPadOS-17%2B-lightgrey?logo=apple&logoColor=white" alt="iPadOS 17+">
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey?logo=apple&logoColor=white" alt="macOS 14+">
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero dependencies">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
</p>

**PhoLife** is an interactive story-and-cooking game for iPad and Mac that teaches the history and
craft of Vietnamese phở. Players journey from the dish's origins on the Red River, through French
colonial kitchens and a divided country, to the diaspora that carried it across oceans — then step
into the kitchen and cook a bowl themselves across eight hand-built minigames, guided by a narrator
named Khoa Nguyen.

It was selected as a **Winner of Apple's Swift Student Challenge 2026**, and is built entirely with
Apple frameworks — **SwiftUI**, **SpriteKit**, and **AVFoundation** — in **Swift 6** with strict
concurrency, and **zero third-party dependencies**.

---

## 📸 Screenshots & Demo

> _Media coming soon._

| Splash | Story | Minigame | Completion |
| :---: | :---: | :---: | :---: |
| _`docs/media/splash.png`_ | _`docs/media/story.png`_ | _`docs/media/minigame.png`_ | _`docs/media/completion.png`_ |

<!-- Demo video: replace with a link or an embedded GIF, e.g. docs/media/demo.gif -->

---

## ✨ Highlights

- **A complete, narrative-driven game** — four phases (splash → visual-novel history → 8 minigames →
  results) wired together by a phase-based state machine.
- **Eight distinct SpriteKit minigames**, each a different mechanic (timing, swipe-to-catch,
  whack-a-mole, hold-to-balance, slicing, slider-balancing, sequencing, memory match) with its own
  art direction, particle effects, and 1–3 star scoring.
- **Procedural audio synthesis** — 12 sound effects are generated at runtime with AVAudioEngine
  (hand-written DSP), so almost nothing ships as an audio file.
- **A cinematic visual-novel narrator** — Khoa Nguyen guides the player with typewriter dialogue,
  expressive pixel-art portraits, and text-blip sound synced to each character.
- **Culturally grounded** — every minigame teaches a real phở technique paired with an authentic
  cultural fact; the story treats the dish as living heritage rather than a recipe.
- **~13,500 lines of Swift across 35 files, zero external dependencies** — everything is built on
  first-party Apple frameworks.

---

## 🎮 The Experience

PhoLife plays out in four phases, routed by an `@Observable` state machine:

1. **Splash** — Eight ingredient icons fly in from the screen edges and converge into a steaming
   bowl before the title appears.
2. **Story** — A ten-panel visual-novel history of phở, narrated by **Khoa Nguyen** from Đà Nẵng,
   with typewriter dialogue, a Ken Burns background treatment, and animated portrait expressions.
   (Skippable for return players.)
3. **Cook** — Eight sequential cooking minigames, each framed by an intro card (cultural fact +
   how-to-play) and closed by an animated star-and-score reveal.
4. **Completion** — A results dashboard with per-game stars, a total (max 24), an earned rank, and a
   glowing pixel-art bowl. Replayable via "Cook Another Bowl."

Your total across all eight games earns a title:
**Street Food Curious → Hanoi Home Cook → Saigon Street Vendor → Pho Master.**

---

## 🍲 The Eight Minigames

Each step mirrors a real stage of making phở:

| # | Minigame | Mechanic | You learn… |
|---|----------|----------|------------|
| 1 | **Char the Aromatics** | Timing — tap inside a shrinking target | Charring onion & ginger builds the broth's backbone |
| 2 | **Toast the Spices** | Swipe-to-catch (Fruit-Ninja style) | The five spices of phở — and the decoys that don't belong |
| 3 | **Clean the Bones** | Tap-to-pop / whack-a-mole | Blanching bones is what makes broth run clear |
| 4 | **Simmer the Broth** | Hold-to-balance a moving zone | Patience — a true simmer, never a boil |
| 5 | **Slice the Beef** | Reaction-timed cutting | Paper-thin slices so the hot broth cooks them |
| 6 | **Season the Broth** | Slider balancing | Fish sauce, not soy, is phở's real backbone |
| 7 | **Assemble the Bowl** | Sequencing + a pour cinematic | The layering order — raw beef goes on top |
| 8 | **Top It Off** | Memory match | Toppings on the side reflect communal dining |

---

## 🛠 Built With

| Area | Technology |
|------|------------|
| Language | Swift 6 (strict concurrency, `@MainActor` throughout) |
| UI & navigation | SwiftUI (`@Observable`, custom transitions, `Canvas` vector art) |
| Gameplay | SpriteKit (8 `SKScene` subclasses, emitters, procedural VFX) |
| Audio | AVFoundation — `AVAudioEngine` synthesis + layered `AVAudioPlayer` mixing |
| Haptics | UIKit feedback generators |
| Typography | System SF Pro Rounded (bridged into SpriteKit labels) |
| Distribution | Swift Playgrounds App (`.swiftpm`), Education category |
| Dependencies | **None** |

**Targets:** iPadOS 17+ and macOS 14+ (landscape-first). No third-party packages.

---

## 🧭 Engineering Highlights

A few pieces I'm particularly proud of:

- **Runtime sound engine** (`Services/SoundSynthesizer.swift`) — an `AVAudioEngine` graph with a pool
  of ten player nodes pre-renders 12 effects as raw PCM buffers at launch: sine clicks with decay
  envelopes, square-wave buzzes from odd harmonics, low-pass-filtered noise sweeps for slices, and
  multi-harmonic shimmer chimes for star reveals. The game ships almost no audio files.
- **Three-layer adaptive audio** (`Services/AudioManager.swift`) — independent music, ambient, and
  SFX layers with timer-driven crossfades and music ducking during gameplay, all written to satisfy
  Swift 6 strict-concurrency checking.
- **SwiftUI ↔ SpriteKit bridge** (`Features/Minigames/MinigameContainerView.swift`) — a scene factory
  maps the current step to an `SKScene` subclass and funnels results back through a single
  `(score, stars)` closure into shared game state; SwiftUI overlay cards blur the live scene beneath
  them.
- **Reusable SpriteKit VFX toolkit** (`Features/Shared/SceneEffects.swift`) — camera shake, particle
  bursts, expanding rings, floating score text, vignettes, and entrance/exit curtains as a single
  `SKScene` extension shared by all eight games.
- **Procedural vector art** (`Features/Shared/PhoIngredientIcon.swift`) — all eight ingredient icons
  are drawn with SwiftUI `Canvas`/`Path`, not image assets.

---

## 🚀 Running It

**Requirements:** a Mac with Xcode 16+ (Swift 6), or an iPad/Mac running Swift Playgrounds 4.5+.

**In Xcode**
1. Clone the repo:
   ```bash
   git clone https://github.com/henry-tran07/PhoLife.git
   ```
2. Open `PhoLife.swiftpm` in Xcode.
3. Select an iPad (or Mac) run destination and press **Run** (⌘R). Best experienced in landscape.

**In Swift Playgrounds** (iPad or Mac)
1. Open `PhoLife.swiftpm` in Swift Playgrounds.
2. Tap **Run**.

---

## 🗂 Project Structure

```
PhoLife.swiftpm/
├── PhoLifeApp.swift          # @main entry point
├── ContentView.swift         # Phase router (splash → story → minigames → completion)
├── Models/                   # GameState, StoryPanel, PhoIngredient, CulturalFact, …
├── Services/                 # AudioManager, SoundSynthesizer, HapticManager, FontManager
├── Features/
│   ├── Splash/               # Animated title sequence
│   ├── Story/                # Visual-novel narration (Khoa Nguyen)
│   ├── Minigames/            # SpriteKit bridge, intro/score cards
│   │   └── Scenes/           # The 8 cooking minigames
│   ├── Completion/           # Results dashboard
│   └── Shared/               # Reusable UI + SpriteKit VFX
└── Resources/                # Assets.xcassets + background music
```

---

## 🌏 About the Story

PhoLife frames phở not as a recipe but as a country's history in a bowl — its pre-colonial roots,
the French beef that reshaped it, the 1954 divide between North and South, and the 1975 diaspora that
carried it across oceans and turned restaurants into community anchors. Every technique the player
learns is real, and the closing message is simple: now the story your bowl carries is yours, too.

---

## 📄 License

Released under the [MIT License](LICENSE).

## 👤 Author

**Henry Tran** — Apple Swift Student Challenge 2026 Winner
[GitHub](https://github.com/henry-tran07) · <!-- LinkedIn: add link --> · <!-- Portfolio: add link -->
