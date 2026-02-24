import SwiftUI

struct MinigameScoreCard: View {

    // MARK: - Input

    let stars: Int
    let score: Int
    let minigameIndex: Int
    let onContinue: () -> Void

    // MARK: - Constants

    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Centered card
            VStack(spacing: 20) {
                // Star rating
                StarRatingView(stars: stars, animated: true)

                // Score
                Text("Score: \(score)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                // Cultural fact
                Text(culturalFact)
                    .font(.system(size: 16, weight: .regular).italic())
                    .foregroundStyle(cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)

                // Continue button
                Button {
                    HapticManager.shared.heavy()
                    AudioManager.shared.playSFX("button-tap")
                    onContinue()
                } label: {
                    Text("Continue")
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

    private var culturalFact: String {
        guard minigameIndex >= 0, minigameIndex < CulturalFact.allFacts.count else {
            return ""
        }
        return CulturalFact.allFacts[minigameIndex].fact
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameScoreCard(stars: 2, score: 85, minigameIndex: 0, onContinue: {})
    }
}
