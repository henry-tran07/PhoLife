import SwiftUI

/// A `ViewModifier` that wraps its content in a frosted glass container
/// using `.ultraThinMaterial` with rounded corners and warm amber accents.
struct GlassContainerModifier: ViewModifier {

    private let warmAmber = Color(red: 0xD4 / 255.0,
                                  green: 0xA5 / 255.0,
                                  blue: 0x74 / 255.0)

    func body(content: Content) -> some View {
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

// MARK: - View Extension

extension View {

    /// Apply PhoLife's Liquid Glass container styling.
    ///
    /// Applies a frosted glass background with warm amber accents.
    func glassContainer() -> some View {
        modifier(GlassContainerModifier())
    }
}
