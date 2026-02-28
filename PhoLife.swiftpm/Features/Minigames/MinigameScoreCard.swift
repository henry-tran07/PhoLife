import SwiftUI

struct MinigameScoreCard: View {

    // MARK: - Input

    let stars: Int
    let score: Int
    let minigameIndex: Int
    let onContinue: () -> Void

    // MARK: - State

    @State private var displayedScore: Int = 0
    @State private var cardVisible = false
    @State private var starsVisible = false
    @State private var scoreVisible = false
    @State private var headerVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false
    @State private var starGlow = false
    @State private var sparklePhase: CGFloat = 0

    // MARK: - Constants

    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC
    private let deepAmber = Color(red: 180 / 255, green: 120 / 255, blue: 60 / 255)
    private let gold = Color(red: 1.0, green: 0.84, blue: 0.0)

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background with warm tint
            Color.black.opacity(cardVisible ? 0.65 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.5), value: cardVisible)

            // Warm celebratory glow behind card
            RadialGradient(
                colors: [
                    gold.opacity(cardVisible ? 0.1 : 0),
                    warmAmber.opacity(cardVisible ? 0.06 : 0),
                    Color.clear
                ],
                center: .center,
                startRadius: 60,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.9), value: cardVisible)

            // Gold sparkle particles behind card
            Canvas { context, size in
                let particleCount = 16
                for i in 0..<particleCount {
                    let angle = (CGFloat(i) / CGFloat(particleCount)) * .pi * 2 + sparklePhase * .pi * 2
                    let radius: CGFloat = 140 + 60 * sin(CGFloat(i) * 1.3 + sparklePhase * .pi)
                    let x = size.width / 2 + cos(angle) * radius
                    let y = size.height / 2 + sin(angle) * radius * 0.6
                    let alpha = 0.15 + 0.2 * sin(sparklePhase * .pi * 4 + CGFloat(i))
                    let dotSize: CGFloat = 1.5 + sin(CGFloat(i) * 2.0 + sparklePhase * .pi * 3) * 1.0

                    context.opacity = max(0, alpha)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - dotSize, y: y - dotSize, width: dotSize * 2, height: dotSize * 2)),
                        with: .color(gold)
                    )
                }
            }
            .ignoresSafeArea()
            .opacity(starsVisible ? 1 : 0)
            .animation(.easeIn(duration: 0.6), value: starsVisible)
            .allowsHitTesting(false)

            // Centered card
            VStack(spacing: 22) {
                // Star rating with warm glow behind
                ZStack {
                    // Gold glow behind stars
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [gold.opacity(starGlow ? 0.2 : 0.05), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 200, height: 80)
                        .blur(radius: 10)

                    StarRatingView(stars: stars, animated: true, starSize: 52)
                }
                .opacity(starsVisible ? 1 : 0)
                .scaleEffect(starsVisible ? 1 : 0.6)

                // Celebration header with gradient
                Text(celebrationHeader)
                    .font(.custom("SFCompactRounded-Bold", size: 32))
                    .foregroundStyle(headerGradient)
                    .shadow(color: headerShadowColor, radius: 8, y: 2)
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1 : 0.9)
                    .offset(y: headerVisible ? 0 : 10)

                // Score with count-up and label
                VStack(spacing: 4) {
                    Text("\(displayedScore)")
                        .font(.custom("SFCompactRounded-Bold", size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [warmAmber, cream],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText(value: Double(displayedScore)))
                        .shadow(color: warmAmber.opacity(0.3), radius: 6, y: 2)

                    Text("POINTS")
                        .font(.custom("SFCompactRounded-Bold", size: 12))
                        .tracking(2.0)
                        .foregroundStyle(warmAmber.opacity(0.5))
                }
                .opacity(scoreVisible ? 1 : 0)
                .scaleEffect(scoreVisible ? 1 : 0.85)

                // Continue button - matching IntroCard premium style
                Button {
                    HapticManager.shared.heavy()
                    AudioManager.shared.playSFX("button-tap")
                    onContinue()
                } label: {
                    Text("Continue")
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
                .accessibilityLabel("Continue to next minigame")
                .padding(.top, 6)
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
            displayedScore = 0
            cardVisible = false
            starsVisible = false
            scoreVisible = false
            headerVisible = false
            buttonVisible = false
            buttonPulse = false
            starGlow = false

            // Card entrance
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
                cardVisible = true
            }

            // Staggered reveal sequence - cinematic pacing
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.35)) {
                starsVisible = true
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.9)) {
                scoreVisible = true
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(1.6)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.1)) {
                buttonVisible = true
            }

            // Star glow breathing
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.8)) {
                starGlow = true
            }

            // Button pulse after it appears
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(2.5)) {
                buttonPulse = true
            }

            // Sparkle particle orbit
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                sparklePhase = 1.0
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

    private var headerGradient: some ShapeStyle {
        switch stars {
        case 3:
            return LinearGradient(
                colors: [gold, warmAmber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [cream, warmAmber.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.white, cream.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var headerShadowColor: Color {
        switch stars {
        case 3: gold.opacity(0.3)
        case 2: warmAmber.opacity(0.2)
        default: Color.clear
        }
    }

    private var headerColor: Color {
        switch stars {
        case 3: warmAmber
        case 2: cream
        default: .white
        }
    }

}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MinigameScoreCard(stars: 3, score: 85, minigameIndex: 0, onContinue: {})
    }
}
