# SwiftUI Pho Bowl Component — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Use /ui-ux-pro-max skill for all SwiftUI implementation.

**Goal:** Replace the `completion-bowl` image asset with a fully SwiftUI-drawn pho bowl component featuring a 7-layer stylized design with layered reveal animation and idle steam/shimmer effects.

**Architecture:** A `PhoBowlView` struct using a ZStack of 7 layers (bowl exterior, rim, broth, noodles, beef, herbs, steam), each built from SwiftUI `Path`, `Ellipse`, `Capsule`, and gradient fills. Animation state drives sequential reveal. Integrates into existing CompletionView center column.

**Tech Stack:** SwiftUI (iOS 26+), Liquid Glass, Swift 6 strict concurrency, .swiftpm App Playground

**Build & verify command:** `cd /Users/henryct/PhoLife && xcodebuild -workspace PhoLife.swiftpm/.swiftpm/xcode/package.xcworkspace -scheme PhoLife -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build 2>&1 | tail -5`

**Design doc:** `docs/plans/2026-02-24-swiftui-pho-bowl-design.md`

**Color reference:**
```swift
// Bowl-specific colors
private let bowlTan = Color(red: 0.77, green: 0.58, blue: 0.42)         // #C4956A
private let bowlBrown = Color(red: 0.55, green: 0.38, blue: 0.25)       // #8B6240
private let brothGold = Color(red: 0.83, green: 0.63, blue: 0.31)       // #D4A050
private let brothDeep = Color(red: 0.72, green: 0.53, blue: 0.23)       // #B8863A
private let noodleCream = Color(red: 1.0, green: 0.96, blue: 0.88)      // #FFF5E0
private let beefPink = Color(red: 0.83, green: 0.45, blue: 0.42)        // #D4736A
private let beefBrown = Color(red: 0.63, green: 0.35, blue: 0.31)       // #A0594E
private let herbGreen = Color(red: 0.36, green: 0.67, blue: 0.36)       // #5DAA5D
private let limeGreen = Color(red: 0.66, green: 0.85, blue: 0.42)       // #A8D86A
private let chiliRed = Color(red: 0.83, green: 0.25, blue: 0.25)        // #D44040
private let warmAmber = Color(red: 212/255, green: 165/255, blue: 116/255)
```

---

## Task 1: Create PhoBowlView with bowl exterior and rim (Layers 1-2)

**Files:**
- Create: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

**Step 1: Create PhoBowlView with Layer 1 (bowl exterior) and Layer 2 (rim)**

Create `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`.

The bowl is drawn from a top-down perspective — you're looking slightly into the bowl. Key geometry:
- The bowl exterior is a half-ellipse shape: a wide shallow arc at the top (the rim) connected to a deeper arc at the bottom (the belly)
- The rim is a thin elliptical ring sitting at the top

```swift
import SwiftUI

struct PhoBowlView: View {

    var size: CGFloat = 240
    var animated: Bool = true

    // MARK: - Animation State

    @State private var bowlExteriorVisible = false
    @State private var rimVisible = false
    @State private var brothVisible = false
    @State private var noodlesVisible = false
    @State private var beefVisible = false
    @State private var herbsVisible = false
    @State private var steamActive = false
    @State private var shimmerActive = false

    // MARK: - Colors

    private let bowlTan = Color(red: 0.77, green: 0.58, blue: 0.42)
    private let bowlBrown = Color(red: 0.55, green: 0.38, blue: 0.25)
    private let brothGold = Color(red: 0.83, green: 0.63, blue: 0.31)
    private let brothDeep = Color(red: 0.72, green: 0.53, blue: 0.23)
    private let noodleCream = Color(red: 1.0, green: 0.96, blue: 0.88)
    private let beefPink = Color(red: 0.83, green: 0.45, blue: 0.42)
    private let beefBrown = Color(red: 0.63, green: 0.35, blue: 0.31)
    private let herbGreen = Color(red: 0.36, green: 0.67, blue: 0.36)
    private let limeGreen = Color(red: 0.66, green: 0.85, blue: 0.42)
    private let chiliRed = Color(red: 0.83, green: 0.25, blue: 0.25)

    // MARK: - Proportions

    private var bowlWidth: CGFloat { size }
    private var bowlHeight: CGFloat { size * 0.6 }
    private var rimY: CGFloat { size * 0.18 }
    private var brothWidth: CGFloat { size * 0.82 }
    private var brothHeight: CGFloat { size * 0.28 }

    // MARK: - Body

    var body: some View {
        ZStack {
            bowlExteriorLayer
            rimLayer
            // Layers 3-7 added in subsequent tasks
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Your completed bowl of Vietnamese pho with noodles, beef, and fresh herbs")
        .accessibilityAddTraits(.isImage)
        .onAppear { startReveal() }
    }

    // MARK: - Layer 1: Bowl Exterior

    private var bowlExteriorLayer: some View {
        // Half-ellipse: wide shallow arc at top, deeper belly arc at bottom
        Path { path in
            let w = bowlWidth
            let topY = rimY
            let bottomY = bowlHeight

            // Start at left edge of rim
            path.move(to: CGPoint(x: (size - w) / 2, y: topY + size * 0.2))

            // Top rim arc (shallow, wide) — left to right
            path.addQuadCurve(
                to: CGPoint(x: (size + w) / 2, y: topY + size * 0.2),
                control: CGPoint(x: size / 2, y: topY)
            )

            // Right side curves down to bottom
            path.addQuadCurve(
                to: CGPoint(x: size / 2 + size * 0.15, y: bottomY),
                control: CGPoint(x: (size + w) / 2 - size * 0.02, y: bottomY - size * 0.08)
            )

            // Bottom belly arc — right to left
            path.addQuadCurve(
                to: CGPoint(x: size / 2 - size * 0.15, y: bottomY),
                control: CGPoint(x: size / 2, y: bottomY + size * 0.08)
            )

            // Left side curves back up to start
            path.addQuadCurve(
                to: CGPoint(x: (size - w) / 2, y: topY + size * 0.2),
                control: CGPoint(x: (size - w) / 2 + size * 0.02, y: bottomY - size * 0.08)
            )

            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [bowlTan, bowlBrown],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
        .opacity(bowlExteriorVisible ? 1 : 0)
        .scaleEffect(bowlExteriorVisible ? 1.0 : 0.8)
    }

    // MARK: - Layer 2: Rim

    private var rimLayer: some View {
        // Elliptical rim at top of bowl
        Ellipse()
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.78, blue: 0.65),
                        bowlTan,
                        Color(red: 0.85, green: 0.7, blue: 0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: size * 0.025
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.82, blue: 0.7).opacity(0.3),
                        bowlTan.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bowlWidth * 0.95, height: size * 0.22)
            .offset(y: -(size * 0.15))
            .opacity(rimVisible ? 1 : 0)
    }

    // MARK: - Reveal Sequence

    private func startReveal() {
        guard animated else {
            bowlExteriorVisible = true
            rimVisible = true
            brothVisible = true
            noodlesVisible = true
            beefVisible = true
            herbsVisible = true
            steamActive = true
            shimmerActive = true
            return
        }

        // 0.0s — bowl exterior
        withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
            bowlExteriorVisible = true
        }
        // 0.3s — rim
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            rimVisible = true
        }
        // 0.5s — broth (Task 2)
        withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.5)) {
            brothVisible = true
        }
        // 0.9s — noodles (Task 3)
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            noodlesVisible = true
        }
        // 1.2s — beef (Task 3)
        withAnimation(.spring(duration: 0.3, bounce: 0.2).delay(1.2)) {
            beefVisible = true
        }
        // 1.5s — herbs (Task 4)
        withAnimation(.spring(duration: 0.3, bounce: 0.25).delay(1.5)) {
            herbsVisible = true
        }
        // 1.8s — steam (Task 5)
        withAnimation(.easeIn(duration: 0.4).delay(1.8)) {
            steamActive = true
        }
        // 2.0s — shimmer (Task 2)
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(2.0)) {
            shimmerActive = true
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.05, blue: 0.03).ignoresSafeArea()
        PhoBowlView(size: 280, animated: true)
    }
}
```

Note: The exact Path control points above are starting estimates. You MUST visually tune them in the preview to get a natural bowl shape. The key is:
- The top arc should be wide and shallow (looking down at a slight angle)
- The bottom should curve inward to suggest the bowl's belly
- The overall silhouette should resemble a real ceramic pho bowl viewed from ~30 degrees above

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Check preview in Xcode**

Open PhoBowlView.swift in Xcode, check the preview canvas. Verify:
- Bowl shape looks like a ceramic bowl from above
- Tan-to-brown gradient gives ceramic feel
- Rim ellipse sits naturally at the top
- Shadow adds depth below

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoBowlView.swift
git commit -m "feat: add PhoBowlView with bowl exterior and rim layers"
```

---

## Task 2: Add broth surface layer (Layer 3)

**Files:**
- Modify: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

**Step 1: Add broth layer to the ZStack**

In `PhoBowlView`, add `brothLayer` to the ZStack after `rimLayer`:

```swift
// MARK: - Layer 3: Broth Surface

private var brothLayer: some View {
    ZStack {
        // Main broth fill
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [brothGold, brothDeep],
                    center: .center,
                    startRadius: 0,
                    endRadius: brothWidth * 0.5
                )
            )
            .frame(width: brothWidth, height: brothHeight)

        // Surface reflection highlight
        Ellipse()
            .fill(.white.opacity(0.12))
            .frame(width: brothWidth * 0.35, height: brothHeight * 0.3)
            .offset(
                x: shimmerActive ? 8 : -8,
                y: -(brothHeight * 0.15)
            )
            .blur(radius: 4)
    }
    .offset(y: -(size * 0.12))
    .scaleEffect(brothVisible ? 1.0 : 0.5)
    .opacity(brothVisible ? 1 : 0)
}
```

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Check preview**

Verify:
- Golden-amber broth ellipse fills inside the rim
- White shimmer highlight slowly drifts left-right after reveal
- Broth scales in from center during reveal

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoBowlView.swift
git commit -m "feat: add broth surface layer with shimmer to PhoBowlView"
```

---

## Task 3: Add noodles and beef layers (Layers 4-5)

**Files:**
- Modify: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

**Step 1: Add noodle layer**

Add `noodleLayer` to the ZStack after `brothLayer`:

```swift
// MARK: - Layer 4: Noodle Bed

private var noodleLayer: some View {
    // 5 wavy cream lines representing noodle strands
    ZStack {
        ForEach(0..<5, id: \.self) { i in
            NoodleStrandPath(
                index: i,
                areaWidth: brothWidth * 0.7,
                areaHeight: brothHeight * 0.5
            )
            .stroke(
                noodleCream.opacity(0.7 + Double(i % 3) * 0.1),
                style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round)
            )
            .frame(width: brothWidth * 0.7, height: brothHeight * 0.5)
        }
    }
    .offset(y: -(size * 0.08))
    .opacity(noodlesVisible ? 1 : 0)
    .offset(y: noodlesVisible ? 0 : 10)
}
```

Add the helper Shape for noodle strands:

```swift
// MARK: - Noodle Strand Path

private struct NoodleStrandPath: Shape {
    let index: Int
    let areaWidth: CGFloat
    let areaHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let yOffset = CGFloat(index) * (areaHeight / 5) + areaHeight * 0.1
        let amplitude = areaHeight * 0.08
        let startX = areaWidth * 0.05
        let endX = areaWidth * 0.95
        let midX = (startX + endX) / 2
        let phase = CGFloat(index) * 0.3

        path.move(to: CGPoint(x: startX, y: yOffset))
        path.addQuadCurve(
            to: CGPoint(x: midX, y: yOffset),
            control: CGPoint(x: startX + (midX - startX) * 0.5, y: yOffset - amplitude + phase * 3)
        )
        path.addQuadCurve(
            to: CGPoint(x: endX, y: yOffset),
            control: CGPoint(x: midX + (endX - midX) * 0.5, y: yOffset + amplitude - phase * 2)
        )
        return path
    }
}
```

**Step 2: Add beef layer**

Add `beefLayer` to the ZStack after `noodleLayer`:

```swift
// MARK: - Layer 5: Beef Slices

private var beefLayer: some View {
    ZStack {
        ForEach(0..<3, id: \.self) { i in
            beefSlice(index: i)
        }
    }
    .offset(y: -(size * 0.12))
    .scaleEffect(beefVisible ? 1.0 : 0.3)
    .opacity(beefVisible ? 1 : 0)
}

private func beefSlice(index: Int) -> some View {
    let rotations: [Double] = [-15, 5, 20]
    let offsets: [(x: CGFloat, y: CGFloat)] = [
        (-size * 0.08, -size * 0.02),
        (size * 0.05, size * 0.01),
        (size * 0.15, -size * 0.04)
    ]
    let sliceWidth = size * 0.1
    let sliceHeight = size * 0.055

    return ZStack {
        // Base slice
        RoundedRectangle(cornerRadius: sliceHeight * 0.3)
            .fill(
                LinearGradient(
                    colors: [beefPink, beefBrown],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: sliceWidth, height: sliceHeight)

        // Marbling lines
        ForEach(0..<2, id: \.self) { j in
            Path { path in
                let y = sliceHeight * (0.3 + CGFloat(j) * 0.35)
                path.move(to: CGPoint(x: sliceWidth * 0.15, y: y))
                path.addLine(to: CGPoint(x: sliceWidth * 0.85, y: y + sliceHeight * 0.05))
            }
            .stroke(.white.opacity(0.25), lineWidth: 0.5)
            .frame(width: sliceWidth, height: sliceHeight)
        }
    }
    .rotationEffect(.degrees(rotations[index]))
    .offset(x: offsets[index].x, y: offsets[index].y)
    .animation(
        .spring(duration: 0.3, bounce: 0.2).delay(1.2 + Double(index) * 0.08),
        value: beefVisible
    )
}
```

**Step 3: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 4: Check preview**

Verify:
- Cream noodle strands sit on the broth surface with gentle wave
- 3 beef slices with pink-brown gradient and white marbling lines
- Beef slices at different angles, scattered across noodle area
- Noodles slide in, beef bounces in during reveal

**Step 5: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoBowlView.swift
git commit -m "feat: add noodle bed and beef slice layers to PhoBowlView"
```

---

## Task 4: Add herb garnish layer (Layer 6)

**Files:**
- Modify: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

**Step 1: Add herbs layer**

Add `herbLayer` to the ZStack after `beefLayer`:

```swift
// MARK: - Layer 6: Herb Garnish & Lime

private var herbLayer: some View {
    ZStack {
        // Basil leaf 1
        basilLeaf
            .frame(width: size * 0.07, height: size * 0.09)
            .rotationEffect(.degrees(-25))
            .offset(x: size * 0.18, y: -(size * 0.18))

        // Basil leaf 2
        basilLeaf
            .frame(width: size * 0.055, height: size * 0.07)
            .rotationEffect(.degrees(15))
            .offset(x: size * 0.12, y: -(size * 0.1))

        // Lime wedge
        limeWedge
            .frame(width: size * 0.08, height: size * 0.06)
            .offset(x: -(size * 0.15), y: -(size * 0.15))

        // Bean sprout dots
        ForEach(0..<4, id: \.self) { i in
            Circle()
                .fill(noodleCream.opacity(0.6))
                .frame(width: size * 0.015, height: size * 0.015)
                .offset(
                    x: CGFloat([-0.05, 0.08, 0.2, -0.1][i]) * size,
                    y: CGFloat([-0.06, -0.14, -0.08, -0.16][i]) * size
                )
        }

        // Chili slice
        Capsule()
            .fill(
                LinearGradient(
                    colors: [chiliRed, chiliRed.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size * 0.06, height: size * 0.018)
            .rotationEffect(.degrees(35))
            .offset(x: size * 0.02, y: -(size * 0.17))
    }
    .scaleEffect(herbsVisible ? 1.0 : 0.01)
    .opacity(herbsVisible ? 1 : 0)
}

// MARK: - Basil Leaf Shape

private var basilLeaf: some View {
    ZStack {
        // Leaf body — teardrop
        Path { path in
            path.move(to: CGPoint(x: 0.5, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 0.5, y: 1),
                control: CGPoint(x: 1.1, y: 0.4)
            )
            path.addQuadCurve(
                to: CGPoint(x: 0.5, y: 0),
                control: CGPoint(x: -0.1, y: 0.4)
            )
            path.closeSubpath()
        }
        .fill(herbGreen)
        .scaleEffect(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height)  // Will be sized by frame

        // Center vein
        Path { path in
            path.move(to: CGPoint(x: 0.5, y: 0.1))
            path.addLine(to: CGPoint(x: 0.5, y: 0.85))
        }
        .stroke(herbGreen.opacity(0.5), lineWidth: 0.5)
    }
    // Note: use GeometryReader or pass size in to scale the Path properly.
    // Simpler approach: use a dedicated BasilLeafShape conforming to Shape.
}
```

**Important:** The basil leaf using raw Path coordinates (0-1 range) won't scale correctly with `.frame()`. Instead, create a proper `Shape`:

```swift
private struct BasilLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Teardrop: pointed top, wide middle, pointed bottom
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 1.1, y: h * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * -0.1, y: h * 0.4)
        )
        path.closeSubpath()
        return path
    }
}

private struct BasilLeafVeinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.85))
        return path
    }
}
```

Then replace `basilLeaf` with:

```swift
private var basilLeaf: some View {
    ZStack {
        BasilLeafShape()
            .fill(herbGreen)
        BasilLeafVeinShape()
            .stroke(herbGreen.opacity(0.4), lineWidth: 0.5)
    }
}
```

Similarly for the lime wedge:

```swift
private struct LimeWedgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Triangle-ish wedge with slight curve
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h),
            control: CGPoint(x: w * 0.5, y: h * 1.2)
        )
        path.closeSubpath()
        return path
    }
}
```

Then:
```swift
private var limeWedge: some View {
    ZStack {
        LimeWedgeShape()
            .fill(limeGreen)
        LimeWedgeShape()
            .fill(limeGreen.opacity(0.5))
            .scaleEffect(0.6)
            .offset(y: 2)
    }
}
```

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Check preview**

Verify:
- Two green basil leaves with center veins, different sizes and rotations
- Lime wedge in green with lighter inner segment
- Small cream dots for bean sprouts scattered around
- Red chili capsule slice
- All garnishes spring-bounce in during reveal

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoBowlView.swift
git commit -m "feat: add herb garnish and lime layer to PhoBowlView"
```

---

## Task 5: Add steam layer (Layer 7)

**Files:**
- Modify: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

**Step 1: Add steam layer**

Add `steamLayer` to the ZStack after `herbLayer`:

```swift
// MARK: - Layer 7: Steam

private var steamLayer: some View {
    ZStack {
        ForEach(0..<3, id: \.self) { i in
            SteamWisp(
                index: i,
                size: size,
                isActive: steamActive
            )
        }
    }
    .offset(y: -(size * 0.3))
    .allowsHitTesting(false)
}
```

Add the steam wisp as a private struct:

```swift
private struct SteamWisp: View {
    let index: Int
    let size: CGFloat
    let isActive: Bool

    @State private var drifting = false

    private var config: (xOffset: CGFloat, height: CGFloat, duration: Double, delay: Double) {
        let configs: [(CGFloat, CGFloat, Double, Double)] = [
            (-size * 0.06, size * 0.12, 3.0, 0.0),    // left wisp, shorter
            (0, size * 0.18, 3.5, 0.3),                // center wisp, tallest
            (size * 0.07, size * 0.14, 2.8, 0.6),      // right wisp, medium
        ]
        return configs[index % configs.count]
    }

    var body: some View {
        SteamWispShape(amplitude: size * 0.02)
            .stroke(
                .white.opacity(isActive ? 0.18 : 0),
                style: StrokeStyle(lineWidth: size * 0.015, lineCap: .round)
            )
            .frame(width: size * 0.06, height: config.height)
            .blur(radius: 3)
            .offset(
                x: config.xOffset,
                y: drifting ? -(config.height * 0.5) : 0
            )
            .opacity(drifting ? 0 : (isActive ? 0.9 : 0))
            .onAppear {
                guard isActive else { return }
                startDrift()
            }
            .onChange(of: isActive) { _, active in
                if active { startDrift() }
            }
    }

    private func startDrift() {
        withAnimation(
            .easeInOut(duration: config.duration)
                .repeatForever(autoreverses: false)
                .delay(config.delay)
        ) {
            drifting = true
        }
    }
}

private struct SteamWispShape: Shape {
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.5),
            control: CGPoint(x: w * 0.5 + amplitude, y: h * 0.75)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * 0.5 - amplitude, y: h * 0.25)
        )
        return path
    }
}
```

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Check preview**

Verify:
- 3 subtle white steam wisps rise from the bowl surface
- Wisps have S-curve shape, drift upward and fade
- Loop continuously with staggered timing
- Don't block touch events (allowsHitTesting false)

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Shared/PhoBowlView.swift
git commit -m "feat: add animated steam wisps to PhoBowlView"
```

---

## Task 6: Integrate PhoBowlView into CompletionView

**Files:**
- Modify: `PhoLife.swiftpm/Features/Completion/CompletionView.swift:216-245` (bowlSection)

**Step 1: Replace image-based bowl with PhoBowlView**

In `CompletionView.swift`, replace the `bowlSection` computed property (currently lines 216-245). Change:

```swift
// OLD — Remove this:
Image("completion-bowl")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 240, height: 240)
    .shadow(color: warmAmber.opacity(0.5), radius: 30)
    .shadow(color: .orange.opacity(0.2), radius: 60)
    .scaleEffect(bowlVisible ? 1.0 : 0.5)
    .opacity(bowlVisible ? 1 : 0)
    .accessibilityLabel("Your completed bowl of pho")
```

```swift
// NEW — Replace with:
PhoBowlView(size: 240, animated: true)
    .scaleEffect(bowlVisible ? 1.0 : 0.5)
    .opacity(bowlVisible ? 1 : 0)
```

Keep the radial glow `Circle()` that sits behind the bowl (lines 218-233) — it provides the warm ambient light effect behind the bowl. Only replace the `Image(...)` block.

**Step 2: Build to verify compilation**

Run build command. Expected: BUILD SUCCEEDED.

**Step 3: Run full app in simulator**

Build and run the full app. Play through to the completion screen. Verify:
- The SwiftUI bowl appears in the center column
- Layered reveal plays: bowl → rim → broth → noodles → beef → herbs → steam
- Bowl sits well within the 3-column layout (not too large, not too small)
- Radial glow behind the bowl still works
- Steam wisps loop smoothly
- Broth shimmer is visible
- "Cook Another Bowl" button still works

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Completion/CompletionView.swift
git commit -m "feat: replace completion-bowl image with SwiftUI PhoBowlView"
```

---

## Task 7: Visual polish and tuning

**Files:**
- Possibly adjust: `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`
- Possibly adjust: `PhoLife.swiftpm/Features/Completion/CompletionView.swift`

**Step 1: Run full app flow in simulator**

Build and run. Play through entirely: splash → story → minigames → completion. Focus on:
- Bowl shape proportions — does it look like a real pho bowl from above?
- Color harmony — do bowl colors work with the warm amber theme?
- Ingredient visibility — are noodles, beef, herbs clearly distinguishable?
- Animation timing — does the layered reveal feel natural and cinematic?
- Size in context — is 240pt the right size for the center column?

**Step 2: Tune as needed**

Common adjustments:
- Bowl shape: tweak Path control points for more natural curvature
- Broth color: adjust gold/amber values to match existing theme
- Ingredient positions: shift offsets so nothing overlaps awkwardly
- Animation timing: adjust delays in `startReveal()` for better pacing
- Steam opacity: increase if too subtle, decrease if distracting
- Size: try 220 or 260 if 240 doesn't feel right in the layout

**Step 3: Commit polish**

```bash
git add -A
git commit -m "polish: tune PhoBowlView proportions and animation timing"
```
