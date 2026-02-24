import SwiftUI

struct StoryPanelView: View {

    let panel: StoryPanel

    // MARK: - State

    @State private var titleVisible = false
    @State private var bodyVisible = false
    @State private var imageScale: CGFloat = 1.0

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let placeholderColor = Color(red: 0.15, green: 0.1, blue: 0.08)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)

    /// True when this panel is the opening title card (no body text).
    private var isTitleCard: Bool { panel.bodyText.isEmpty }

    // MARK: - Body

    var body: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            // Panel image — fills the screen with slow Ken Burns zoom
            Image(panel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(imageScale)
                .clipped()
                .ignoresSafeArea()
                .accessibilityLabel("Story illustration: \(panel.title)")

            // Text overlay
            if isTitleCard {
                // Special layout: centered title card
                titleText(fontSize: 48)
                    .padding(.horizontal, 48)
            } else {
                VStack {
                    // Title pinned toward top
                    titleText(fontSize: 42)
                        .padding(.top, 80)

                    Spacer()

                    // Body text pinned toward bottom
                    bodyText
                        .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            titleVisible = false
            bodyVisible = false
            imageScale = 1.0

            // Title fades & slides in first
            withAnimation(.easeOut(duration: 0.6)) {
                titleVisible = true
            }

            // Body text follows 0.3s later
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                bodyVisible = true
            }

            // Slow Ken Burns zoom
            withAnimation(.easeInOut(duration: 8.0)) {
                imageScale = 1.08
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func titleText(fontSize: CGFloat) -> some View {
        Text(panel.title)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(warmAmber)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .glassEffect24()
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 15)
    }

    @ViewBuilder
    private var bodyText: some View {
        Text(panel.bodyText)
            .font(.system(size: 26, weight: .regular, design: .default))
            .italic()
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .glassEffect24()
            .padding(.horizontal, 40)
            .opacity(bodyVisible ? 1 : 0)
            .offset(y: bodyVisible ? 0 : 15)
    }
}

// MARK: - Glass Effect (cornerRadius 24)

private extension View {

    /// Applies Liquid Glass with a 24-pt corner radius on iOS 26+,
    /// falling back to ultra-thin material on earlier versions.
    @ViewBuilder
    func glassEffect24() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}
