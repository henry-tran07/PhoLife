import SwiftUI

/// A horizontal row of cooking-step icons that visualises the player's
/// progress through the 8 minigame steps.
///
/// - Completed steps are filled with a warm amber colour and a checkmark badge.
/// - The current step is highlighted with a larger, accented circle.
/// - Future steps are outlined / dimmed.
/// - Thin connecting lines run between each dot.
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

    private let stepIcons: [String] = [
        "flame",
        "star.circle",
        "bubbles.and.sparkles",
        "gauge.with.dots.needle.bottom.50percent",
        "scissors",
        "slider.horizontal.3",
        "square.stack.3d.down.right",
        "leaf"
    ]

    // MARK: - Init

    init(currentStep: Int, totalSteps: Int = 8) {
        self.currentStep = currentStep
        self.totalSteps  = totalSteps
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< totalSteps, id: \.self) { index in
                dot(for: index)

                // Connecting line between dots
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(index < currentStep ? completedColor : futureColor)
                        .frame(height: 2)
                        .frame(maxWidth: 16)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentStep)
                }
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

            // Cooking step icon
            Image(systemName: stepIcons[safe: index] ?? "circle")
                .font(.system(size: isCurrent ? 16 : 13, weight: .semibold))
                .foregroundStyle(
                    isCurrent || isCompleted
                        ? Color.white
                        : futureColor
                )

            // Checkmark badge on completed steps
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                    .offset(x: size / 2 - 2, y: size / 2 - 2)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentStep)
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
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            ProgressBarView(currentStep: 0)
            ProgressBarView(currentStep: 3)
            ProgressBarView(currentStep: 7)
        }
    }
}
