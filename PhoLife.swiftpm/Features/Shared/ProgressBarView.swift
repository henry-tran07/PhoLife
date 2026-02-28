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

    // MARK: - State

    /// Drives the pulsing glow on the current step indicator.
    @State private var isPulsing = false

    /// Tracks which steps have played their checkmark pop-in so we only animate once.
    @State private var checkmarkRevealed: Set<Int> = []

    /// Controls staggered line fill animation.
    @State private var linesAnimated = false

    // MARK: - Constants

    private let completedColor = Color(red: 0xD4 / 255.0,
                                       green: 0xA5 / 255.0,
                                       blue: 0x74 / 255.0)      // #D4A574
    private let currentColor   = Color(red: 0x8B / 255.0,
                                       green: 0x25 / 255.0,
                                       blue: 0x00 / 255.0)      // #8B2500
    private let futureColor    = Color.white.opacity(0.25)

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
                    connectingLine(after: index)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassContainer()
        .accessibilityLabel("Minigame progress: step \(currentStep + 1) of 8")
        .onAppear {
            // Start the pulsing animation for the current step
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
            // Mark all previously completed steps as already revealed
            for i in 0 ..< currentStep {
                checkmarkRevealed.insert(i)
            }
            // Trigger line animation
            withAnimation(.easeOut(duration: 0.5)) {
                linesAnimated = true
            }
        }
        .onChange(of: currentStep) { oldValue, newValue in
            // Animate checkmark reveal for the step that just completed
            if oldValue < newValue && oldValue >= 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    _ = checkmarkRevealed.insert(oldValue)
                }
            }
        }
    }

    // MARK: - Connecting Line

    @ViewBuilder
    private func connectingLine(after index: Int) -> some View {
        let isCompleted = index < currentStep

        ZStack {
            // Base track
            Capsule()
                .fill(futureColor.opacity(0.4))
                .frame(height: 2)
                .frame(maxWidth: 16)

            // Filled progress overlay with warm gradient
            if isCompleted {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                completedColor,
                                completedColor.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2.5)
                    .frame(maxWidth: 16)
                    .shadow(color: completedColor.opacity(0.4), radius: 3, y: 0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
    }

    // MARK: - Dot

    @ViewBuilder
    private func dot(for index: Int) -> some View {
        let isCompleted = index < currentStep
        let isCurrent   = index == currentStep
        let size        = isCurrent ? currentDotSize : dotSize

        ZStack {
            // --- Background circle ---
            if isCompleted {
                // Completed: warm amber filled with subtle inner shadow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                completedColor.opacity(0.95),
                                completedColor.opacity(0.75)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: completedColor.opacity(0.35), radius: 4, y: 1)
            } else if isCurrent {
                // Pulsing glow ring behind the current step
                Circle()
                    .fill(currentColor.opacity(0.15))
                    .frame(width: size + 12, height: size + 12)
                    .scaleEffect(isPulsing ? 1.15 : 0.95)

                // Main current step circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                currentColor.opacity(0.9),
                                currentColor
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: currentColor.opacity(0.6), radius: 8, y: 2)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
            } else {
                // Future: outlined with a faint warm tint
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(futureColor, lineWidth: 1.5)
                    )
            }

            // --- Step icon ---
            Image(systemName: stepIcons[safe: index] ?? "circle")
                .font(.system(size: isCurrent ? 16 : 13, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isCurrent || isCompleted
                        ? Color.white
                        : futureColor
                )
                .shadow(
                    color: isCurrent ? Color.white.opacity(0.3) : .clear,
                    radius: 2
                )

            // --- Checkmark badge on completed steps ---
            if isCompleted {
                checkmarkBadge(size: size, index: index)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentStep)
    }

    // MARK: - Checkmark Badge

    @ViewBuilder
    private func checkmarkBadge(size: CGFloat, index: Int) -> some View {
        let revealed = checkmarkRevealed.contains(index)

        ZStack {
            // White backing circle for contrast
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.8, blue: 0.3),
                            Color(red: 0.2, green: 0.65, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .offset(x: size / 2 - 2, y: size / 2 - 2)
        .scaleEffect(revealed ? 1.0 : 0.01)
        .opacity(revealed ? 1.0 : 0.0)
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
