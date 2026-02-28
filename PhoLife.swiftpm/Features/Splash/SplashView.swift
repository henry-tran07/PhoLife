import SwiftUI

// MARK: - File-level Color Constants

private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC
private let deepAmber = Color(red: 0.75, green: 0.55, blue: 0.35)

// MARK: - SplashView

struct SplashView: View {

    var onComplete: () -> Void

    // MARK: - Animation State

    @State private var bowlVisible = false
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var steamActive = false
    @State private var ambientGlow = false
    @State private var exitTransition = false
    @State private var bowlPulse = false
    @State private var landscapeHintVisible = false
    @State private var ingredientArrived: Set<Int> = []
    @State private var ingredientStarted: Set<Int> = []

    // MARK: - Start Positions

    private let startPositions: [CGPoint] = [
        CGPoint(x: -450, y: -200),   // top-left
        CGPoint(x: 450, y: -250),    // top-right
        CGPoint(x: -500, y: 50),     // left
        CGPoint(x: 500, y: 100),     // right
        CGPoint(x: -400, y: 280),    // bottom-left
        CGPoint(x: 400, y: 250),     // bottom-right
        CGPoint(x: -150, y: -320),   // top
        CGPoint(x: 200, y: 320),     // bottom
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: Background
            backgroundLayer

            // Layer 2: Steam particles (opacity scales with arrivals)
            steamParticlesLayer

            // Layer 3: Ingredient convergence
            ingredientConvergenceLayer

            // Main content
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                // Bowl with radiant glow
                bowlSection

                // Title in glass pill
                titleSection

                // Subtitle with decorative divider
                subtitleSection

                Spacer()
            }
            .scaleEffect(exitTransition ? 1.08 : 1.0)
            .opacity(exitTransition ? 0 : 1)

            // Landscape hint — positioned below the convergence center
            VStack {
                Spacer()
                landscapeHintSection
                    .padding(.bottom, 48)
            }
            .opacity(exitTransition ? 0 : 1)
        }
        .transition(.opacity)
        .task {
            await runAnimationSequence()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            // Warm radial glow centered behind the bowl
            RadialGradient(
                colors: [
                    warmAmber.opacity(ambientGlow ? 0.12 : 0.06),
                    warmAmber.opacity(0.03),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 500
            )
            .ignoresSafeArea()
            .offset(y: -40)

            // Secondary softer glow for depth
            RadialGradient(
                colors: [
                    Color.orange.opacity(ambientGlow ? 0.06 : 0.02),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
            .offset(y: -60)
        }
    }

    // MARK: - Steam Particles

    private var steamParticlesLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                SteamWispView(
                    index: i,
                    isActive: steamActive,
                    baseOpacityScale: 0.02 + Double(ingredientArrived.count) * 0.008,
                    warmAmber: warmAmber
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Ingredient Convergence

    private var ingredientConvergenceLayer: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                FloatingIngredientView(
                    index: i,
                    icon: PhoIngredientIcon.allCases[i],
                    startPosition: startPositions[i],
                    isStarted: ingredientStarted.contains(i),
                    hasArrived: ingredientArrived.contains(i)
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bowl Section

    private var bowlSection: some View {
        ZStack {
            // Warm underglow beneath the bowl
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            warmAmber.opacity(bowlVisible ? 0.2 : 0),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 20)
                .scaleEffect(ambientGlow ? 1.05 : 0.95)

            // Bowl image
            Image("splash-bowl")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .scaleEffect(bowlVisible ? 1.0 : 0.7)
                .opacity(bowlVisible ? 1 : 0)
                .accessibilityLabel("A beautiful bowl of Vietnamese pho")

            // Enhanced organic steam overlay
            steamOverlay
        }
        // Warm pulse when all ingredients arrive
        .scaleEffect(bowlPulse ? 1.05 : 1.0)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: bowlPulse)
    }

    private var steamOverlay: some View {
        ZStack {
            // Primary steam wisps
            ForEach(0..<5, id: \.self) { i in
                let baseSize = CGFloat([22, 28, 18, 32, 24][i])
                let xOffset = CGFloat([-30, -8, 15, 35, -18][i])
                let phase = Double([0, 0.3, 0.7, 0.15, 0.55][i])

                Ellipse()
                    .fill(.white.opacity(steamActive ? 0.03 : 0.18))
                    .frame(
                        width: baseSize + (steamActive ? 20 : 0),
                        height: baseSize * 1.4 + (steamActive ? 30 : 0)
                    )
                    .blur(radius: steamActive ? 20 : 12)
                    .offset(
                        x: xOffset + (steamActive ? CGFloat([-5, 8, -3, 6, -7][i]) : 0),
                        y: steamActive ? CGFloat(-90 - i * 22) : -30
                    )
                    .animation(
                        .easeInOut(duration: Double([3.5, 4.0, 3.2, 4.5, 3.8][i]))
                            .repeatForever(autoreverses: true)
                            .delay(phase),
                        value: steamActive
                    )
            }

            // Secondary faint steam layer for depth
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(steamActive ? 0.02 : 0.10))
                    .frame(width: CGFloat(40 + i * 12), height: CGFloat(40 + i * 12))
                    .blur(radius: 18)
                    .offset(
                        x: CGFloat([10, -15, 5][i]),
                        y: steamActive ? CGFloat(-110 - i * 20) : -40
                    )
                    .animation(
                        .easeInOut(duration: Double([4.2, 3.6, 5.0][i]))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.4),
                        value: steamActive
                    )
            }
        }
        .offset(y: -80)
        .allowsHitTesting(false)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        ZStack {
            // Warm glow behind title text
            Text("PhoLife")
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundStyle(warmAmber.opacity(0.3))
                .blur(radius: 16)
                .opacity(titleVisible ? 1 : 0)

            Text("PhoLife")
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            warmAmber,
                            Color(red: 0.95, green: 0.75, blue: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .glassContainer()
                .opacity(titleVisible ? 1 : 0)
                .scaleEffect(titleVisible ? 1.0 : 0.92)
                .offset(y: titleVisible ? 0 : 8)
        }
    }

    // MARK: - Subtitle Section

    private var subtitleSection: some View {
        VStack(spacing: 8) {
            Text("The story of Vietnamese ph\u{1EDF}")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(cream.opacity(0.7))
                .opacity(subtitleVisible ? 1 : 0)
                .offset(y: subtitleVisible ? 0 : 6)

            // Decorative divider
            Capsule()
                .fill(warmAmber.opacity(0.3))
                .frame(width: subtitleVisible ? 60 : 0, height: 2)
        }
    }

    // MARK: - Landscape Hint

    private var landscapeHintSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "ipad.landscape")
                .font(.system(size: 18, weight: .medium, design: .rounded))
            Text("Best in landscape")
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .foregroundStyle(cream.opacity(0.45))
        .padding(.top, 12)
        .opacity(landscapeHintVisible ? 1 : 0)
        .offset(y: landscapeHintVisible ? 0 : 6)
    }

    // MARK: - Animation Sequence

    private func runAnimationSequence() async {
        // 0.0s — ambient glow
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            ambientGlow = true
        }

        // 0.3s — bowl
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
            bowlVisible = true
        }
        withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
            steamActive = true
        }

        // 0.5s — ingredients wave 1 (indices 0, 1)
        try? await Task.sleep(for: .seconds(0.2))
        withAnimation { ingredientStarted.insert(0); ingredientStarted.insert(1) }

        // 0.8s — wave 2 (indices 2, 3)
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation { ingredientStarted.insert(2); ingredientStarted.insert(3) }

        // 1.1s — wave 3 (indices 4, 5)
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation { ingredientStarted.insert(4); ingredientStarted.insert(5) }

        // 1.4s — wave 4 (indices 6, 7)
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation { ingredientStarted.insert(6); ingredientStarted.insert(7) }

        // 1.5s — title
        try? await Task.sleep(for: .seconds(0.1))
        withAnimation(.spring(duration: 0.7, bounce: 0.15)) {
            titleVisible = true
        }

        // 2.0s — subtitle
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeOut(duration: 0.6)) {
            subtitleVisible = true
        }

        // 2.5s — landscape hint
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeOut(duration: 0.5)) {
            landscapeHintVisible = true
        }

        // Stagger ingredient arrivals
        try? await Task.sleep(for: .seconds(0.3))
        for i in 0..<8 {
            try? await Task.sleep(for: .seconds(0.15))
            _ = withAnimation(.easeIn(duration: 0.3)) {
                ingredientArrived.insert(i)
            }
        }

        // Bowl pulse when all ingredients arrived
        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
            bowlPulse = true
        }
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.spring(duration: 0.3)) {
            bowlPulse = false
        }

        // Hold — let the user appreciate the full composition
        try? await Task.sleep(for: .seconds(1.5))

        // Exit
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeInOut(duration: 0.5)) {
            exitTransition = true
        }
        try? await Task.sleep(for: .seconds(0.5))
        onComplete()
    }
}

// MARK: - Floating Ingredient View

private struct FloatingIngredientView: View {

    let index: Int
    let icon: PhoIngredientIcon
    let startPosition: CGPoint
    let isStarted: Bool
    let hasArrived: Bool

    @State private var burstActive = false

    var body: some View {
        ZStack {
            // Trailing glow
            Circle()
                .fill(warmAmber.opacity(0.15))
                .frame(width: 40, height: 40)
                .blur(radius: 8)
                .opacity(isStarted && !hasArrived ? 0.6 : 0)

            // The icon
            PhoIngredientIconView(icon: icon, size: 32)
                .opacity(isStarted && !hasArrived ? 1.0 : (hasArrived ? 0 : 0.3))
                .scaleEffect(hasArrived ? 0.01 : 1.0)

            // Arrival burst particles
            if hasArrived {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(warmAmber.opacity(burstActive ? 0 : 0.5))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: burstActive ? CGFloat(cos(Double(i) * 2.094)) * 30 : 0,
                            y: burstActive ? CGFloat(sin(Double(i) * 2.094)) * 30 : 0
                        )
                        .blur(radius: burstActive ? 4 : 0)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) { burstActive = true }
                }
            }
        }
        .offset(
            x: isStarted && !hasArrived ? 0 : (hasArrived ? 0 : startPosition.x),
            y: isStarted && !hasArrived ? 0 : (hasArrived ? 0 : startPosition.y)
        )
        .animation(.spring(duration: 1.2, bounce: 0.1), value: isStarted)
        .animation(.easeIn(duration: 0.3), value: hasArrived)
    }
}

// MARK: - Steam Wisp Particle

/// An individual floating wisp that drifts upward in the ambient background.
private struct SteamWispView: View {

    let index: Int
    let isActive: Bool
    var baseOpacityScale: Double = 0.08
    let warmAmber: Color

    @State private var drift = false

    // Deterministic layout per index
    private var config: (x: CGFloat, yStart: CGFloat, size: CGFloat, duration: Double, delay: Double) {
        let xPositions: [CGFloat] = [-120, -80, -40, 0, 40, 80, 120, -60, 60, -100, 100, 0]
        let sizes: [CGFloat] = [4, 6, 3, 5, 4, 7, 3, 5, 6, 4, 3, 5]
        let durations: [Double] = [6, 8, 7, 9, 6.5, 7.5, 8.5, 6, 7, 9, 8, 7.5]
        let delays: [Double] = [0, 1.2, 0.5, 2.0, 0.8, 1.5, 0.3, 2.5, 1.0, 0.7, 1.8, 2.2]

        let i = index % xPositions.count
        return (xPositions[i], 60, sizes[i], durations[i], delays[i])
    }

    var body: some View {
        Circle()
            .fill(warmAmber.opacity(isActive ? baseOpacityScale : 0))
            .frame(width: config.size, height: config.size)
            .blur(radius: config.size * 0.6)
            .offset(
                x: config.x + (drift ? CGFloat(index.isMultiple(of: 2) ? 15 : -15) : 0),
                y: drift ? -200 : config.yStart
            )
            .opacity(drift ? 0 : (isActive ? 0.5 : 0))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: config.duration)
                        .repeatForever(autoreverses: false)
                        .delay(config.delay)
                ) {
                    drift = true
                }
            }
    }
}
