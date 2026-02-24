import SwiftUI

struct MinigameScoreCard: View {

    // MARK: - Input

    let stars: Int
    let score: Int
    let minigameIndex: Int
    let onContinue: () -> Void

    // MARK: - State

    @State private var displayedScore: Int = 0
    @State private var starsVisible = false
    @State private var scoreVisible = false
    @State private var headerVisible = false
    @State private var factVisible = false
    @State private var buttonVisible = false

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
                StarRatingView(stars: stars, animated: true, starSize: 52)
                    .opacity(starsVisible ? 1 : 0)
                    .scaleEffect(starsVisible ? 1 : 0.8)

                // Celebration header
                Text(celebrationHeader)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(headerColor)
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : 10)

                // Score with count-up
                Text("\(displayedScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
                    .contentTransition(.numericText(value: Double(displayedScore)))
                    .opacity(scoreVisible ? 1 : 0)

                // Cultural fact
                Text(culturalFact)
                    .font(.system(size: 16, weight: .regular).italic())
                    .foregroundStyle(cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                    .opacity(factVisible ? 1 : 0)
                    .offset(y: factVisible ? 0 : 15)

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
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Continue to next minigame")
                .padding(.top, 8)
                .opacity(buttonVisible ? 1 : 0)
                .scaleEffect(buttonVisible ? 1 : 0.9)
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
            displayedScore = 0
            starsVisible = false
            scoreVisible = false
            headerVisible = false
            factVisible = false
            buttonVisible = false

            // Staggered reveal sequence
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                starsVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
                scoreVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(1.5)) {
                headerVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(2.0)) {
                factVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(2.3)) {
                buttonVisible = true
            }
        }
        .task {
            // Haptic on star reveal
            try? await Task.sleep(for: .milliseconds(700))
            HapticManager.shared.success()

            // Wait for score counter to start
            try? await Task.sleep(for: .milliseconds(400))

            // Count up to score
            let steps = min(score, 60)
            guard steps > 0 else { return }
            let increment = max(1, score / steps)

            for i in stride(from: 0, through: score, by: increment) {
                if Task.isCancelled { return }
                withAnimation(.linear(duration: 0.016)) {
                    displayedScore = min(i, score)
                }
                // Throttled haptic every ~20 points
                if i % 20 == 0 {
                    HapticManager.shared.light()
                }
                try? await Task.sleep(for: .milliseconds(20))
            }
            // Ensure final value is exact
            withAnimation(.linear(duration: 0.016)) {
                displayedScore = score
            }
        }
    }

    // MARK: - Helpers

    private var celebrationHeader: String {
        switch stars {
        case 3: "Perfect!"
        case 2: "Well Done!"
        default: "Nice Try!"
        }
    }

    private var headerColor: Color {
        switch stars {
        case 3: warmAmber
        case 2: cream
        default: .white
        }
    }

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
        MinigameScoreCard(stars: 3, score: 85, minigameIndex: 0, onContinue: {})
    }
}
