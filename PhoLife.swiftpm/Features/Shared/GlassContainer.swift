import SwiftUI

/// A `ViewModifier` that wraps its content in a Liquid Glass container.
///
/// On iOS 26+ the native `.glassEffect()` modifier is applied.
/// On earlier versions (or if the API is unavailable at compile time)
/// the modifier falls back to `.ultraThinMaterial` with rounded corners,
/// keeping the visual language consistent across SDK targets.
struct GlassContainerModifier: ViewModifier {

    private let warmAmber = Color(red: 0xD4 / 255.0,
                                  green: 0xA5 / 255.0,
                                  blue: 0x74 / 255.0)

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(warmAmber.opacity(0.15), lineWidth: 0.5)
                )
        } else {
            content
                .background {
                    ZStack {
                        // Outer warm ambient shadow layer
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.25))
                            .blur(radius: 12)
                            .offset(y: 4)

                        // Primary frosted glass
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)

                        // Subtle warm tint overlay
                        RoundedRectangle(cornerRadius: 16)
                            .fill(warmAmber.opacity(0.04))

                        // Inner glow — top highlight simulating light source
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear,
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Warm-tinted border with subtle gradient
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        warmAmber.opacity(0.25),
                                        warmAmber.opacity(0.08),
                                        warmAmber.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
                }
        }
    }
}

// MARK: - View Extension

extension View {

    /// Apply PhoLife's Liquid Glass container styling.
    ///
    /// Uses the native iOS 26 glass effect when available and falls
    /// back to a blurred material background otherwise.
    func glassContainer() -> some View {
        modifier(GlassContainerModifier())
    }
}
