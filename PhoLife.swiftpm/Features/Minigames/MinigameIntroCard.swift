import SwiftUI

struct MinigameIntroCard: View {

    // MARK: - Input

    let minigameIndex: Int
    let onStart: () -> Void

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

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Centered card
            VStack(spacing: 20) {
                // Minigame title
                Text(minigameTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
                    .multilineTextAlignment(.center)

                // Cooking step description
                Text(descriptions[safe: minigameIndex] ?? "Prepare the next step.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Mechanic hint
                Text(mechanicHints[safe: minigameIndex] ?? "Follow the on-screen prompts.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                // Start button
                Button {
                    HapticManager.shared.heavy()
                    onStart()
                } label: {
                    Text("Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(warmAmber, in: Capsule())
                }
                .padding(.top, 8)
            }
            .padding(32)
            .frame(width: 500)
            .glassContainer()
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameIntroCard(minigameIndex: 0, onStart: {})
    }
}
