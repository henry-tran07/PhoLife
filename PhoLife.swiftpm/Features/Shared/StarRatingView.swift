import SwiftUI

/// A reusable row of star icons that displays how many stars a
/// player has earned (1-3) out of a configurable maximum.
///
/// Filled stars use a warm gold gradient and glow shadow;
/// unearned stars use a dim warm amber tint.
///
/// When `animated` is `true` each star scales in sequentially with a
/// short staggered delay -- useful for the score reveal screen.
struct StarRatingView: View {

    // MARK: - Input

    /// Number of stars earned (clamped to 0 ... `maxStars`).
    let stars: Int

    /// Maximum number of stars that can be earned.
    let maxStars: Int

    /// Whether to play the sequential scale-in animation on appear.
    let animated: Bool

    /// Size of each star icon.
    let starSize: CGFloat

    // MARK: - State

    @State private var visibleCount: Int = 0

    /// Per-star glow radius animation (radiating golden glow).
    @State private var glowActive: Set<Int> = []

    /// Per-star subtle idle shimmer after reveal.
    @State private var shimmerActive = false

    /// Per-star rotation for the bounce-in reveal.
    @State private var rotations: [Double] = []

    // MARK: - Constants

    /// Rich gold gradient: bright gold top to warm amber bottom.
    private let filledGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.88, blue: 0.15),
            Color(red: 1.0, green: 0.75, blue: 0.0),
            Color(red: 0.85, green: 0.60, blue: 0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let emptyColor = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255).opacity(0.18)
    private let emptyStrokeColor = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255).opacity(0.35)

    // MARK: - Init

    init(stars: Int, maxStars: Int = 3, animated: Bool = false, starSize: CGFloat = 36) {
        self.stars    = stars
        self.maxStars = maxStars
        self.animated = animated
        self.starSize = starSize
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: starSize * 0.3) {
            ForEach(0 ..< maxStars, id: \.self) { index in
                starCell(for: index)
                    .scaleEffect(scaleForStar(at: index))
                    .rotationEffect(.degrees(rotationForStar(at: index)))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.45, blendDuration: 0.1)
                            .delay(animated ? Double(index) * 0.25 : 0),
                        value: visibleCount
                    )
            }
        }
        .onAppear {
            // Initialize rotation array
            if rotations.isEmpty {
                rotations = Array(repeating: 0.0, count: maxStars)
            }

            if animated {
                visibleCount = 0
                // Small delay so the view is on screen before the reveal begins.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation {
                        visibleCount = stars
                    }
                    // Stagger the glow activation for each earned star.
                    for i in 0 ..< stars {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25 + 0.2) {
                            withAnimation(.easeOut(duration: 0.6)) {
                                _ = glowActive.insert(i)
                            }
                        }
                    }
                    // Start idle shimmer after all stars have revealed.
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(stars) * 0.25 + 0.5) {
                        withAnimation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                        ) {
                            shimmerActive = true
                        }
                    }
                }
            } else {
                visibleCount = stars
                for i in 0 ..< stars {
                    glowActive.insert(i)
                }
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    shimmerActive = true
                }
            }
        }
    }

    // MARK: - Star Cell (star + sparkles)

    @ViewBuilder
    private func starCell(for index: Int) -> some View {
        let isFilled = index < stars
        let isRevealed = index < visibleCount
        let showGlow = glowActive.contains(index)

        ZStack {
            // --- Radiating golden glow behind filled stars ---
            if isFilled {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.1).opacity(showGlow ? 0.35 : 0.0),
                                Color(red: 1.0, green: 0.7, blue: 0.0).opacity(showGlow ? 0.12 : 0.0),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: starSize * 0.1,
                            endRadius: starSize * 0.9
                        )
                    )
                    .frame(width: starSize * 1.8, height: starSize * 1.8)
                    .scaleEffect(showGlow ? 1.0 : 0.5)
                    .animation(.easeOut(duration: 0.7).delay(Double(index) * 0.25), value: showGlow)
            }

            // --- The star itself ---
            starImage(for: index)

            // --- Sparkle particles around filled & revealed stars ---
            if isFilled && isRevealed {
                sparkleParticles(for: index)
            }
        }
    }

    // MARK: - Star Image

    @ViewBuilder
    private func starImage(for index: Int) -> some View {
        let isFilled = index < stars

        ZStack {
            if isFilled {
                // Filled star with rich gradient
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundStyle(filledGradient)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 10, y: 2)
                    .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3), radius: 20, y: 4)
                    // Subtle idle shimmer via overlay brightness
                    .brightness(shimmerActive ? 0.08 : 0.0)
            } else {
                // Empty star: outlined for better contrast against dark backgrounds
                ZStack {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundStyle(emptyColor)

                    Image(systemName: "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundStyle(emptyStrokeColor)
                }
            }
        }
    }

    // MARK: - Sparkle Particles

    @ViewBuilder
    private func sparkleParticles(for index: Int) -> some View {
        let seed = index * 137 // deterministic but varied per star
        let particleCount = 5

        ForEach(0 ..< particleCount, id: \.self) { i in
            let angle = Angle.degrees(Double(seed + i * 72))
            let distance = starSize * (0.55 + CGFloat(i % 3) * 0.12)

            Image(systemName: "sparkle")
                .font(.system(size: starSize * (i % 2 == 0 ? 0.2 : 0.14)))
                .foregroundStyle(
                    Color(red: 1.0, green: 0.9, blue: 0.4).opacity(shimmerActive ? 0.8 : 0.3)
                )
                .offset(
                    x: cos(angle.radians) * distance,
                    y: sin(angle.radians) * distance
                )
                .scaleEffect(shimmerActive ? 1.0 : 0.5)
                .opacity(shimmerActive ? 0.9 : 0.2)
                .animation(
                    .easeInOut(duration: 1.4 + Double(i) * 0.3)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15),
                    value: shimmerActive
                )
        }
    }

    // MARK: - Animation Helpers

    private func scaleForStar(at index: Int) -> CGFloat {
        guard animated else { return 1.0 }
        return index < visibleCount ? 1.0 : 0.01
    }

    private func rotationForStar(at index: Int) -> Double {
        guard animated else { return 0 }
        // Stars rotate slightly from -15 degrees to 0 as they pop in
        return index < visibleCount ? 0 : -15
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            StarRatingView(stars: 1)
            StarRatingView(stars: 2, starSize: 52)
            StarRatingView(stars: 3, animated: true, starSize: 52)
        }
    }
}
