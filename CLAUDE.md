# PhoLife — SSC 2026

## Project Structure
- `PhoLife.swiftpm/` — App Playground (the submission artifact)
- `PhoLife-prd.md` — Product Requirements Document
- `PhoLife-implementation-plan.md` — Implementation Plan

## Build & Run
- Open: `open PhoLife.swiftpm`
- XcodeBuildMCP workspace: `PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace`
- Scheme: `PhoLife`
- Simulator: iPad Pro 13-inch (M5)
- Bundle ID: `com.henrytran.PhoLife`

## Key Constraints
- .swiftpm App Playground format (NOT .xcodeproj)
- iPad-only, iOS 26+, landscape locked
- 25 MB ZIP limit
- Fully offline, zero network calls
- Swift 6 strict concurrency

## Architecture
- SwiftUI shell + SpriteKit minigames via SpriteView
- @Observable MVVM with GameState as central model
- Enum-driven phase navigation (Splash → Story → Minigames → Completion)
- All overlays on SpriteView need .allowsHitTesting(false)

## Image Generation
- Use /nano-banana-pro skill for all images
- Style: "Warm hand-painted watercolor, Vietnamese food/culture theme"
- Resolution: 1K for space efficiency

## Important
- NEVER add .env to git (contains API key)
- Test ZIP size after every asset batch
- All overlays on SpriteView need .allowsHitTesting(false)
- No force unwraps anywhere
