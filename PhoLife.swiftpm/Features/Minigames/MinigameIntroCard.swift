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
    @State private var descriptionVisible = false
    @State private var hintVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false
    @State private var iconGlow = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlePhase: CGFloat = 0

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
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(warmAmber)
                        .shadow(color: warmAmber.opacity(0.3), radius: 6)
                }
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(iconVisible ? 1 : 0.5)

                // Minigame title
                Text(minigameTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
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

                // Cooking step description
                Text(descriptions[safe: minigameIndex] ?? "Prepare the next step.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(descriptionVisible ? 1 : 0)
                    .offset(y: descriptionVisible ? 0 : 12)

                // Divider with gradient
                HStack(spacing: 0) {
                    LinearGradient(colors: [Color.clear, warmAmber.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                    LinearGradient(colors: [warmAmber.opacity(0.35), Color.clear], startPoint: .leading, endPoint: .trailing)
                }
                .frame(height: 1)
                .padding(.horizontal, 20)
                .opacity(hintVisible ? 1 : 0)

                // Mechanic hint with icon
                Label(
                    mechanicHints[safe: minigameIndex] ?? "Follow the on-screen prompts.",
                    systemImage: "hand.tap"
                )
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(cream.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(hintVisible ? 1 : 0)
                .offset(y: hintVisible ? 0 : 10)

                // Start button - premium warm gradient with pulse
                Button {
                    HapticManager.shared.heavy()
                    AudioManager.shared.playSFX("button-tap")
                    onStart()
                } label: {
                    Text("Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
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
            descriptionVisible = false
            hintVisible = false
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
                descriptionVisible = true
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.78)) {
                hintVisible = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) {
                buttonVisible = true
            }

            // Icon glow breathing
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6)) {
                iconGlow = true
            }

            // Button pulse after it appears
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(1.3)) {
                buttonPulse = true
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameIntroCard(minigameIndex: 0, onStart: {})
    }
}
