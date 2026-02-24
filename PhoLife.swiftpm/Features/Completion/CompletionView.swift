import SwiftUI

// MARK: - File-level Color Constants

private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC
private let deepAmber = Color(red: 0.75, green: 0.55, blue: 0.35)

// MARK: - CompletionView

struct CompletionView: View {

    // MARK: - Input

    let gameState: GameState

    // MARK: - Animation State

    @State private var bowlVisible = false
    @State private var starsVisible = false
    @State private var titleVisible = false
    @State private var earnedTitleVisible = false
    @State private var leftPanelVisible = false
    @State private var rightPanelVisible = false
    @State private var leftRowsVisible = false
    @State private var rightRowsVisible = false
    @State private var buttonVisible = false
    @State private var buttonPulse = false
    @State private var ambientGlow = false
    @State private var confettiActive = false

    // MARK: - Computed

    private var overallStars: Int {
        if gameState.totalStars >= 20 { return 3 }
        else if gameState.totalStars >= 12 { return 2 }
        else { return 1 }
    }

    private var totalScore: Int {
        gameState.minigameResults.reduce(0) { $0 + $1.score }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            if overallStars >= 2 {
                confettiLayer
            }

            HStack(spacing: 0) {
                // Left panel — Performance
                performancePanel
                    .frame(width: 280)
                    .padding(.leading, 24)

                Spacer()

                // Center — Hero bowl
                centerColumn
                    .frame(maxWidth: 340)

                Spacer()

                // Right panel — Ingredients
                ingredientsPanel
                    .frame(width: 280)
                    .padding(.trailing, 24)
            }
            .padding(.vertical, 24)
        }
        .onAppear { startRevealSequence() }
        .transition(.opacity)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

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

    // MARK: - Left Panel: Performance

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Performance")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber)
                .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(gameState.minigameResults.enumerated()), id: \.element.id) { index, result in
                        performanceRow(result: result, index: index)
                    }
                }
            }

            // Footer: total
            Capsule().fill(warmAmber.opacity(0.25)).frame(height: 1)
                .padding(.vertical, 8)
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(cream)
                Spacer()
                StarRatingView(stars: overallStars, starSize: 16)
                Text("\(totalScore)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(18)
        .glassContainer()
        .opacity(leftPanelVisible ? 1 : 0)
        .offset(x: leftPanelVisible ? 0 : -20)
    }

    private func performanceRow(result: MinigameResult, index: Int) -> some View {
        let fact = CulturalFact.allFacts[safe: result.minigameIndex]
        let ingredient = PhoIngredient.allIngredients[safe: result.minigameIndex]

        return HStack(spacing: 10) {
            if let ingredient {
                PhoIngredientIconView(icon: ingredient.icon, size: 22)
            }
            Text(fact?.minigameTitle ?? "Step \(index + 1)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(cream)
                .lineLimit(1)
            Spacer()
            StarRatingView(stars: result.stars, starSize: 14)
            Text("\(result.score)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(warmAmber)
                .frame(width: 32, alignment: .trailing)
        }
        .opacity(leftRowsVisible ? 1 : 0)
        .offset(x: leftRowsVisible ? 0 : -12)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: leftRowsVisible)
    }

    // MARK: - Center Column

    private var centerColumn: some View {
        VStack(spacing: 12) {
            Spacer()

            titleSection

            bowlSection

            StarRatingView(stars: overallStars, animated: true, starSize: 40)
                .opacity(starsVisible ? 1 : 0)
                .scaleEffect(starsVisible ? 1.0 : 0.6)

            earnedTitleSection

            Spacer()

            replayButton
                .padding(.bottom, 16)
        }
    }

    // MARK: - Bowl Section

    private var bowlSection: some View {
        ZStack {
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
                        endRadius: 160
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 25)
                .scaleEffect(ambientGlow ? 1.06 : 0.94)

            Image("completion-bowl")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240, height: 240)
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
            Text("Your Bowl is Ready!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber.opacity(0.3))
                .blur(radius: 12)
                .opacity(titleVisible ? 1 : 0)

            Text("Your Bowl is Ready!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [warmAmber, Color(red: 0.95, green: 0.78, blue: 0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .glassContainer()
                .opacity(titleVisible ? 1 : 0)
                .scaleEffect(titleVisible ? 1.0 : 0.9)
        }
    }

    // MARK: - Earned Title

    private var earnedTitleSection: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(warmAmber.opacity(0.25))
                .frame(width: earnedTitleVisible ? 50 : 0, height: 2)

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
                .opacity(earnedTitleVisible ? 1 : 0)
                .scaleEffect(earnedTitleVisible ? 1.0 : 0.85)

            Capsule()
                .fill(warmAmber.opacity(0.25))
                .frame(width: earnedTitleVisible ? 50 : 0, height: 2)
        }
    }

    // MARK: - Replay Button

    private var replayButton: some View {
        Button {
            HapticManager.shared.heavy()
            AudioManager.shared.playSFX("button-tap")
            gameState.resetForReplay()
        } label: {
            ZStack {
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
                                    colors: [warmAmber, deepAmber],
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

    // MARK: - Right Panel: Ingredients

    private var ingredientsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Bowl Ingredients")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber)
                .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(PhoIngredient.allIngredients.enumerated()), id: \.element.id) { index, ingredient in
                        ingredientRow(ingredient: ingredient, index: index)
                    }
                }
            }
        }
        .padding(18)
        .glassContainer()
        .opacity(rightPanelVisible ? 1 : 0)
        .offset(x: rightPanelVisible ? 0 : 20)
    }

    private func ingredientRow(ingredient: PhoIngredient, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PhoIngredientIconView(icon: ingredient.icon, size: 26)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(cream)
                Text(ingredient.contribution)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(2)
            }
        }
        .opacity(rightRowsVisible ? 1 : 0)
        .offset(x: rightRowsVisible ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: rightRowsVisible)
    }

    // MARK: - Reveal Sequence

    private func startRevealSequence() {
        // 0.0s — ambient glow
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            ambientGlow = true
        }
        // 0.3s — bowl
        withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
            bowlVisible = true
        }
        // 0.5s — title
        withAnimation(.spring(duration: 0.6, bounce: 0.15).delay(0.5)) {
            titleVisible = true
        }
        // 0.7s — stars + confetti
        withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.7)) {
            starsVisible = true
        }
        if overallStars >= 2 {
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                confettiActive = true
            }
        }
        // 0.9s — earned title
        withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.9)) {
            earnedTitleVisible = true
        }
        // 1.0s — left panel
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            leftPanelVisible = true
        }
        // 1.1s — left rows
        withAnimation(.easeOut(duration: 0.3).delay(1.1)) {
            leftRowsVisible = true
        }
        // 1.2s — right panel
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            rightPanelVisible = true
        }
        // 1.3s — right rows
        withAnimation(.easeOut(duration: 0.3).delay(1.3)) {
            rightRowsVisible = true
        }
        // 1.6s — button
        withAnimation(.spring(duration: 0.5, bounce: 0.15).delay(1.6)) {
            buttonVisible = true
        }
        // 2.0s — button pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(2.0)) {
            buttonPulse = true
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
            Color(red: 1.0, green: 0.84, blue: 0.0),
            Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255),
            Color(red: 1.0, green: 248 / 255, blue: 220 / 255),
            Color.orange,
            Color(red: 0.85, green: 0.65, blue: 0.4)
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
                withAnimation(
                    .linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
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

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    CompletionView(gameState: {
        let state = GameState()
        for i in 0..<8 {
            state.completeMinigame(result: MinigameResult(
                minigameIndex: i,
                stars: [3, 2, 3, 2, 3, 1, 2, 3][i],
                score: [95, 78, 92, 81, 88, 65, 76, 90][i]
            ))
        }
        return state
    }())
    .preferredColorScheme(.dark)
}
