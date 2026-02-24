import SwiftUI

/// A horizontal row of numbered dots that visualises the player's
/// progress through the 8 minigame steps.
///
/// - Completed steps are filled with a warm amber colour.
/// - The current step is highlighted with a larger, accented circle.
/// - Future steps are outlined / dimmed.
struct ProgressBarView: View {

    // MARK: - Input

    /// Zero-based index of the step the player is currently on (0 ... 7).
    let currentStep: Int

    /// Total number of steps in the sequence.
    let totalSteps: Int

    // MARK: - Constants

    private let completedColor = Color(red: 0xD4 / 255.0,
                                       green: 0xA5 / 255.0,
                                       blue: 0x74 / 255.0)      // #D4A574
    private let currentColor   = Color(red: 0x8B / 255.0,
                                       green: 0x25 / 255.0,
                                       blue: 0x00 / 255.0)      // #8B2500
    private let futureColor    = Color.white.opacity(0.35)

    private let dotSize: CGFloat        = 32
    private let currentDotSize: CGFloat = 42

    // MARK: - Init

    init(currentStep: Int, totalSteps: Int = 8) {
        self.currentStep = currentStep
        self.totalSteps  = totalSteps
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< totalSteps, id: \.self) { index in
                dot(for: index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassContainer()
        .accessibilityLabel("Minigame progress: step \(currentStep + 1) of 8")
    }

    // MARK: - Helpers

    @ViewBuilder
    private func dot(for index: Int) -> some View {
        let isCompleted = index < currentStep
        let isCurrent   = index == currentStep
        let size        = isCurrent ? currentDotSize : dotSize

        ZStack {
            if isCompleted {
                Circle()
                    .fill(completedColor)
                    .frame(width: size, height: size)
            } else if isCurrent {
                Circle()
                    .fill(currentColor)
                    .frame(width: size, height: size)
                    .shadow(color: currentColor.opacity(0.6), radius: 6, y: 2)
            } else {
                Circle()
                    .stroke(futureColor, lineWidth: 1.5)
                    .frame(width: size, height: size)
            }

            Text("\(index + 1)")
                .font(.system(size: isCurrent ? 16 : 13,
                              weight: .semibold,
                              design: .rounded))
                .foregroundStyle(
                    isCurrent || isCompleted
                        ? Color.white
                        : futureColor
                )
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            ProgressBarView(currentStep: 0)
            ProgressBarView(currentStep: 3)
            ProgressBarView(currentStep: 7)
        }
    }
}
