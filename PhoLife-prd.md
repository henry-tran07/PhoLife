# Product Requirements Document
## PhoLife
### Apple Swift Student Challenge 2026

---

## 1. Overview

**App Name:** PhoLife
**Format:** `.swiftpm` App Playground
**Platform:** iPad (iOS 26+)
**Submission Deadline:** February 28, 2026, 11:59 PM PST
**Developer:** Henry

**One-Line Description (≤50 words):**
An immersive journey through the origins, history, and soul of Vietnamese phở — told through cinematic visual storytelling and a series of classic arcade-style minigames where players learn to craft an authentic bowl, one step at a time.

---

## 2. Problem Statement

Phở is one of the most recognized dishes in the world, yet most people outside Vietnam understand it only as "beef noodle soup." The centuries of history, the regional variations, the precise technique behind the broth, and phở's role as a symbol of Vietnamese resilience and identity are almost entirely unknown. Cultural knowledge is being flattened into a menu item.

This app preserves and transmits that cultural knowledge through two things humans can't resist: a great story and play.

---

## 3. Target User

Anyone curious about food and culture, with zero assumed knowledge of Vietnamese cuisine or cooking. The experience should be equally engaging for a 14-year-old who's never had phở and a Vietnamese-American who grew up eating it but never learned to make it. Primary context: iPad user exploring the app for the first time.

---

## 4. SSC Compliance Checklist

| Requirement | Implementation |
|---|---|
| `.swiftpm` format | Xcode 26 App Playground project |
| ≤ 25 MB ZIP | All assets generated via /nano-banana-pro, compressed, bundled locally |
| Fully offline | Zero network calls, no remote assets, no API dependencies |
| English content | All text and UI in English |
| Individual work | Solo project |
| AI disclosure | Document all Claude Code, /nano-banana-pro, and AI assistance in submission form |
| iPad-first | Designed and tested for iPad Simulator (landscape + portrait) |

---

## 5. Core Design Philosophy

PhoLife should feel like a **polished indie game**, not a school project. Every screen should make the user pause and think "this is beautiful." The storytelling phase should feel cinematic — like opening a gorgeous picture book or playing the intro to Monument Valley. The minigame phase should feel satisfying and tactile — like the best casual mobile games.

### Visual Standard
- Every illustration and sprite asset generated via **/nano-banana-pro** Claude Code skill
- Warm, rich, atmospheric art direction — think hand-painted textures, soft lighting, steam and depth
- Consistent visual language across story panels and minigame scenes
- Animations should feel fluid and alive — nothing static, nothing cheap

### Audio Standard
- **AVFoundation** drives all audio: ambient soundscapes, music, and per-action sound effects
- The story phase has its own musical identity (contemplative, warm, Vietnamese-inspired)
- Each minigame has distinct audio feedback that makes actions feel satisfying
- Audio is not decoration — it's 50% of the experience

### Interaction Standard
- Every tap, swipe, and hold should feel responsive with haptic feedback
- Transitions between screens should be animated and intentional
- No loading screens — seamless flow from story to gameplay to completion

---

## 6. App Structure

```
┌─────────────────────────────────────────────┐
│              LAUNCH / SPLASH                │
│    Cinematic animated phở bowl with steam   │
│    Title fades in over warm ambient light   │
└──────────────────┬──────────────────────────┘
                   ▼
┌─────────────────────────────────────────────┐
│       PHASE 1: THE STORY OF PHỞ            │
│   Immersive illustrated narrative           │
│   Cinematic pacing, parallax, animation     │
│   10+ panels telling the full journey       │
└──────────────────┬──────────────────────────┘
                   ▼
┌─────────────────────────────────────────────┐
│       PHASE 2: COOK YOUR PHỞ               │
│   8 sequential minigames                    │
│   Classic arcade mechanics                  │
│   Cultural teaching woven into each         │
└──────────────────┬──────────────────────────┘
                   ▼
┌─────────────────────────────────────────────┐
│          COMPLETION SCREEN                  │
│   Beautiful finished bowl reveal            │
│   Score + cultural facts + replay           │
└─────────────────────────────────────────────┘
```

---

## 7. Phase 1: The Story of Phở — The Cinematic Experience

This is not a text dump with pictures. This is the heart of the app. The storytelling should feel like the opening of a Pixar short or the intro sequence of a beautiful indie game. Every panel is a **scene** — with layered parallax, subtle animation, atmospheric audio, and minimal but powerful text.

### Design Principles for the Story
- **Show, don't tell.** The illustrations carry the emotion. Text is short, poetic, and punchy — never more than 2 sentences per panel.
- **Parallax depth on every panel.** Foreground, midground, background layers that shift as the user swipes. This creates a feeling of looking into a living world.
- **Animated elements in every scene.** Steam rising, flames flickering, people moving, rain falling, boats drifting. Nothing is a flat image.
- **Audio shifts per panel.** Each scene has its own ambient sound layer that crossfades as the user swipes.
- **Pacing is user-controlled.** Swipe to advance. No auto-advance, no timers. Let the user absorb each scene.
- **Liquid Glass** on text overlays and navigation elements for native iOS 26 feel.

### Story Panels

**Panel 1 — Title Card: "Every great bowl has a story."**
A single steaming bowl of phở, beautifully rendered, centered on screen. Steam rises in soft particle animation. Warm amber light. The text fades in slowly. Music begins — soft, contemplative, a single đàn tranh (Vietnamese zither) melody over ambient warmth.

*Ambient audio: Gentle simmering, distant kitchen sounds*

---

**Panel 2 — "Before it had a name"**
Scene: A misty early morning on the Red River Delta, Northern Vietnam, early 1900s. Water buffalo in rice paddies. A small village with wooden houses on stilts. Warm fog. Birds.

Text: *"In the villages along the Red River, Vietnamese cooks had been simmering bones and herbs for centuries. But the dish that would become phở didn't exist yet."*

*Animated elements: Mist drifting, water rippling, birds flying across background*
*Ambient audio: Morning birds, distant water, soft wind*

---

**Panel 3 — "Where worlds collided"**
Scene: A bustling Hanoi street in the French colonial era (~1910s-1920s). French colonial architecture alongside Vietnamese market stalls. A street vendor with a shoulder pole carrying two steaming pots (the original phở delivery system). European figures in the background, Vietnamese locals in the foreground.

Text: *"When the French arrived, they brought their appetite for beef. The bones they discarded became treasure in Vietnamese hands."*

*Animated elements: People walking, steam from vendor's pots, flickering oil lamp*
*Ambient audio: Street bustle, distant French accordion faintly mixed with Vietnamese market sounds*

---

**Panel 4 — "Alchemy in a pot"**
Scene: Close-up of a massive pot over an open flame. Charred onions and ginger being dropped in. Star anise, cinnamon, and cardamom floating. Bones submerged. The broth is golden and clear.

Text: *"Charred aromatics. Toasted spices. Beef bones simmered for hours. What emerged was unlike anything before — a broth that was light as water but deep as the earth."*

*Animated elements: Flames dancing, spices floating, steam billowing, broth color slowly deepening*
*Ambient audio: Fire crackling, liquid bubbling, the soft clink of a ladle*

---

**Panel 5 — "The streets came alive"**
Scene: A vibrant 1940s-50s Hanoi street food scene. Multiple phở vendors with their shoulder poles and small stools. Locals crouched on tiny plastic stools, slurping from bowls. Morning light streaming through narrow streets. Bicycles.

Text: *"Phở became the rhythm of Hanoi mornings. Vendors carried entire kitchens on their shoulders, and the city woke to the sound of broth ladled into bowls."*

*Animated elements: Steam from multiple bowls, people eating (subtle motion), bicycle passing through background*
*Ambient audio: Slurping sounds, ladle pouring, Vietnamese street vendor calls, morning city ambiance*

---

**Panel 6 — "A country divided"**
Scene: A split-screen composition. Left side: a stark, minimalist Northern phở bowl — clear broth, wide noodles, scallions, nothing more. Muted, cool tones. Right side: an overflowing Southern phở bowl — bean sprouts, Thai basil, hoisin, sriracha, lime wedges. Warm, saturated tones. A subtle line divides them (evoking the 17th parallel).

Text: *"In 1954, Vietnam was split in two. Phở split with it. The North kept it pure — just broth, noodles, and beef. The South made it abundant — herbs, sauces, and sweetness piled high."*

*Animated elements: Herbs gently swaying on the Southern side, steam rising differently on each side (thin wisps vs. billowing)*
*Ambient audio: Contrasting soundscapes — sparse, quiet on the North side; lively, busy on the South side*

---

**Panel 7 — "Carried across oceans"**
Scene: A dramatic ocean scene. A boat filled with Vietnamese refugees on dark water, a distant coastline glowing with lights ahead. One figure holds a small wrapped bundle close — the suggestion of something precious brought from home. Stars overhead.

Text: *"After 1975, over a million Vietnamese fled by sea. They couldn't carry much. But they carried their recipes — and the memory of home in a bowl."*

*Animated elements: Waves gently rocking the boat, stars twinkling, distant shore lights flickering*
*Ambient audio: Ocean waves, wind, a faint lullaby melody on the đàn tranh*

---

**Panel 8 — "New roots"**
Scene: A warm, glowing Vietnamese restaurant in a Western city (could be Houston, San Jose, Sydney, Paris). The neon "PHỞ" sign in the window. Inside, a multigenerational family — grandmother ladling broth, parents serving, kids eating. Through the window, you can see it's snowing or raining outside, but inside is warm.

Text: *"In Houston, Sydney, Paris, and San Jose, phở restaurants became anchors. The first taste of home in a new country. The place where communities rebuilt."*

*Animated elements: Neon sign flickering softly, snow/rain outside window, steam from kitchen visible, warm interior glow*
*Ambient audio: Muffled rain/city outside, warm indoor restaurant hum, family chatter, clinking bowls*

---

**Panel 9 — "More than soup"**
Scene: A single beautiful bowl of phở, slowly being assembled in a cinematic sequence — noodles placed, brisket layered, raw beef draped, broth poured in a golden stream, garnishes placed with care. Each element appears one at a time with intention.

Text: *"Phở is not soup. It is patience simmered into broth. History ladled into a bowl. A culture you can taste."*

*Animated elements: Full assembly animation — each ingredient appearing with a satisfying motion and sound. Steam crescendo at the end.*
*Ambient audio: Each ingredient has its own sound — noodles sliding, meat placing, the satisfying pour of broth, final garnish rustle*

---

**Panel 10 — "Your turn"**
Scene: An empty bowl, perfectly lit, waiting. A pair of hands (the user's) visible at the bottom of frame. Cooking tools arranged around the bowl. The kitchen is set up. Everything is ready.

Text: *"Now you know the story. Time to make the bowl."*

CTA: **"Let's Cook"** button — large, warm, inviting. Liquid Glass styling. Haptic pulse on tap.

*Ambient audio: Music builds to a warm, energetic transition. The simmering fades up.*

---

### Story Phase Technical Notes
- All panel illustrations generated via **/nano-banana-pro** Claude Code skill
- Each panel is a SwiftUI view with layered `Image` views for parallax (offset modified by drag gesture or `ScrollView` position)
- Animated elements use SpriteKit particle systems (steam, fire, rain, snow) embedded via `SpriteView`, or SwiftUI animations for simpler motion (fade, slide, scale)
- Audio crossfades managed by `AudioManager` service using AVFoundation — each panel has an associated audio layer that fades in/out on transition
- Text uses SF Pro Rounded, animated with `.opacity` and `.offset` transitions
- Liquid Glass applied to text containers via native iOS 26 `.glass()` modifier or equivalent

---

## 8. Phase 2: Minigame Sequence — Detailed Spec

### Global Minigame Rules
- Each minigame has a **brief intro card** explaining the real cooking step and the game mechanic — styled as a recipe card with hand-drawn feel
- Scoring: 1-3 stars per minigame based on performance
- A **cultural fact** overlays on the score reveal screen after each minigame (no separate transition screen)
- Animated progress bar showing the 8 steps, current step highlighted, styled as a recipe timeline
- If the player "fails" a minigame, they can retry or skip — no hard blocking (judges must experience the full app)
- **Every minigame has distinct audio:** ambient cooking sounds + action-specific sound effects + satisfying completion chime
- **Every minigame has particle effects** appropriate to the cooking step (steam, smoke, sparks, splashes)
- All sprite assets generated via **/nano-banana-pro**

### Minigame 1: Char the Aromatics
**Real step:** Char halved onions and sliced ginger cut-side down on a dry smoking-hot skillet.

| Attribute | Detail |
|---|---|
| Mechanic | Hold-and-release timing (power meter) |
| Input | Tap and hold on each ingredient |
| Goal | Release when the heat meter is in the green "perfect char" zone |
| Fail state | Burned (held too long) or raw (released too early) |
| Items | 2 onion halves + 2 ginger slices = 4 rounds |
| Visual | Skillet with visible heat shimmer. Ingredient darkens progressively. Smoke particles increase with heat. Perfect char = golden-brown with visible grill marks. Burn = black with heavy smoke. |
| Audio | Sizzle starts on touch, intensifies. Perfect release = satisfying "tsss." Burn = harsh sizzle + alarming tone. |
| Cultural lesson | "Charring aromatics adds a subtle smoky depth — a secret step that separates authentic phở from imitations." |
| SpriteKit needs | Heat meter bar, progressive char texture animation, smoke/steam particle systems, heat shimmer shader |

### Minigame 2: Toast the Spices
**Real step:** Dry-toast star anise, cinnamon, cardamom, cloves, and coriander seeds in a skillet.

| Attribute | Detail |
|---|---|
| Mechanic | Swipe to catch (Fruit Ninja style) |
| Input | Swipe across correct spices as they fly across screen |
| Goal | Catch all 5 correct spices, avoid wrong ones |
| Correct spices | Star anise, cinnamon quill, cardamom pod, cloves, coriander seeds |
| Decoys | Paprika, cumin, turmeric, oregano, black pepper |
| Penalty | Wrong swipe loses a point; 3 wrong = restart |
| Visual | Warm kitchen background. Spices tumble upward from the bottom (tossed from a pan). Correct catches burst into golden sparkle. Wrong catches flash red. Swipe trail leaves a warm golden arc. |
| Audio | Whoosh on swipe. Warm chime on correct catch. Buzzer on wrong. Faint toasting/crackling ambient. |
| Cultural lesson | "These five spices are the signature of phở's fragrance. Star anise and cinnamon dominate — you'll recognize them in every bowl." |
| SpriteKit needs | Physics-based throwing arcs, swipe trail particle effect, spice sprite assets (each visually distinct), burst animations |

### Minigame 3: Clean the Bones
**Real step:** Boil bones/brisket 5 minutes, drain, rinse under tap water to remove impurities (scum).

| Attribute | Detail |
|---|---|
| Mechanic | Whack-a-Mole — tap rising bubbles |
| Input | Tap scum bubbles as they rise to surface |
| Goal | Skim 80%+ of bubbles before they sink back |
| Difficulty curve | Bubbles speed up and multiply over time |
| Visual | Large pot seen from above. Murky brown water. Each tapped bubble pops with a splash. As score increases, water gradually transitions from murky to crystal clear. Satisfying visual payoff. |
| Audio | Bubbling water ambient. Pop sound on each tap (varied pitch). Watery splash. Clarity "sparkle" sound as water clears. |
| Cultural lesson | "This blanching step is why phở broth is crystal clear. Skipping it means cloudy, murky soup — the mark of a careless cook." |
| SpriteKit needs | Bubble physics (random spawn, float upward, variable speed), water color transition shader/overlay, pop splash particle effect, clarity sparkle effect |

### Minigame 4: Simmer the Broth
**Real step:** Simmer bones, brisket, aromatics, and spices for 3 hours at low, steady heat.

| Attribute | Detail |
|---|---|
| Mechanic | Zone keeper (Flappy Bird / balance game) |
| Input | Tap to raise flame, release to lower |
| Goal | Keep temperature in the "simmer" zone for the full duration |
| Fail states | Too high = rolling boil (broth goes cloudy, bubbles explode). Too low = no extraction (bubbles stop, broth grays out) |
| Difficulty curve | Target zone narrows over time; random gusts affect flame |
| Visual | Side view of pot on stove. Flame animated below. Broth surface shows variable bubble activity matching temperature. A beautiful golden broth when in zone vs. angry roiling when too hot vs. still and grey when too cold. |
| Audio | Gentle simmer bubbling when in zone. Aggressive boiling when too hot. Silence/flat tone when too cold. Subtle musical cue rewards sustained time in zone. |
| Cultural lesson | "Great phở broth is never rushed. A gentle 3-hour simmer extracts deep flavor while keeping the broth clear. A rolling boil makes it cloudy and bitter." |
| SpriteKit needs | Flame animation (multi-frame, variable intensity), thermometer/gauge UI, pot with variable bubble particle system, steam particles scaling with heat |

### Minigame 5: Slice the Beef
**Real step:** Partially freeze beef tenderloin, then slice paper-thin for raw topping.

| Attribute | Detail |
|---|---|
| Mechanic | Precision slicing (swipe rhythm game) |
| Input | Horizontal swipes across the beef |
| Goal | Slice as thinly and evenly as possible |
| Scoring | Thinner + more even = higher score. Each slice falls away satisfyingly, revealing a cross-section |
| Visual | Cutting board with beautiful wood grain texture. Beef positioned center. Each swipe animates a knife pass. Sliced pieces fall and fan out like cards. Thickness comparison shown visually after each cut. |
| Audio | Sharp, satisfying "thwk" on each slice (pitch varies with quality). Knife on wood. Subtle rhythm/beat that rewards even timing. |
| Cultural lesson | "Paper-thin raw beef is placed on top so the boiling broth cooks it to perfect medium-rare when ladled over. Too thick, and it stays chewy." |
| SpriteKit needs | Cutting board + beef sprite, knife slash effect, slice separation physics (pieces fan out), thickness measurement overlay |

### Minigame 6: Season the Broth
**Real step:** Add fish sauce, adjust salt and sugar until "beefy, fragrant, savoury and barely sweet."

| Attribute | Detail |
|---|---|
| Mechanic | Slider mixing / balancing game |
| Input | Drag 3 sliders: fish sauce, salt, sugar |
| Goal | Hit the target flavor profile zone (savory-dominant, salt-supporting, sugar-minimal) |
| Visual | A beautiful bowl of broth in the center. Color and "energy" of the broth shifts as sliders move — too much sugar makes it glow amber/sweet, too much salt makes it harsh/white, perfect fish sauce makes it warm golden. A flavor harmony meter visualizes balance. |
| Audio | Each slider has a tonal quality — fish sauce is a deep warm hum, salt is a bright ping, sugar is a soft chime. When balanced, they harmonize into a chord. When off, they're dissonant. |
| Cultural lesson | "Fish sauce, not soy sauce, is the backbone of phở seasoning. The Vietnamese flavor philosophy balances savory, salty, sweet, sour, and spicy — with savory always leading." |
| SpriteKit needs | Custom slider UI, animated broth color/effect transitions, flavor harmony meter with visual feedback, particle aura around broth |

### Minigame 7: Assemble the Bowl
**Real step:** Noodles in bowl first, then brisket slices, then raw beef on top, then ladle hot broth over.

| Attribute | Detail |
|---|---|
| Mechanic | Drop stacking / layering game (tower builder tap game) |
| Input | Tap to drop each ingredient into the bowl at the right moment |
| Goal | Layer in correct order: noodles → brisket → raw beef → broth pour |
| Wrong order penalty | Visual feedback shows why it's wrong (e.g., raw beef buried = "this won't cook!") |
| Visual | Beautiful empty bowl. Each ingredient hovers above, swaying. Tap to drop. They settle satisfyingly. The final broth pour is the **hero moment** — a golden stream that fills the bowl, steam erupts, and the raw beef visibly changes from red to pink in real-time. The most cinematic moment in the game. |
| Audio | Each ingredient has a landing sound (noodles = soft pile, meat = gentle thud, broth = gorgeous pour). The broth pour gets its own extended audio moment — a 2-second satisfying ladle pour with rising steam hiss. Musical payoff. |
| Cultural lesson | "Order matters. Raw beef goes on top so the boiling broth hits it directly, cooking it to medium-rare in seconds. Bury it under noodles and it stays raw." |
| SpriteKit needs | Ingredient hover/sway animation, drop physics, bowl layering with depth, broth fill fluid animation, beef color-change animation (red → pink), massive steam particle burst |

### Minigame 8: Top It Off
**Real step:** Serve with bean sprouts, Thai basil, cilantro, lime wedges, chili, hoisin, and sriracha on the side.

| Attribute | Detail |
|---|---|
| Mechanic | Memory match (card flip) |
| Input | Tap cards to flip, find matching pairs |
| Pairs | 6 toppings matched to their role: bean sprouts ↔ "crunch & freshness", Thai basil ↔ "aromatic sweetness", cilantro ↔ "bright herbiness", lime ↔ "acidity & brightness", hoisin ↔ "rich sweetness", sriracha ↔ "heat & kick" |
| Visual | Cards styled as beautiful hand-painted tiles. Flip animation is smooth and weighty. Matched pairs glow and float to the bowl (which is visible in the background). As matches complete, the bowl fills with toppings. Final match = fully topped bowl, gorgeous. |
| Audio | Card flip = satisfying click. Match = warm chime + specific topping sound (herb rustle, lime squeeze, sauce squirt). Mismatch = soft thud. Final match = celebratory musical flourish. |
| Cultural lesson | "Phở toppings are always served on the side — the eater customizes every bowl to their own taste. That's the communal philosophy of Vietnamese dining." |
| SpriteKit needs | Card flip animation (3D rotation effect), match glow, topping-to-bowl float animation, completed bowl composition |

---

## 9. Completion Screen

### The Reveal
The screen opens with the user's completed bowl of phở — rendered in full beauty, centered, with steam particle effects rising. The camera slowly pulls back (scale animation) to reveal the bowl on a table setting with chopsticks, a spoon, and the side toppings plate. This should feel like the money shot in a food film.

### Score Summary
- Total stars earned (out of 24)
- Visual star display per minigame (mini icons along a recipe timeline)
- Earned title based on performance:
  - 0-8 stars: "Street Food Curious"
  - 9-16 stars: "Hanoi Home Cook"
  - 17-21 stars: "Saigon Street Vendor"
  - 22-24 stars: "Phở Master"

### Cultural Facts Carousel
Swipeable carousel of the 8 cultural facts learned — one per minigame, with the associated illustration. Reinforces what the player learned through play.

### Replay
**"Cook Another Bowl"** button — restarts from minigame 1 (skipping story). Allows the player to improve their score.

### Audio
Warm, resolved musical cue. Ambient steam and restaurant sounds. A feeling of accomplishment and warmth.

---

## 10. Technical Architecture

### Frameworks

| Framework | Usage |
|---|---|
| **SwiftUI** | App shell, navigation, story panels, completion screen, Liquid Glass styling, text animations, transitions |
| **SpriteKit** | All 8 minigames via `SpriteView`, story panel particle effects (steam, fire, rain, snow, sparkles), animated elements |
| **AVFoundation** | Full audio system: ambient soundscapes per story panel, background music, per-action sound effects in minigames, audio crossfading between scenes |

### Asset Generation
All visual assets — story panel illustrations, sprite sheets, backgrounds, UI elements, card art — generated via **/nano-banana-pro** Claude Code skill. Assets should maintain a consistent warm, hand-painted visual style across the entire app.

### Architecture Pattern
MVVM with `@Observable`

```
Sources/
├── App/
│   └── PhoLifeApp.swift              # @main entry point
├── Models/
│   ├── GameState.swift                # Overall game progress, scores, current phase
│   ├── MinigameResult.swift           # Per-minigame score/stars
│   ├── StoryPanel.swift               # Panel content model (text, image layers, audio)
│   └── CulturalFact.swift             # Data model for facts
├── Features/
│   ├── Splash/
│   │   └── SplashView.swift           # Animated launch screen
│   ├── Story/
│   │   ├── StoryView.swift            # Scrollable panel container with parallax
│   │   ├── StoryPanelView.swift       # Individual panel with layered images + text
│   │   └── ParallaxModifier.swift     # Custom ViewModifier for parallax depth
│   ├── Minigames/
│   │   ├── MinigameContainerView.swift     # Hosts SpriteView + intro/score cards
│   │   ├── MinigameIntroCard.swift         # Recipe-card styled intro overlay
│   │   ├── MinigameScoreCard.swift         # Star reveal + cultural fact overlay
│   │   ├── CharAromaticsScene.swift        # SpriteKit scene
│   │   ├── ToastSpicesScene.swift
│   │   ├── CleanBonesScene.swift
│   │   ├── SimmerBrothScene.swift
│   │   ├── SliceBeefScene.swift
│   │   ├── SeasonBrothScene.swift
│   │   ├── AssembleBowlScene.swift
│   │   └── TopItOffScene.swift
│   ├── Completion/
│   │   ├── CompletionView.swift       # Final bowl reveal + score + facts carousel
│   │   └── BowlRevealAnimation.swift  # The cinematic bowl reveal sequence
│   └── Shared/
│       ├── ProgressBarView.swift      # 8-step recipe timeline indicator
│       ├── StarRatingView.swift       # Reusable star display
│       └── GlassContainer.swift       # Liquid Glass styled container
├── Services/
│   ├── AudioManager.swift             # AVFoundation: playback, crossfading, sound effects
│   ├── GameEngine.swift               # Score tracking, state transitions, progression
│   └── HapticManager.swift            # UIImpactFeedbackGenerator wrapper
└── Resources/
    ├── Assets.xcassets/               # All /nano-banana-pro generated illustrations + sprites
    ├── Sounds/
    │   ├── Music/                     # Background tracks (.m4a, compressed)
    │   ├── Ambient/                   # Per-panel ambient layers (.m4a)
    │   └── SFX/                       # Sound effects (.caf or .m4a)
    └── Data/
        └── CulturalFacts.json         # Static fact content
```

### Asset Budget (25 MB ZIP limit)

| Category | Estimated Size | Notes |
|---|---|---|
| Story illustrations (10 panels × 3 parallax layers) | ~8 MB | /nano-banana-pro generated, compressed PNG, consistent style |
| Sprite assets (8 minigames) | ~4 MB | Ingredient sprites, backgrounds, UI elements, cards |
| Music tracks | ~3 MB | 2-3 compressed .m4a loops (story, gameplay, completion) |
| Ambient audio layers | ~2 MB | Per-panel ambient, compressed short loops |
| Sound effects | ~1.5 MB | ~30-40 short .caf files for minigame actions |
| SF Symbols | 0 MB | Built into iOS |
| Code + metadata | ~1 MB | Swift source, Package.swift, asset catalogs |
| **Total estimated** | **~19.5 MB** | **~5.5 MB headroom** |

---

## 11. Audio Design — Full Specification

Audio is a first-class feature of PhoLife, not an afterthought. The `AudioManager` service handles three simultaneous audio layers:

### Layer 1: Music
- **Story phase:** Warm, contemplative Vietnamese-inspired instrumental. đàn tranh (zither) melody over soft pads. Emotional, not busy. Loops seamlessly.
- **Minigame phase:** Upbeat but not frantic. Percussive, playful energy. Shifts slightly per minigame to match intensity.
- **Completion:** Resolved, warm, celebratory. A sense of accomplishment.
- All music royalty-free or original. Compressed .m4a, target ~1 MB per track.

### Layer 2: Ambient
- Each story panel has a unique ambient layer (street sounds, ocean waves, rain, restaurant hum, simmering broth)
- Crossfade between panels using AVFoundation player queuing
- Minigames have cooking-specific ambient (bubbling pot, sizzling skillet, kitchen background)

### Layer 3: Sound Effects
- Every user interaction has audio feedback — taps, swipes, holds, releases, successes, failures
- Each minigame has ~4-6 unique SFX
- Effects should be short (< 1 second), satisfying, and tactile
- Haptic feedback (UIImpactFeedbackGenerator) paired with key sound effects for multi-sensory response

### Audio Source Strategy
- Royalty-free sound libraries (freesound.org, mixkit.co) for SFX and ambient
- Music: royalty-free Vietnamese-inspired instrumental tracks, or generate using AI music tools (disclose in submission)
- All audio bundled locally, no streaming

---

## 12. Design Language

### Visual Identity
- **Color palette:** Warm ambers (#D4A574), deep reds (#8B2500), cream whites (#FFF8DC), rich browns (#5C3317), fresh green accents (#4CAF50 for herbs), golden broth (#DAA520)
- **Typography:** SF Pro Rounded for headings (warm, approachable), SF Pro for body text. Story panel text is larger, more cinematic. Minigame UI text is compact and clear.
- **Illustration style:** Hand-painted / watercolor aesthetic generated by /nano-banana-pro. Warm lighting, soft edges, atmospheric depth. Consistent across all panels and minigame backgrounds.
- **Liquid Glass:** Applied to text overlays in story panels, navigation controls, progress bar, intro/score cards, and CTA buttons. Native iOS 26 treatment.
- **Iconography:** SF Symbols for UI controls. Custom /nano-banana-pro generated icons for the 8 minigame steps in the progress bar.

### Accessibility
- Dynamic Type support on all text
- VoiceOver labels on all interactive elements, illustrations, and game objects
- Sufficient color contrast (WCAG AA minimum)
- Haptic feedback on all minigame interactions
- No reliance on color alone for scoring (stars + numeric + title)
- Audio cues paired with visual feedback (never audio-only information)

---

## 13. Essay Strategy (≤500 words)

### Framework: FPP (Place → Problem → Feature)

**Place:** Vietnamese culture and cuisine are globally beloved but poorly understood. Phở is ordered in restaurants worldwide but its history, technique, and cultural meaning are almost entirely unknown to non-Vietnamese diners.

**Problem:** Cultural knowledge about traditional foods is being flattened — reduced to a menu item stripped of context. Young people, including Vietnamese-Americans, are losing connection to the stories behind their heritage dishes.

**Feature:** PhoLife preserves and transmits cultural knowledge through cinematic storytelling and play. The story phase immerses users in phở's journey from colonial Hanoi to the global diaspora. Each minigame teaches a real step in authentic phở preparation through familiar arcade mechanics, making the learning effortless and memorable. Players don't just learn about phở — they understand why every step matters.

**Framework choices to highlight:**
- SpriteKit for tactile, physics-based minigames that make cooking steps visceral and satisfying
- SwiftUI with Liquid Glass for a native iOS 26 experience that feels polished and modern
- AVFoundation for full audio immersion — the sounds of cooking, culture, and storytelling are integral to the experience, not decoration
- Parallax storytelling with layered illustration and ambient audio to create an emotional, cinematic narrative

**Personal connection:** [Henry — this paragraph is the most important thing in your entire submission. Write it yourself from the heart.]

---

## 14. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Exceeds 25 MB | Medium | Fatal | Asset budget tracked. /nano-banana-pro images compressed. Audio aggressively compressed. Test ZIP after every asset batch. |
| /nano-banana-pro style inconsistency | Medium | High | Define a strict style prompt template. Generate all story panels in one session for consistency. Review and regenerate outliers. |
| SpriteKit + SwiftUI performance issues | Medium | High | Keep particle counts conservative. Profile with Instruments. Reuse textures. Limit simultaneous SpriteView instances. |
| Audio memory pressure | Low | Medium | Use streaming playback for music, not preloading. Short SFX loaded on demand. Test on iPad Simulator. |
| App crashes during judging | Low | Fatal | No force unwraps. Graceful error handling in every scene transition. Test on clean Simulator install. Kill and relaunch test. |
| Minigames feel too similar | Medium | Medium | 8 distinct mechanics (timing, swiping, tapping, balancing, precision, mixing, stacking, matching). Playtest for variety. |
| Story feels too long for judges | Medium | Medium | Add "Skip to Cook" button visible on every panel. Judges who want to see gameplay can jump ahead. |
| Parallax performance on complex panels | Low | Medium | Limit to 3 layers per panel. Use compressed PNGs, not vectors for complex illustrations. Test scrolling performance. |

---

## 15. Development Milestones

| Milestone | Deliverable |
|---|---|
| **M1: Scaffold** | `.swiftpm` created, CLAUDE.md written, MCP servers configured, Git repo, project structure from Section 10 |
| **M2: Audio infrastructure** | `AudioManager` service built — music playback, ambient crossfading, SFX triggering all working |
| **M3: Story phase** | All 10 story panels with /nano-banana-pro illustrations, parallax scrolling, text animations, audio per panel, "Skip to Cook" button |
| **M4: Minigame framework** | `MinigameContainerView`, intro cards, score cards, progress bar, star system, game state management |
| **M5: Minigames 1-4** | Char Aromatics, Toast Spices, Clean Bones, Simmer Broth — playable with scoring, audio, and particles |
| **M6: Minigames 5-8** | Slice Beef, Season Broth, Assemble Bowl, Top It Off — playable with scoring, audio, and particles |
| **M7: Completion screen** | Bowl reveal animation, score summary, facts carousel, replay, earned title |
| **M8: Polish** | Liquid Glass styling, transition animations, haptics, accessibility pass (VoiceOver, Dynamic Type, contrast) |
| **M9: Asset pass** | Review all /nano-banana-pro assets for consistency, regenerate outliers, compress everything, verify ZIP ≤ 25 MB |
| **M10: Final test** | Full playthrough on iPad Simulator offline. Cold launch. Kill and relaunch. Both orientations. No crashes. |
| **M11: Submit** | ZIP exported, essays written, AI disclosure completed, proof of enrollment uploaded |

---

## 16. Open Questions

1. **Personal story:** What is Henry's personal connection to phở / Vietnamese culture? This is the single highest-leverage element of the entire submission.
2. **Audio sourcing:** Royalty-free libraries? Original recordings? AI-generated music (must disclose)?
3. **Regional focus:** Should the minigames teach Northern phở, Southern phở, or reference both? (The story already covers both.)
4. **Replay value:** Should different runs randomize elements (decoy spices, difficulty scaling) or is a single polished run sufficient?
5. **Orientation:** Lock to landscape (more cinematic for story panels) or support both? Landscape is recommended for the story experience.
6. **Story panel count:** 10 panels is ambitious for assets. Could trim to 8 if /nano-banana-pro generation or 25 MB budget becomes tight.
