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
    @State private var factsVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false
    @State private var ambientGlow = false
    @State private var confettiActive = false

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
            // Layered background
            backgroundLayer

            // Confetti for high star counts
            if overallStars >= 2 {
                confettiLayer
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                // Bowl with radiant glow
                bowlSection
                    .padding(.bottom, 16)

                // Title
                titleSection
                    .padding(.bottom, 12)

                // Overall star rating
                starSection
                    .padding(.bottom, 8)

                // Earned title
                earnedTitleSection
                    .padding(.bottom, 20)

                Spacer()
                    .frame(minHeight: 8, maxHeight: 20)

                // Cultural facts carousel
                factsCarousel
                    .opacity(factsVisible ? 1 : 0)
                    .offset(y: factsVisible ? 0 : 16)

                Spacer()
                    .frame(minHeight: 16, maxHeight: 32)

                // Replay button
                replayButton
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            startRevealSequence()
        }
        .transition(.opacity)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            // Warm radial glow centered behind the bowl area
            RadialGradient(
                colors: [
                    warmAmber.opacity(ambientGlow ? 0.14 : 0.06),
                    warmAmber.opacity(0.03),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 30,
                endRadius: 450
            )
            .ignoresSafeArea()

            // Secondary warm bloom
            RadialGradient(
                colors: [
                    Color.orange.opacity(ambientGlow ? 0.07 : 0.02),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Confetti Layer

    private var confettiLayer: some View {
        ZStack {
            ForEach(0..<(overallStars >= 3 ? 20 : 12), id: \.self) { i in
                ConfettiPiece(
                    index: i,
                    isActive: confettiActive,
                    warmAmber: warmAmber,
                    cream: cream,
                    isHighScore: overallStars >= 3
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bowl Section

    private var bowlSection: some View {
        ZStack {
            // Warm radial light behind the bowl
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            warmAmber.opacity(bowlVisible ? 0.25 : 0),
                            Color.orange.opacity(bowlVisible ? 0.08 : 0),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 380, height: 380)
                .blur(radius: 25)
                .scaleEffect(ambientGlow ? 1.06 : 0.94)

            // Bowl image
            Image("completion-bowl")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 260, height: 260)
                .shadow(color: warmAmber.opacity(0.5), radius: 30)
                .shadow(color: .orange.opacity(0.2), radius: 60)
                .scaleEffect(bowlVisible ? 1.0 : 0.5)
                .opacity(bowlVisible ? 1 : 0)
                .accessibilityLabel("Your completed bowl of pho")
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        ZStack {
            // Warm text glow
            Text("Your Bowl is Ready!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber.opacity(0.3))
                .blur(radius: 12)
                .opacity(bowlVisible ? 1 : 0)

            Text("Your Bowl is Ready!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [warmAmber, Color(red: 0.95, green: 0.78, blue: 0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(bowlVisible ? 1 : 0)
                .scaleEffect(bowlVisible ? 1.0 : 0.9)
        }
    }

    // MARK: - Star Section

    private var starSection: some View {
        StarRatingView(stars: overallStars, animated: true, starSize: 44)
            .opacity(starsVisible ? 1 : 0)
            .scaleEffect(starsVisible ? 1.0 : 0.6)
    }

    // MARK: - Earned Title

    private var earnedTitleSection: some View {
        VStack(spacing: 8) {
            // Decorative line above
            Capsule()
                .fill(warmAmber.opacity(0.25))
                .frame(width: titleVisible ? 50 : 0, height: 2)

            Text(gameState.earnedTitle)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [cream, warmAmber.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: warmAmber.opacity(0.3), radius: 8)
                .opacity(titleVisible ? 1 : 0)
                .scaleEffect(titleVisible ? 1.0 : 0.85)

            // Decorative line below
            Capsule()
                .fill(warmAmber.opacity(0.25))
                .frame(width: titleVisible ? 50 : 0, height: 2)
        }
    }

    // MARK: - Facts Carousel

    private var factsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(CulturalFact.allFacts.enumerated()), id: \.element.id) { index, fact in
                    factCard(fact: fact, index: index)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func factCard(fact: CulturalFact, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Minigame title with icon accent
            HStack(spacing: 8) {
                Circle()
                    .fill(warmAmber.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(fact.minigameTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
            }

            Text(fact.fact)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(width: 280, alignment: .topLeading)
        .glassContainer()
        .opacity(factsVisible ? 1 : 0)
        .offset(y: factsVisible ? 0 : 10)
        .animation(
            .easeOut(duration: 0.5).delay(Double(index) * 0.06),
            value: factsVisible
        )
    }

    // MARK: - Replay Button

    private var replayButton: some View {
        Button {
            HapticManager.shared.heavy()
            AudioManager.shared.playSFX("button-tap")
            gameState.resetForReplay()
        } label: {
            ZStack {
                // Pulsing glow behind button
                Capsule()
                    .fill(warmAmber.opacity(buttonPulse ? 0.35 : 0.15))
                    .frame(width: 280, height: 64)
                    .blur(radius: 16)

                Text("Cook Another Bowl")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        warmAmber,
                                        Color(red: 0.75, green: 0.55, blue: 0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: warmAmber.opacity(0.4), radius: 12, y: 4)
                    )
            }
        }
        .accessibilityLabel("Replay all minigames")
        .opacity(buttonVisible ? 1 : 0)
        .scaleEffect(buttonVisible ? 1.0 : 0.85)
        .offset(y: buttonVisible ? 0 : 12)
    }

    // MARK: - Reveal Sequence

    private func startRevealSequence() {
        // Bowl enters with spring
        withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
            bowlVisible = true
        }

        // Ambient glow breathes
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
            ambientGlow = true
        }

        // Stars reveal after bowl settles
        withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.5)) {
            starsVisible = true
        }

        // Earned title slides in
        withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.9)) {
            titleVisible = true
        }

        // Facts carousel fades up
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            factsVisible = true
        }

        // Replay button enters
        withAnimation(.spring(duration: 0.5, bounce: 0.15).delay(1.5)) {
            buttonVisible = true
        }

        // Button pulse starts after it appears
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(2.0)) {
            buttonPulse = true
        }

        // Confetti for high scores
        if overallStars >= 2 {
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                confettiActive = true
            }
        }
    }
}

// MARK: - Confetti Piece

/// A single celebratory particle that floats and drifts down from the top.
private struct ConfettiPiece: View {

    let index: Int
    let isActive: Bool
    let warmAmber: Color
    let cream: Color
    let isHighScore: Bool

    @State private var falling = false
    @State private var rotation: Double = 0

    private var config: (x: CGFloat, size: CGFloat, duration: Double, delay: Double, color: Color) {
        let xSpread: [CGFloat] = [-180, -140, -100, -60, -20, 20, 60, 100, 140, 180,
                                   -160, -120, -80, -40, 0, 40, 80, 120, 160, -150]
        let sizes: [CGFloat] = [6, 8, 5, 7, 6, 9, 5, 7, 8, 6, 7, 5, 8, 6, 9, 7, 5, 8, 6, 7]
        let durations: [Double] = [4, 5, 4.5, 3.8, 5.2, 4.3, 3.5, 4.8, 5.5, 4.1,
                                    3.9, 5.3, 4.6, 3.7, 4.9, 5.1, 4.2, 3.6, 5.4, 4.7]
        let delays: [Double] = [0, 0.2, 0.4, 0.1, 0.6, 0.3, 0.8, 0.15, 0.5, 0.7,
                                 0.35, 0.55, 0.25, 0.75, 0.45, 0.1, 0.65, 0.9, 0.3, 0.5]
        let colors: [Color] = [
            Color(red: 1.0, green: 0.84, blue: 0.0),      // Gold
            Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255), // Amber
            Color(red: 1.0, green: 248 / 255, blue: 220 / 255),       // Cream
            Color.orange,
            Color(red: 0.85, green: 0.65, blue: 0.4)       // Warm tan
        ]

        let i = index % xSpread.count
        let colorIndex = index % colors.count
        return (xSpread[i], sizes[i], durations[i], delays[i], colors[colorIndex])
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(config.color.opacity(isActive ? 0.7 : 0))
            .frame(width: config.size, height: config.size * 0.5)
            .rotationEffect(.degrees(rotation))
            .offset(
                x: config.x,
                y: falling ? 500 : -320
            )
            .opacity(falling ? 0 : (isActive ? 0.8 : 0))
            .onAppear {
                // Continuous spin
                withAnimation(
                    .linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
                // Fall downward
                withAnimation(
                    .easeIn(duration: config.duration)
                        .repeatForever(autoreverses: false)
                        .delay(config.delay)
                ) {
                    falling = true
                }
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
