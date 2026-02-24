import SwiftUI

struct MinigameIntroCard: View {

    // MARK: - Input

    let minigameIndex: Int
    let onStart: () -> Void

    // MARK: - State

    @State private var badgeVisible = false
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var descriptionVisible = false
    @State private var hintVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false

    // MARK: - Constants

    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC

    private let descriptions: [String] = [
        "Char halved onions and ginger on a smoking-hot skillet until deeply blackened.",
        "Dry-toast star anise, cinnamon, cloves, coriander, and cardamom until fragrant.",
        "Blanch beef bones in boiling water to remove impurities for a crystal-clear broth.",
        "Keep the broth at a gentle simmer for hours — never let it reach a rolling boil.",
        "Slice raw beef paper-thin against the grain so the hot broth cooks it instantly.",
        "Season with fish sauce, rock sugar, and salt — taste and adjust until balanced.",
        "Layer noodles, herbs, and raw beef in the bowl in the right order.",
        "Add fresh herbs, bean sprouts, lime, and chili to finish your perfect bowl."
    ]

    private let mechanicHints: [String] = [
        "Hold and release at the right moment.",
        "Swipe to catch the right spices.",
        "Tap the bubbles before they escape.",
        "Keep the flame steady — not too high, not too low.",
        "Swipe to slice at the correct angle.",
        "Drag the seasoning to hit the sweet spot.",
        "Drag ingredients into the bowl in order.",
        "Tap the fresh toppings as they appear."
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
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Centered card
            VStack(spacing: 16) {
                // Step badge
                Text("Step \(minigameIndex + 1) of 8")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(warmAmber.opacity(0.8), in: Capsule())
                    .opacity(badgeVisible ? 1 : 0)
                    .offset(y: badgeVisible ? 0 : 10)

                // Cooking step icon
                Image(systemName: stepIcons[safe: minigameIndex] ?? "fork.knife")
                    .font(.system(size: 44))
                    .foregroundStyle(warmAmber)
                    .opacity(iconVisible ? 1 : 0)
                    .scaleEffect(iconVisible ? 1 : 0.6)

                // Minigame title
                Text(minigameTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 10)

                // Cooking step description
                Text(descriptions[safe: minigameIndex] ?? "Prepare the next step.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(descriptionVisible ? 1 : 0)
                    .offset(y: descriptionVisible ? 0 : 10)

                // Divider
                Rectangle()
                    .fill(warmAmber.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .opacity(hintVisible ? 1 : 0)

                // Mechanic hint with icon
                Label(
                    mechanicHints[safe: minigameIndex] ?? "Follow the on-screen prompts.",
                    systemImage: "hand.tap"
                )
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .opacity(hintVisible ? 1 : 0)
                .offset(y: hintVisible ? 0 : 10)

                // Start button
                Button {
                    HapticManager.shared.heavy()
                    AudioManager.shared.playSFX("button-tap")
                    onStart()
                } label: {
                    Text("Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(warmAmber, in: Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Start minigame")
                .padding(.top, 8)
                .opacity(buttonVisible ? 1 : 0)
                .scaleEffect(buttonVisible ? (buttonPulse ? 1.03 : 1.0) : 0.9)
            }
            .padding(32)
            .frame(width: 500)
            .glassContainer()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(warmAmber.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            badgeVisible = false
            iconVisible = false
            titleVisible = false
            descriptionVisible = false
            hintVisible = false
            buttonVisible = false
            buttonPulse = false

            withAnimation(.easeOut(duration: 0.3)) {
                badgeVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.08)) {
                iconVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.16)) {
                titleVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.24)) {
                descriptionVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.32)) {
                hintVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.40)) {
                buttonVisible = true
            }
            // Start subtle pulse after button appears
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.8)) {
                buttonPulse = true
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameIntroCard(minigameIndex: 0, onStart: {})
    }
}
