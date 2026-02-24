import SwiftUI

struct SplashView: View {

    var onComplete: () -> Void

    // MARK: - Animation State

    @State private var bowlVisible = false
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var steamActive = false
    @State private var ambientGlow = false
    @State private var particlesActive = false
    @State private var exitTransition = false

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC

    // MARK: - Body

    var body: some View {
        ZStack {
            // Warm radial gradient background instead of flat color
            backgroundLayer

            // Ambient floating particles
            steamParticlesLayer

            // Main content
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                // Bowl image with enhanced steam effect
                bowlSection

                // Title with warm glow
                titleSection

                // Subtitle with gentle presence
                subtitleSection

                Spacer()
            }
            .scaleEffect(exitTransition ? 1.08 : 1.0)
            .opacity(exitTransition ? 0 : 1)
        }
        .transition(.opacity)
        .onAppear {
            startEntranceSequence()
        }
        .task {
            try? await Task.sleep(for: .seconds(3.0))
            // Cinematic exit
            withAnimation(.easeInOut(duration: 0.5)) {
                exitTransition = true
            }
            try? await Task.sleep(for: .seconds(0.5))
            onComplete()
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
                    isActive: particlesActive,
                    warmAmber: warmAmber
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
                .frame(width: 280, height: 280)
                .scaleEffect(bowlVisible ? 1.0 : 0.85)
                .opacity(bowlVisible ? 1 : 0)
                .accessibilityLabel("A beautiful bowl of Vietnamese pho")

            // Enhanced organic steam overlay
            steamOverlay
        }
    }

    private var steamOverlay: some View {
        ZStack {
            // Primary steam wisps — organic, varied sizes and timing
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

    // MARK: - Animation Sequence

    private func startEntranceSequence() {
        // Bowl fades in with gentle scale
        withAnimation(.easeOut(duration: 0.9)) {
            bowlVisible = true
        }

        // Steam begins after bowl appears
        withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
            steamActive = true
        }

        // Ambient background glow breathes
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.3)) {
            ambientGlow = true
        }

        // Title staggered entrance
        withAnimation(.spring(duration: 0.7, bounce: 0.15).delay(0.6)) {
            titleVisible = true
        }

        // Subtitle and divider
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
            subtitleVisible = true
        }

        // Particles begin floating
        withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
            particlesActive = true
        }
    }
}

// MARK: - Steam Wisp Particle

/// An individual floating wisp that drifts upward in the ambient background.
private struct SteamWispView: View {

    let index: Int
    let isActive: Bool
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
            .fill(warmAmber.opacity(isActive ? 0.08 : 0))
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
