import UIKit

/// Thin wrapper around `UIFeedbackGenerator` that provides named
/// convenience methods for the haptic patterns used throughout PhoLife.
@MainActor
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact

    /// A subtle, light tap -- used for minor UI interactions such as
    /// highlighting a dot in the progress bar.
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// A moderate tap -- used for standard game interactions like
    /// catching a spice or popping a bubble.
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// A strong tap -- used for significant moments like dropping an
    /// ingredient into the bowl or completing a minigame.
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification

    /// A success pattern -- used when the player earns stars or
    /// completes a step correctly.
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// An error pattern -- used for wrong answers, burns, or other
    /// negative outcomes.
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
