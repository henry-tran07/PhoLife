import SwiftUI

/// A reusable row of star icons that displays how many stars a
/// player has earned (1-3) out of a configurable maximum.
///
/// Filled stars use a yellow/gold colour and the `star.fill` SF Symbol;
/// unearned stars use gray and the `star` SF Symbol.
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

    // MARK: - State

    @State private var visibleCount: Int = 0

    // MARK: - Constants

    private let filledColor = Color.yellow
    private let emptyColor  = Color.gray.opacity(0.45)
    private let starSize: CGFloat = 36

    // MARK: - Init

    init(stars: Int, maxStars: Int = 3, animated: Bool = false) {
        self.stars    = stars
        self.maxStars = maxStars
        self.animated = animated
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< maxStars, id: \.self) { index in
                starImage(for: index)
                    .scaleEffect(scaleForStar(at: index))
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                            .delay(animated ? Double(index) * 0.2 : 0),
                        value: visibleCount
                    )
            }
        }
        .onAppear {
            if animated {
                // Start with nothing visible, then reveal earned stars.
                visibleCount = 0
                withAnimation {
                    visibleCount = stars
                }
            } else {
                visibleCount = stars
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func starImage(for index: Int) -> some View {
        let isFilled = index < stars

        Image(systemName: isFilled ? "star.fill" : "star")
            .resizable()
            .scaledToFit()
            .frame(width: starSize, height: starSize)
            .foregroundStyle(isFilled ? filledColor : emptyColor)
    }

    private func scaleForStar(at index: Int) -> CGFloat {
        guard animated else { return 1.0 }
        return index < visibleCount ? 1.0 : 0.01
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            StarRatingView(stars: 1)
            StarRatingView(stars: 2)
            StarRatingView(stars: 3, animated: true)
        }
    }
}
