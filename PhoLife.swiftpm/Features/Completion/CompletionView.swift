import SwiftUI

struct CompletionView: View {

    // MARK: - Input

    let gameState: GameState

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC

    @State private var bowlVisible = false
    @State private var starsVisible = false
    @State private var titleVisible = false

    // MARK: - Computed

    private var overallStars: Int {
        if gameState.totalStars >= 20 {
            return 3
        } else if gameState.totalStars >= 12 {
            return 2
        } else {
            return 1
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Bowl image
                Image("completion-bowl")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 260, height: 260)
                    .shadow(color: .orange.opacity(0.4), radius: 30)
                    .scaleEffect(bowlVisible ? 1.0 : 0.5)
                    .opacity(bowlVisible ? 1 : 0)
                    .accessibilityLabel("Your completed bowl of pho")

                // Title
                Text("Your Bowl is Ready!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)

                // Overall star rating
                StarRatingView(stars: overallStars, animated: true)
                    .opacity(starsVisible ? 1 : 0)

                // Earned title
                Text(gameState.earnedTitle)
                    .font(.system(size: 20, weight: .regular).italic())
                    .foregroundStyle(cream.opacity(0.85))
                    .opacity(titleVisible ? 1 : 0)

                Spacer()

                // Cultural facts carousel
                factsCarousel

                Spacer()

                // Replay button
                Button {
                    HapticManager.shared.heavy()
                    AudioManager.shared.playSFX("button-tap")
                    gameState.resetForReplay()
                } label: {
                    Text("Cook Another Bowl")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 18)
                        .background(warmAmber, in: Capsule())
                }
                .accessibilityLabel("Replay all minigames")
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                bowlVisible = true
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                starsVisible = true
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.9)) {
                titleVisible = true
            }
        }
        .transition(.opacity)
    }

    // MARK: - Facts Carousel

    private var factsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(CulturalFact.allFacts) { fact in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(fact.minigameTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(warmAmber)

                        Text(fact.fact)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(width: 280, alignment: .topLeading)
                    .glassContainer()
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    CompletionView(gameState: {
        let state = GameState()
        // Simulate completed game
        for i in 0..<8 {
            state.completeMinigame(result: MinigameResult(
                minigameIndex: i,
                stars: 2,
                score: 80
            ))
        }
        return state
    }())
    .preferredColorScheme(.dark)
}
