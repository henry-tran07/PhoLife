# SwiftUI Pho Bowl Component — Design

**Date:** 2026-02-24
**Status:** Approved

## Overview

Replace the `completion-bowl` image asset on the completion screen with a fully SwiftUI-drawn pho bowl (`PhoBowlView`). Stylized/iconic aesthetic with layered reveal animation. 7 layers built from SwiftUI `Path`, `Ellipse`, `Capsule`, and gradient fills.

## Constraints

- .swiftpm App Playground, iPad-only, iOS 26+, landscape
- 25 MB ZIP limit — this change removes an image asset, saving space
- Swift 6 strict concurrency
- Must integrate with existing CompletionView 3-column layout (center column, 240pt)

---

## Component: PhoBowlView

### API

```swift
struct PhoBowlView: View {
    var size: CGFloat = 240
    var animated: Bool = true
}
```

### The 7 Layers (ZStack, back to front)

**Layer 1 — Bowl Exterior**
- Half-ellipse Path (bottom 60%) with wide shallow rim arc at top
- LinearGradient: warm tan (#C4956A) → darker brown (#8B6240)
- Shadow below for depth

**Layer 2 — Bowl Rim**
- Thin ellipse at top of bowl, ~6pt thick
- Lighter cream/tan gradient fill
- 3D "looking down into a bowl" perspective

**Layer 3 — Broth Surface**
- Filled ellipse inside the rim, slightly smaller
- RadialGradient: golden amber (#D4A050) center → deeper amber (#B8863A) edge
- White semi-transparent ellipse overlay for surface reflection
- Idle: reflection shifts x ±8pt, 3s easeInOut loop

**Layer 4 — Noodle Bed**
- 5-6 wavy Path curves (horizontal sine via addQuadCurve)
- Cream/off-white (#FFF5E0), opacity 0.7–0.9
- 2-3pt strokes, round line caps

**Layer 5 — Beef Slices**
- 3 small rounded rectangles (~20x12pt) with rotations (-15, 5, 20 degrees)
- Gradient: pink-red (#D4736A) → brownish (#A0594E)
- Thin white marbling lines inside each

**Layer 6 — Herb Garnish & Lime**
- 2 basil leaves: teardrop Path, green (#5DAA5D), center vein
- 1 lime wedge: arc/triangle, lime green (#A8D86A)
- Small cream circles for bean sprout cross-sections
- 1 small red chili: thin tapered capsule (#D44040)
- Scattered on right side and top edge

**Layer 7 — Steam**
- 3 wavy Path lines with addQuadCurve
- White, opacity 0.12–0.20, blur 3-4
- Idle: drift upward, fade, repeat forever with staggered timing

### Reveal Animation (animated == true)

```
0.0s  — Bowl exterior scales in (0.8→1.0, spring 0.5s)
0.3s  — Rim fades in (0.3s)
0.5s  — Broth fills from center (scale 0.5→1.0, 0.5s)
0.9s  — Noodles draw in (opacity+offset, 0.4s)
1.2s  — Beef slices drop in (scale+bounce, staggered 0.08s)
1.5s  — Herbs scatter in (spring bounce, staggered 0.06s)
1.8s  — Steam begins rising
2.0s  — Broth shimmer loop starts
```

### Size & Proportions (relative to `size` param)

- Bowl width: size * 1.0
- Bowl height: size * 0.6
- Broth ellipse: size * 0.82 wide, size * 0.28 tall
- All internal elements proportional

### Integration

In CompletionView.swift, replace `bowlSection`:
- Remove `Image("completion-bowl")` and its frame/shadow
- Insert `PhoBowlView(size: 240, animated: true)`
- Keep existing radial glow Circle behind it
- Keep `bowlVisible` controlling container opacity/scale
- Bowl's internal reveal triggers on appear

### Accessibility

- `.accessibilityLabel("Your completed bowl of Vietnamese pho with noodles, beef, and fresh herbs")`
- `.accessibilityAddTraits(.isImage)`

---

## Files

### New
- `PhoLife.swiftpm/Features/Shared/PhoBowlView.swift`

### Modified
- `PhoLife.swiftpm/Features/Completion/CompletionView.swift` (replace Image with PhoBowlView in bowlSection)
