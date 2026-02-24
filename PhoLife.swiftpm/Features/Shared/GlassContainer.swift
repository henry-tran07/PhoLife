import SwiftUI

/// A `ViewModifier` that wraps its content in a Liquid Glass container.
///
/// On iOS 26+ the native `.glassEffect()` modifier is applied.
/// On earlier versions (or if the API is unavailable at compile time)
/// the modifier falls back to `.ultraThinMaterial` with rounded corners,
/// keeping the visual language consistent across SDK targets.
struct GlassContainerModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
