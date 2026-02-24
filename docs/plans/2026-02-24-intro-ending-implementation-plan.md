# Intro & Ending Screen Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign SplashView with cinematic ingredient convergence animation and CompletionView with 3-column performance/bowl/ingredients layout, using Liquid Glass and custom SwiftUI ingredient icons.

**Architecture:** Shared `PhoIngredientIcon` enum provides 8 custom SwiftUI shape icons reused by both screens. New `PhoIngredient` model holds static ingredient data. SplashView rewritten with ingredient-to-bowl convergence. CompletionView rewritten as 3-column HStack.

**Tech Stack:** SwiftUI (iOS 26+), Liquid Glass (`.glassEffect`), Swift 6 strict concurrency, `.swiftpm` App Playground format

**Build & verify command:** From XcodeBuildMCP — use `build_sim` with workspace `PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace`, scheme `PhoLife`, simulator `iPad Pro 13-inch (M5)`. Or via Bash: `cd /Users/henryct/PhoLife && xcodebuild -workspace PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace -scheme PhoLife -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build 2>&1 | tail -5`

**Color constants used throughout (copy into each file):**
```swift
private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
private let warmAmber = Color(red: 212/255, green: 165/255, blue: 116/255)
private let cream = Color(red: 1.0, green: 248/255, blue: 220/255)
private let deepAmber = Color(red: 0.75, green: 0.55, blue: 0.35)
```

---

## Task 1: Create PhoIngredientIcon enum with 8 custom SwiftUI shape icons

**Files:**
- Create: `PhoLife.swiftpm/Features/Shared/PhoIngredientIcon.swift`

**Step 1: Create the icon enum and view**

Create `PhoLife.swiftpm/Features/Shared/PhoIngredientIcon.swift` with:

- An `enum PhoIngredientIcon: Int, CaseIterable` with 8 cases: `onion`, `starAnise`, `bone`, `pot`, `beefSlice`, `fishSauce`, `noodles`, `herbs`
- A `PhoIngredientIconView: View` struct that takes a `PhoIngredientIcon` and `size: CGFloat` (default 30)
- Each case renders a distinct SwiftUI shape in warm amber:

| Case | How to draw |
|------|------------|
| `onion` | Two nested half-circles (Path arcs) in amber, small green capsule shoot on top |
| `starAnise` | 8-pointed star using Path — compute 16 points alternating between outer radius and inner radius at evenly spaced angles |
| `bone` | Horizontal Capsule (width: size, height: size*0.35) with Circle knobs (size*0.35) at each end |
| `pot` | RoundedRectangle body (size*0.7 wide, size*0.45 tall) + two small handle rects on sides + 3 wavy steam lines above using Path with `addQuadCurve` |
| `beefSlice` | RoundedRectangle (size*0.75 wide, size*0.5 tall, cornerRadius 6) with 2-3 thin diagonal Path lines inside for marbling |
| `fishSauce` | Vertical RoundedRectangle body + narrower rect neck on top + small triangle/cap |
| `noodles` | 3-4 wavy horizontal Path lines stacked vertically, each using sine-wave pattern via `addQuadCurve` |
| `herbs` | Teardrop leaf shape via Path (wide at base, pointed at tip) + thin center vein line |

- All shapes filled with `warmAmber` color
- Wrap in a frame of `size x size`

**Step 2: Add a SwiftUI Preview**

```swift
#Preview {
    ZStack {
        Color(red: 0.08, green: 0.05, blue: 0.03).ignoresSafeArea()
        HStack(spacing: 24) {
            ForEach(PhoIngredientIcon.allCases, id: \.rawValue) { icon in
                VStack(spacing: 8) {
                    PhoIngredientIconView(icon: icon, size: 40)
                    Text(String(describing: icon))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}
```

**Step 3: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED with no errors.

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoIngredientIcon.swift
git commit -m "feat: add 8 custom SwiftUI ingredient icons"
```

---

## Task 2: Create PhoIngredient data model

**Files:**
- Create: `PhoLife.swiftpm/Models/PhoIngredient.swift`

**Step 1: Create the model**

Create `PhoLife.swiftpm/Models/PhoIngredient.swift`:

```swift
import Foundation

struct PhoIngredient: Identifiable {
    let id: Int
    let name: String
    let contribution: String
    let icon: PhoIngredientIcon

    static let allIngredients: [PhoIngredient] = [
        PhoIngredient(id: 1, name: "Charred Onion & Ginger", contribution: "Smoky depth and aromatic backbone", icon: .onion),
        PhoIngredient(id: 2, name: "Whole Spices", contribution: "Signature fragrance of star anise & cinnamon", icon: .starAnise),
        PhoIngredient(id: 3, name: "Beef Bones", contribution: "Rich collagen body and clear golden broth", icon: .bone),
        PhoIngredient(id: 4, name: "Slow-Simmered Broth", contribution: "Hours of gentle heat for deep umami", icon: .pot),
        PhoIngredient(id: 5, name: "Paper-Thin Beef", contribution: "Cooks to medium-rare from the hot broth", icon: .beefSlice),
        PhoIngredient(id: 6, name: "Fish Sauce & Rock Sugar", contribution: "Savory-sweet seasoning balance", icon: .fishSauce),
        PhoIngredient(id: 7, name: "Fresh Rice Noodles", contribution: "Silky foundation that carries the broth", icon: .noodles),
        PhoIngredient(id: 8, name: "Fresh Herbs & Garnish", contribution: "Bright contrast — basil, lime, bean sprouts", icon: .herbs),
    ]
}
```

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/Models/PhoIngredient.swift
git commit -m "feat: add PhoIngredient data model with 8 ingredients"
```

---

## Task 3: Rewrite SplashView with convergence animation

**Files:**
- Modify: `PhoLife.swiftpm/Features/Splash/SplashView.swift` (full rewrite, keep same struct name and `onComplete` interface)

**Step 1: Rewrite SplashView**

Replace entire contents of `SplashView.swift`. The new implementation must:

**Keep the same public interface:**
```swift
struct SplashView: View {
    var onComplete: () -> Void
    // ...
}
```

**State properties:**
```swift
@State private var bowlVisible = false
@State private var titleVisible = false
@State private var subtitleVisible = false
@State private var steamActive = false
@State private var ambientGlow = false
@State private var exitTransition = false
// Per-ingredient arrival tracking (8 bools or a Set<Int>)
@State private var ingredientArrived: Set<Int> = []
@State private var ingredientStarted: Set<Int> = []
```

**Body structure (ZStack layers):**

1. `backgroundLayer` — same warm dark + breathing radial amber glow as before (keep existing code logic)

2. `steamParticlesLayer` — reuse existing `SteamWispView` pattern (12 wisps), but key change: wisps have lower initial opacity, increasing as `ingredientArrived.count` grows. Scale the base opacity: `0.02 + Double(ingredientArrived.count) * 0.008`

3. `ingredientConvergenceLayer` — new:
   - `ForEach(0..<8, id: \.self)` rendering `FloatingIngredientView` for each
   - Each `FloatingIngredientView` needs: index, icon (from `PhoIngredientIcon.allCases[index]`), start position, `isStarted` bool (from `ingredientStarted`), `hasArrived` bool (from `ingredientArrived`)
   - Start positions spread around screen edges:
     ```swift
     let startPositions: [CGPoint] = [
         CGPoint(x: -450, y: -200),  // top-left
         CGPoint(x: 450, y: -250),   // top-right
         CGPoint(x: -500, y: 50),    // left
         CGPoint(x: 500, y: 100),    // right
         CGPoint(x: -400, y: 280),   // bottom-left
         CGPoint(x: 400, y: 250),    // bottom-right
         CGPoint(x: -150, y: -320),  // top
         CGPoint(x: 200, y: 320),    // bottom
     ]
     ```
   - When `isStarted && !hasArrived`: animate offset from start position toward (0,0) using `.spring(duration: 1.2, bounce: 0.1)`, opacity from 0.5 to 1.0
   - When `hasArrived`: scale to 0 with a small burst (3 tiny circles expanding outward and fading)
   - Trailing glow: a Circle filled with warmAmber.opacity(0.15), blurred by 8, positioned behind the icon with a slight animation delay

4. `bowlSection` — similar to current: center bowl image `splash-bowl` 300x300, radial glow behind, spring scale 0.7→1.0. Add a warm pulse effect when all ingredients arrive (`ingredientArrived.count == 8`): brief scale to 1.05 then back to 1.0

5. `titleSection` — "PhoLife" with warm amber gradient, wrapped in `.padding(.horizontal, 24).padding(.vertical, 8).glassContainer()` for Liquid Glass pill effect. Fades + scales in

6. `subtitleSection` — "The story of Vietnamese phở" cream text + decorative capsule divider (same as current)

**`FloatingIngredientView` (private struct):**
```swift
private struct FloatingIngredientView: View {
    let index: Int
    let icon: PhoIngredientIcon
    let startPosition: CGPoint
    let isStarted: Bool
    let hasArrived: Bool

    @State private var burstActive = false

    var body: some View {
        ZStack {
            // Trailing glow
            Circle()
                .fill(warmAmber.opacity(0.15))
                .frame(width: 40, height: 40)
                .blur(radius: 8)
                .opacity(isStarted && !hasArrived ? 0.6 : 0)

            // The icon
            PhoIngredientIconView(icon: icon, size: 32)
                .opacity(isStarted && !hasArrived ? 1.0 : (hasArrived ? 0 : 0.3))
                .scaleEffect(hasArrived ? 0.01 : 1.0)

            // Arrival burst particles
            if hasArrived {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(warmAmber.opacity(burstActive ? 0 : 0.5))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: burstActive ? CGFloat(cos(Double(i) * 2.094)) * 30 : 0,
                            y: burstActive ? CGFloat(sin(Double(i) * 2.094)) * 30 : 0
                        )
                        .blur(radius: burstActive ? 4 : 0)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) { burstActive = true }
                }
            }
        }
        .offset(
            x: isStarted && !hasArrived ? 0 : (hasArrived ? 0 : startPosition.x),
            y: isStarted && !hasArrived ? 0 : (hasArrived ? 0 : startPosition.y)
        )
        .animation(.spring(duration: 1.2, bounce: 0.1), value: isStarted)
        .animation(.easeIn(duration: 0.3), value: hasArrived)
    }
}
```

**Animation sequence in `.task` modifier:**

```swift
.task {
    // 0.0s — ambient glow
    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
        ambientGlow = true
    }

    // 0.3s — bowl
    try? await Task.sleep(for: .seconds(0.3))
    withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
        bowlVisible = true
    }
    withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
        steamActive = true
    }

    // 0.5s — ingredients wave 1 (indices 0, 1)
    try? await Task.sleep(for: .seconds(0.2))
    withAnimation { ingredientStarted.insert(0); ingredientStarted.insert(1) }

    // 0.8s — wave 2 (indices 2, 3)
    try? await Task.sleep(for: .seconds(0.3))
    withAnimation { ingredientStarted.insert(2); ingredientStarted.insert(3) }

    // 1.1s — wave 3 (indices 4, 5)
    try? await Task.sleep(for: .seconds(0.3))
    withAnimation { ingredientStarted.insert(4); ingredientStarted.insert(5) }

    // 1.4s — wave 4 (indices 6, 7)
    try? await Task.sleep(for: .seconds(0.3))
    withAnimation { ingredientStarted.insert(6); ingredientStarted.insert(7) }

    // 1.5s — title
    try? await Task.sleep(for: .seconds(0.1))
    withAnimation(.spring(duration: 0.7, bounce: 0.15)) {
        titleVisible = true
    }

    // 2.0s — subtitle
    try? await Task.sleep(for: .seconds(0.5))
    withAnimation(.easeOut(duration: 0.6)) {
        subtitleVisible = true
    }

    // 2.0s — mark first ingredients as arrived (they had 1.2s spring travel time)
    // Stagger arrivals based on when they started
    try? await Task.sleep(for: .seconds(0.3))
    for i in 0..<8 {
        try? await Task.sleep(for: .seconds(0.15))
        withAnimation(.easeIn(duration: 0.3)) {
            ingredientArrived.insert(i)
        }
    }

    // 4.0s — exit
    try? await Task.sleep(for: .seconds(0.8))
    withAnimation(.easeInOut(duration: 0.5)) {
        exitTransition = true
    }
    try? await Task.sleep(for: .seconds(0.5))
    onComplete()
}
```

**Keep `SteamWispView` (private struct) from current file** — copy it over unchanged.

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Run in simulator to verify visually**

Use XcodeBuildMCP `build_run_sim` or manually run in simulator. Verify:
- Bowl appears center with spring animation
- 8 ingredient icons float inward from edges in 4 waves
- Icons disappear with particle burst on arrival
- "PhoLife" title appears in glass pill
- Tagline appears
- Auto-advances after ~4.5s

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Splash/SplashView.swift
git commit -m "feat: redesign splash screen with ingredient convergence animation"
```

---

## Task 4: Rewrite CompletionView with 3-column layout

**Files:**
- Modify: `PhoLife.swiftpm/Features/Completion/CompletionView.swift` (full rewrite, keep same struct name and `gameState` interface)

**Step 1: Rewrite CompletionView**

Replace entire contents of `CompletionView.swift`. The new implementation must:

**Keep the same public interface:**
```swift
struct CompletionView: View {
    let gameState: GameState
    // ...
}
```

**State properties:**
```swift
@State private var bowlVisible = false
@State private var starsVisible = false
@State private var titleVisible = false
@State private var earnedTitleVisible = false
@State private var leftPanelVisible = false
@State private var rightPanelVisible = false
@State private var leftRowsVisible = false
@State private var rightRowsVisible = false
@State private var buttonVisible = false
@State private var buttonPulse = false
@State private var ambientGlow = false
@State private var confettiActive = false
```

**Computed:**
```swift
private var overallStars: Int {
    if gameState.totalStars >= 20 { return 3 }
    else if gameState.totalStars >= 12 { return 2 }
    else { return 1 }
}

private var totalScore: Int {
    gameState.minigameResults.reduce(0) { $0 + $1.score }
}
```

**Body structure:**

```swift
var body: some View {
    ZStack {
        backgroundLayer          // same warm dark + breathing glow
        if overallStars >= 2 { confettiLayer }  // keep existing ConfettiPiece

        HStack(spacing: 0) {
            // Left panel — Performance
            performancePanel
                .frame(width: 280)
                .padding(.leading, 24)

            Spacer()

            // Center — Hero bowl
            centerColumn
                .frame(maxWidth: 340)

            Spacer()

            // Right panel — Ingredients
            ingredientsPanel
                .frame(width: 280)
                .padding(.trailing, 24)
        }
        .padding(.vertical, 24)
    }
    .onAppear { startRevealSequence() }
    .transition(.opacity)
}
```

**Left panel (`performancePanel`):**
```swift
private var performancePanel: some View {
    VStack(alignment: .leading, spacing: 0) {
        // Header
        Text("Your Performance")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(warmAmber)
            .padding(.bottom, 16)

        // 8 minigame rows
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(Array(gameState.minigameResults.enumerated()), id: \.element.id) { index, result in
                    performanceRow(result: result, index: index)
                }
            }
        }

        // Footer: total
        Capsule().fill(warmAmber.opacity(0.25)).frame(height: 1)
            .padding(.vertical, 8)
        HStack {
            Text("Total")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(cream)
            Spacer()
            StarRatingView(stars: overallStars, starSize: 16)
            Text("\(totalScore)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber)
                .frame(width: 40, alignment: .trailing)
        }
    }
    .padding(18)
    .glassContainer()
    .opacity(leftPanelVisible ? 1 : 0)
    .offset(x: leftPanelVisible ? 0 : -20)
}
```

**Performance row:**
```swift
private func performanceRow(result: MinigameResult, index: Int) -> some View {
    let fact = CulturalFact.allFacts[safe: result.minigameIndex]
    let ingredient = PhoIngredient.allIngredients[safe: result.minigameIndex]

    return HStack(spacing: 10) {
        // Ingredient icon
        if let ingredient {
            PhoIngredientIconView(icon: ingredient.icon, size: 22)
        }
        // Minigame name
        Text(fact?.minigameTitle ?? "Step \(index + 1)")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(cream)
            .lineLimit(1)
        Spacer()
        // Stars
        StarRatingView(stars: result.stars, starSize: 14)
        // Score
        Text("\(result.score)")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(warmAmber)
            .frame(width: 32, alignment: .trailing)
    }
    .opacity(leftRowsVisible ? 1 : 0)
    .offset(x: leftRowsVisible ? 0 : -12)
    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: leftRowsVisible)
}
```

Note: add a `safe` subscript on Array if not already accessible (it exists in ProgressBarView.swift as a private extension — move it or duplicate it here as file-private).

**Center column (`centerColumn`):**
```swift
private var centerColumn: some View {
    VStack(spacing: 12) {
        Spacer()

        // Title
        titleSection

        // Bowl
        bowlSection

        // Stars
        StarRatingView(stars: overallStars, animated: true, starSize: 40)
            .opacity(starsVisible ? 1 : 0)
            .scaleEffect(starsVisible ? 1.0 : 0.6)

        // Earned title
        earnedTitleSection

        Spacer()

        // Cook Another Bowl button
        replayButton
            .padding(.bottom, 16)
    }
}
```

**Bowl section:** Same as current (completion-bowl 240x240 with radial glow, spring scale-in), keep existing logic.

**Title section:** "Your Bowl is Ready!" — 36pt instead of 40pt, with liquid glass pill backing via `.padding(.horizontal, 20).padding(.vertical, 8).glassContainer()`.

**Earned title:** Same decorative capsule style as current.

**Replay button:** Same as current (warm amber gradient capsule, pulse glow), keep existing code.

**Right panel (`ingredientsPanel`):**
```swift
private var ingredientsPanel: some View {
    VStack(alignment: .leading, spacing: 0) {
        Text("Bowl Ingredients")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(warmAmber)
            .padding(.bottom, 16)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(Array(PhoIngredient.allIngredients.enumerated()), id: \.element.id) { index, ingredient in
                    ingredientRow(ingredient: ingredient, index: index)
                }
            }
        }
    }
    .padding(18)
    .glassContainer()
    .opacity(rightPanelVisible ? 1 : 0)
    .offset(x: rightPanelVisible ? 0 : 20)
}
```

**Ingredient row:**
```swift
private func ingredientRow(ingredient: PhoIngredient, index: Int) -> some View {
    HStack(alignment: .top, spacing: 12) {
        PhoIngredientIconView(icon: ingredient.icon, size: 26)
            .frame(width: 30)

        VStack(alignment: .leading, spacing: 3) {
            Text(ingredient.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(cream)
            Text(ingredient.contribution)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(2)
        }
    }
    .opacity(rightRowsVisible ? 1 : 0)
    .offset(x: rightRowsVisible ? 0 : 12)
    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: rightRowsVisible)
}
```

**`startRevealSequence()`:** Follow the animation timeline from design doc:

```swift
private func startRevealSequence() {
    // 0.0s — ambient glow
    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
        ambientGlow = true
    }
    // 0.3s — bowl
    withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
        bowlVisible = true
    }
    // 0.5s — title
    withAnimation(.spring(duration: 0.6, bounce: 0.15).delay(0.5)) {
        titleVisible = true
    }
    // 0.7s — stars + confetti
    withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.7)) {
        starsVisible = true
    }
    if overallStars >= 2 {
        withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
            confettiActive = true
        }
    }
    // 0.9s — earned title
    withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.9)) {
        earnedTitleVisible = true
    }
    // 1.0s — left panel
    withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
        leftPanelVisible = true
    }
    // 1.1s — left rows
    withAnimation(.easeOut(duration: 0.3).delay(1.1)) {
        leftRowsVisible = true
    }
    // 1.2s — right panel
    withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
        rightPanelVisible = true
    }
    // 1.3s — right rows
    withAnimation(.easeOut(duration: 0.3).delay(1.3)) {
        rightRowsVisible = true
    }
    // 1.6s — button
    withAnimation(.spring(duration: 0.5, bounce: 0.15).delay(1.6)) {
        buttonVisible = true
    }
    // 2.0s — button pulse
    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(2.0)) {
        buttonPulse = true
    }
}
```

**Keep `ConfettiPiece` private struct** from current file — copy unchanged.

**Add file-private safe subscript:**
```swift
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

**Update Preview:**
```swift
#Preview {
    CompletionView(gameState: {
        let state = GameState()
        for i in 0..<8 {
            state.completeMinigame(result: MinigameResult(
                minigameIndex: i, stars: [3,2,3,2,3,1,2,3][i], score: [95,78,92,81,88,65,76,90][i]
            ))
        }
        return state
    }())
    .preferredColorScheme(.dark)
}
```

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Run in simulator to verify visually**

Verify:
- 3-column layout fits landscape iPad
- Left panel shows 8 minigame rows with icons, stars, scores + total footer
- Center has bowl, title in glass pill, stars, earned title, replay button
- Right panel shows 8 ingredient rows with custom icons and descriptions
- All animations stagger correctly
- "Cook Another Bowl" resets state correctly
- Confetti appears for 2+ star games

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Completion/CompletionView.swift
git commit -m "feat: redesign completion screen with 3-column performance/bowl/ingredients layout"
```

---

## Task 5: Visual polish and final tuning

**Files:**
- Possibly adjust: `PhoLife.swiftpm/Features/Splash/SplashView.swift`
- Possibly adjust: `PhoLife.swiftpm/Features/Completion/CompletionView.swift`
- Possibly adjust: `PhoLife.swiftpm/Features/Shared/PhoIngredientIcon.swift`

**Step 1: Run full app flow in simulator**

Build and run via XcodeBuildMCP. Play through entire flow: splash → story → 8 minigames → completion. Watch for:
- Splash animation timing feels cinematic (not too fast, not too slow)
- Ingredient icons are visually distinct and recognizable at 30pt
- Completion columns don't overflow or clip on iPad Pro 13"
- Glass containers have proper Liquid Glass effect on iOS 26
- Stagger animations feel smooth, not janky
- Button interactions work (replay resets correctly)

**Step 2: Fix any layout/animation issues found**

Common adjustments:
- If side panels clip content: reduce font sizes by 1pt or adjust padding
- If ingredient icons look unclear: increase size to 34pt or add stroke
- If animations feel too slow/fast: adjust timing values
- If glass containers look too opaque: already handled by GlassContainer modifier

**Step 3: Commit final polish**

```bash
git add -A
git commit -m "polish: tune splash and completion screen animations and layout"
```
