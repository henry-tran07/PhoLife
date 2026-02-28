import SwiftUI

struct MinigameIntroCard: View {

    // MARK: - Input

    let minigameIndex: Int
    let onStart: () -> Void

    // MARK: - State

    @State private var cardVisible = false
    @State private var badgeVisible = false
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var dialogueVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false
    @State private var iconGlow = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlePhase: CGFloat = 0

    // Narrator dialogue state
    @State private var dialogueSegmentIndex = 0
    @State private var displayedCharCount = 0
    @State private var isTypewriting = false
    @State private var typewriterComplete = false
    @State private var showTapIndicator = false
    @State private var dialogueFinished = false

    // MARK: - Constants

    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC
    private let deepAmber = Color(red: 180 / 255, green: 120 / 255, blue: 60 / 255)

    private let descriptions: [String] = [
        "Char onions and ginger on a hot skillet — tap at just the right moment for the perfect sear.",
        "Dry-toast star anise, cinnamon, cloves, coriander, and cardamom until fragrant.",
        "Blanch beef bones in boiling water to remove impurities for a crystal-clear broth.",
        "Keep the broth at a gentle simmer for hours — never let it reach a rolling boil.",
        "Slice raw beef paper-thin — time each cut to get as many thin slices from the top as you can.",
        "Season with fish sauce, rock sugar, and salt — taste and adjust until balanced.",
        "Layer noodles, herbs, and raw beef in the bowl in the right order.",
        "Match each topping with its role to garnish your perfect bowl of ph\u{1EDF}."
    ]

    private let mechanicHints: [String] = [
        "Tap when the cursor hits the golden zone!",
        "Swipe to catch the right spices.",
        "Tap the bubbles before they escape.",
        "Hold to raise the heat, release to lower — stay in the green zone!",
        "Tap when the line is near the top for thinner slices!",
        "Adjust each slider to balance the flavors, then tap Taste!",
        "Tap the ingredients in the correct order!",
        "Flip cards to match each topping with its role!"
    ]

    private let stepIcons: [String] = [
        "flame",
        "star.circle",
        "bubbles.and.sparkles",
        "gauge.with.dots.needle.bottom.50percent",
        "scissors",
        "slider.horizontal.3",
        "square.stack.3d.down.right",
        "leaf"
    ]

    /// The two dialogue segments: cultural fact, then mechanic hint.
    private var dialogueSegments: [String] {
        let fact = (minigameIndex >= 0 && minigameIndex < CulturalFact.allFacts.count)
            ? CulturalFact.allFacts[minigameIndex].fact
            : "Prepare the next step."
        let hint = mechanicHints[safe: minigameIndex] ?? "Follow the on-screen prompts."
        return [fact, hint]
    }

    private var currentSegmentText: String {
        guard dialogueSegmentIndex < dialogueSegments.count else { return "" }
        return dialogueSegments[dialogueSegmentIndex]
    }

    private var currentExpression: NarratorExpression {
        isTypewriting ? .speak : .happy
    }

    /// Typewriter attributed string — unrevealed characters are transparent for stable layout.
    private var typewriterText: AttributedString {
        let text = currentSegmentText
        guard !text.isEmpty else { return AttributedString("") }
        var result = AttributedString(text)
        let total = text.count
        guard displayedCharCount < total else { return result }
        let visibleEnd = result.characters.index(result.startIndex, offsetBy: displayedCharCount)
        result[visibleEnd..<result.endIndex].foregroundColor = .clear
        return result
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background with warm vignette
            Color.black.opacity(cardVisible ? 0.65 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.5), value: cardVisible)

            // Warm ambient glow behind card
            RadialGradient(
                colors: [
                    warmAmber.opacity(cardVisible ? 0.12 : 0),
                    Color.clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.8), value: cardVisible)

            // Floating shimmer particles
            Canvas { context, size in
                let particleCount = 12
                for i in 0..<particleCount {
                    let progress = (particlePhase + CGFloat(i) / CGFloat(particleCount)).truncatingRemainder(dividingBy: 1.0)
                    let x = size.width * (0.2 + 0.6 * sin(CGFloat(i) * 1.8 + particlePhase * .pi))
                    let y = size.height * (1.0 - progress)
                    let alpha = sin(progress * .pi) * 0.35
                    let radius: CGFloat = 1.5 + sin(CGFloat(i) * 2.5) * 1.0

                    context.opacity = alpha
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(warmAmber)
                    )
                }
            }
            .ignoresSafeArea()
            .opacity(cardVisible ? 1 : 0)
            .allowsHitTesting(false)

            // Centered card
            VStack(spacing: 18) {
                // Step badge - premium gradient
                Text("Step \(minigameIndex + 1) of 8")
                    .font(.custom("SFCompactRounded-Bold", size: 13))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [warmAmber, deepAmber],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: warmAmber.opacity(0.4), radius: 8, y: 2)
                    )
                    .opacity(badgeVisible ? 1 : 0)
                    .offset(y: badgeVisible ? 0 : 12)

                // Cooking step icon with circular glow background
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [warmAmber.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(iconGlow ? 1.1 : 0.9)

                    // Subtle circle backing
                    Circle()
                        .fill(warmAmber.opacity(0.1))
                        .frame(width: 72, height: 72)

                    Circle()
                        .stroke(warmAmber.opacity(0.2), lineWidth: 1)
                        .frame(width: 72, height: 72)

                    Image(systemName: stepIcons[safe: minigameIndex] ?? "fork.knife")
                        .font(.custom("SFCompactRounded-Medium", size: 36))
                        .foregroundStyle(warmAmber)
                        .shadow(color: warmAmber.opacity(0.3), radius: 6)
                }
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(iconVisible ? 1 : 0.5)

                // Minigame title
                Text(minigameTitle)
                    .font(.custom("SFCompactRounded-Bold", size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [warmAmber, cream],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 12)

                // Narrator dialogue box
                HStack(alignment: .bottom, spacing: 10) {
                    NarratorPortraitView(expression: currentExpression, isSpeaking: isTypewriting)
                        .frame(width: 100, height: 100)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Narrator")
                            .font(.custom("SFCompactRounded-Bold", size: 16))
                            .foregroundStyle(warmAmber)

                        Text(typewriterText)
                            .font(.custom("SFCompactRounded-Medium", size: 18))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)

                        if showTapIndicator {
                            Text("\u{25BC}")
                                .font(.custom("SFCompactRounded-Regular", size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                                .modifier(IntroCardPulseModifier())
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .glassContainer()
                .opacity(dialogueVisible ? 1 : 0)
                .offset(y: dialogueVisible ? 0 : 12)
                .onTapGesture {
                    handleDialogueTap()
                }
                .task(id: dialogueSegmentIndex) {
                    await runTypewriter()
                }

                // Start button - premium warm gradient with pulse (shown after dialogue finishes)
                if dialogueFinished {
                    Button {
                        HapticManager.shared.heavy()
                        AudioManager.shared.playSFX("button-tap")
                        onStart()
                    } label: {
                        Text("Start")
                            .font(.custom("SFCompactRounded-Bold", size: 20))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 52)
                            .padding(.vertical, 15)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [warmAmber, deepAmber],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: warmAmber.opacity(buttonPulse ? 0.5 : 0.25), radius: buttonPulse ? 14 : 8, y: 3)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [cream.opacity(0.3), warmAmber.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(WarmScaleButtonStyle())
                    .accessibilityLabel("Start minigame")
                    .padding(.top, 8)
                    .opacity(buttonVisible ? 1 : 0)
                    .scaleEffect(buttonVisible ? (buttonPulse ? 1.04 : 1.0) : 0.85)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .frame(width: 500)
            .glassContainer()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [warmAmber.opacity(0.3), warmAmber.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Card entrance animation
            .scaleEffect(cardVisible ? 1 : 0.88)
            .blur(radius: cardVisible ? 0 : 6)
            .opacity(cardVisible ? 1 : 0)
        }
        .onAppear {
            cardVisible = false
            badgeVisible = false
            iconVisible = false
            titleVisible = false
            dialogueVisible = false
            buttonVisible = false
            buttonPulse = false
            iconGlow = false
            shimmerOffset = -200

            // Card entrance: scale up from center with blur clear
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
                cardVisible = true
            }

            // Stagger content reveal with cinematic timing
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.25)) {
                badgeVisible = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.38)) {
                iconVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.52)) {
                titleVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
                dialogueVisible = true
            }

            // Icon glow breathing
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6)) {
                iconGlow = true
            }

            // Particle drift
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                particlePhase = 1.0
            }
        }
    }

    // MARK: - Helpers

    private var minigameTitle: String {
        guard minigameIndex >= 0, minigameIndex < CulturalFact.allFacts.count else {
            return "Cooking Step"
        }
        return CulturalFact.allFacts[minigameIndex].minigameTitle
    }

    // MARK: - Typewriter

    private func runTypewriter() async {
        let text = currentSegmentText
        guard !text.isEmpty else { return }

        displayedCharCount = 0
        showTapIndicator = false
        typewriterComplete = false
        isTypewriting = true

        // Wait for entrance animations
        try? await Task.sleep(for: .milliseconds(400))

        let totalChars = text.count
        for i in 1...totalChars {
            if Task.isCancelled { return }

            if typewriterComplete {
                displayedCharCount = totalChars
                break
            }

            displayedCharCount = i

            let charIndex = text.index(text.startIndex, offsetBy: i - 1)
            let char = text[charIndex]
            if !char.isWhitespace && !".,!?;:—\u{2014}".contains(char) {
                AudioManager.shared.playSFX("text-blip-\(Int.random(in: 0...2))")
            }

            try? await Task.sleep(for: .milliseconds(25))
        }

        isTypewriting = false
        typewriterComplete = true

        try? await Task.sleep(for: .milliseconds(300))
        if Task.isCancelled { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            showTapIndicator = true
        }
    }

    // MARK: - Dialogue Tap

    private func handleDialogueTap() {
        if isTypewriting {
            // Skip to full text
            typewriterComplete = true
        } else if dialogueSegmentIndex < dialogueSegments.count - 1 {
            // Advance to next segment
            showTapIndicator = false
            dialogueSegmentIndex += 1
        } else {
            // Both segments done — show Start button
            showTapIndicator = false
            dialogueFinished = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                buttonVisible = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.3)) {
                buttonPulse = true
            }
        }
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Warm Scale Button Style (Enhanced)

struct WarmScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pulse Modifier

private struct IntroCardPulseModifier: ViewModifier {

    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.3 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameIntroCard(minigameIndex: 0, onStart: {})
    }
}
