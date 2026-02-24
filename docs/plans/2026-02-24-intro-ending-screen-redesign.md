# Intro & Ending Screen Redesign — PhoLife

**Date:** 2026-02-24
**Status:** Approved

## Overview

Full redesign of the SplashView (intro) and CompletionView (ending) screens. The "Convergence" approach: ingredients animate inward toward a center bowl on the intro, and the ending shows a 3-column landscape layout with performance, hero bowl, and ingredient breakdown. Liquid Glass theme throughout, same warm color palette, custom SwiftUI ingredient icons reused across both screens.

## Constraints

- .swiftpm App Playground, iPad-only, iOS 26+, landscape
- 25 MB ZIP limit — custom SwiftUI shapes instead of image assets
- Swift 6 strict concurrency (@MainActor, @Observable)
- No force unwraps
- Fully offline

---

## Shared Component: Custom SwiftUI Ingredient Icons

A `PhoIngredientIcon` enum with 8 cases, each rendering a small SwiftUI shape (~30-40pt):

| Case | Visual | Built From |
|------|--------|-----------|
| `onion` | Two nested semicircles + green shoot | Path + Circle |
| `starAnise` | 8-pointed star | Path with computed points |
| `bone` | Capsule with rounded knob ends | Capsule + Circle |
| `pot` | Rounded rect + 3 wavy lines | RoundedRectangle + Path |
| `beefSlice` | Rounded rectangle + marbling lines | RoundedRectangle + Path |
| `fishSauce` | Small bottle silhouette | RoundedRectangle + Path triangle neck |
| `noodles` | 3-4 wavy parallel lines | Path |
| `herbs` | Teardrop leaf + center vein | Path |

Rendered in warm amber with soft glow. Reused on intro (floating animation) and ending (ingredient list).

## Shared Data: PhoIngredient Model

```swift
struct PhoIngredient: Identifiable {
    let id: Int
    let name: String
    let contribution: String
    let icon: PhoIngredientIcon
}
```

Static array of 8 entries:

1. Charred Onion & Ginger — Smoky depth and aromatic backbone
2. Whole Spices — Signature fragrance of star anise & cinnamon
3. Beef Bones — Rich collagen body and clear golden broth
4. Slow-Simmered Broth — Hours of gentle heat for deep umami
5. Paper-Thin Beef — Cooks to medium-rare from the hot broth
6. Fish Sauce & Rock Sugar — Savory-sweet seasoning balance
7. Fresh Rice Noodles — Silky foundation that carries the broth
8. Fresh Herbs & Garnish — Bright contrast: basil, lime, bean sprouts

---

## Section 1: Intro Screen (SplashView) Redesign

### Layout

Landscape 1194x834. Single ZStack, center-stage composition.

**Layers (back to front):**
1. Background: warm dark + breathing radial amber glow (existing style)
2. Ingredient ring: 8 custom icons starting at screen edges
3. Bowl: center, `splash-bowl` image, 300x300
4. Steam overlay: enhanced wisps (existing style, intensifies as ingredients arrive)
5. Title: "PhoLife" in liquid glass pill above bowl
6. Tagline: "The story of Vietnamese pho" below title

### Animation Timeline

```
0.0s  — Background + ambient glow begin
0.3s  — Bowl scales in (spring, 0.7 → 1.0)
0.5s  — First 2 ingredients float inward (onion, star anise)
0.8s  — Next 2 ingredients (bone, pot)
1.1s  — Next 2 ingredients (beef, fish sauce)
1.4s  — Last 2 ingredients (noodles, herbs)
1.5s  — Title "PhoLife" fades in with glass effect
2.0s  — Tagline fades in
2.0s  — Steam intensifies to full
2.5s  — All ingredients arrived, bowl pulses warmly
4.0s  — Exit transition (scale 1.08 + fade)
4.5s  — onComplete() fires
```

### Ingredient Float Animation

- Each ingredient starts at a designated edge position (spread around the screen perimeter)
- Animates along a curved path toward bowl center using offset animation with spring timing
- Trailing glow: small blurred circle behind each moving icon with slight delay
- On arrival: icon scales to 0, small particle burst (2-3 tiny circles that expand + fade)
- Each icon is ~30pt, warm amber, 50% opacity while floating → 100% near bowl

### Auto-advance

Total ~4.5s. Exit transition at 4.0s: scale to 1.08 + opacity to 0 over 0.5s.

---

## Section 2: Ending Screen (CompletionView) Redesign

### Layout

Three-column HStack:

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────────┐      ┌──────────────┐     ┌───────────┐  │
│  │PERFORMANCE│     │   Bowl Hero   │     │INGREDIENTS│  │
│  │          │      │  + Title      │     │           │  │
│  │ 8 rows   │      │  + Stars      │     │ 8 rows    │  │
│  │ w/ stars │      │  + Title      │     │ w/ icons  │  │
│  │ & scores │      │              │     │ & desc    │  │
│  │          │      │ [Cook Again]  │     │           │  │
│  └──────────┘      └──────────────┘     └───────────┘  │
└─────────────────────────────────────────────────────────┘
```

- Side panels: ~280pt wide, liquid glass containers
- Center column: fills remaining space

### Left Panel — Performance

- **Header:** "Your Performance" — warm amber, bold, 20pt
- **8 rows** (one per minigame):
  - Custom ingredient icon (matching the minigame step)
  - Minigame name — cream, 15pt
  - `StarRatingView(stars:, starSize: 18)` — non-animated, compact
  - Score — warm amber, 14pt, right-aligned
- **Footer row:** Divider + total stars + total score, slightly larger text
- Rows stagger in from left, 0.05s delay each

### Center Column — Hero Bowl

- `completion-bowl` image, 240x240, radial warm glow, spring scale-in (0.5 → 1.0)
- **"Your Bowl is Ready!"** — 36pt bold, warm amber gradient, liquid glass backing
- **Overall star rating** — `StarRatingView(animated: true, starSize: 40)`
- **Earned title** — italic, cream-to-amber gradient, capsule dividers
- **"Cook Another Bowl"** button — lower center, warm amber gradient capsule, pulse glow, liquid glass. Calls `resetForReplay()`
- Confetti layer for 2+ overall stars (existing style)

### Right Panel — Ingredients

- **Header:** "Bowl Ingredients" — warm amber, bold, 20pt
- **8 rows** (one per ingredient):
  - Custom SwiftUI ingredient icon
  - Ingredient name — cream, bold, 15pt
  - One-liner — white 60% opacity, 13pt
  - Each row is a VStack(name, description) with HStack(icon, VStack)
- Rows stagger in from right, 0.05s delay each

### Animation Timeline

```
0.0s  — Background + ambient glow
0.3s  — Bowl scales in with spring bounce
0.5s  — Title fades in
0.7s  — Stars reveal (animated), confetti starts (if earned)
0.9s  — Earned title slides in
1.0s  — Left panel glass container fades in
1.1s  — Left panel rows stagger in (0.05s each)
1.2s  — Right panel glass container fades in
1.3s  — Right panel rows stagger in (0.05s each)
1.6s  — "Cook Another Bowl" button springs in
2.0s  — Button pulse begins
```

---

## Files to Create/Modify

### New Files
- `Features/Shared/PhoIngredientIcon.swift` — Enum + SwiftUI shape views for 8 icons
- `Models/PhoIngredient.swift` — Data model with static array of 8 ingredients

### Modified Files
- `Features/Splash/SplashView.swift` — Full rewrite with convergence animation
- `Features/Completion/CompletionView.swift` — Full rewrite with 3-column layout

### Unchanged
- `GameState.swift`, `MinigameResult.swift`, `CulturalFact.swift` — No changes needed
- `GlassContainer.swift`, `StarRatingView.swift`, `ProgressBarView.swift` — Reused as-is
