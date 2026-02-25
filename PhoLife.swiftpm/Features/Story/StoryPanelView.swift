import SwiftUI

struct StoryPanelView: View {

    let panel: StoryPanel
    var onComplete: (() -> Void)? = nil

    // MARK: - State

    @State private var titleVisible = false
    @State private var bodyVisible = false
    @State private var imageScale: CGFloat = 1.0
    @State private var displayedCharCount = 0

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let placeholderColor = Color(red: 0.15, green: 0.1, blue: 0.08)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)

    /// True when this panel is the opening title card (no body text).
    private var isTitleCard: Bool { panel.bodyText.isEmpty }

    /// Full body text with un-revealed characters transparent (stable layout during typewriter).
    private var typewriterText: AttributedString {
        var result = AttributedString(panel.bodyText)
        let total = panel.bodyText.count
        guard displayedCharCount < total else { return result }
        let visibleEnd = result.characters.index(result.startIndex, offsetBy: displayedCharCount)
        result[visibleEnd..<result.endIndex].foregroundColor = .clear
        return result
    }

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

            // Text overlay — dynamically sized to fit
            if isTitleCard {
                ViewThatFits(in: .vertical) {
                    titleText(fontSize: 52)
                    titleText(fontSize: 46)
                    titleText(fontSize: 40)
                }
                .padding(.horizontal, 48)
            } else {
                VStack {
                    titleText(fontSize: 46)
                        .padding(.top, 56)

                    Spacer(minLength: 16)

                    // "Let's Cook" CTA above the caption on the final panel
                    if let onComplete {
                        Button {
                            HapticManager.shared.heavy()
                            onComplete()
                        } label: {
                            Text("Let's Cook")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 48)
                                .padding(.vertical, 18)
                                .background(warmAmber, in: Capsule())
                        }
                        .accessibilityLabel("Start cooking minigames")
                        .padding(.bottom, 16)
                    }

                    // Body uses ViewThatFits to step down font size
                    ViewThatFits(in: .vertical) {
                        bodyText(fontSize: 30)
                        bodyText(fontSize: 26)
                        bodyText(fontSize: 22)
                    }
                    .padding(.bottom, 56)
                }
            }
        }
        .onAppear {
            titleVisible = false
            bodyVisible = false
            imageScale = 1.0
            displayedCharCount = 0

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
        .task(id: panel.id) {
            guard !isTitleCard else { return }
            // Wait for glass container fade-in before typing starts
            try? await Task.sleep(for: .milliseconds(700))
            for i in 1...panel.bodyText.count {
                if Task.isCancelled { return }
                displayedCharCount = i
                try? await Task.sleep(for: .milliseconds(25))
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func titleText(fontSize: CGFloat) -> some View {
        Text(panel.title)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(warmAmber)
            .shadow(color: .black.opacity(0.6), radius: 5, x: 0, y: 2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .glassEffect24()
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 15)
    }

    @ViewBuilder
    private func bodyText(fontSize: CGFloat) -> some View {
        Text(typewriterText)
            .font(.system(size: fontSize, weight: .medium, design: .default))
            .italic()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .containerRelativeFrame(.horizontal) { length, _ in
                length * 0.82
            }
            .glassEffect24()
            .opacity(bodyVisible ? 1 : 0)
            .offset(y: bodyVisible ? 0 : 15)
    }
}

// MARK: - Glass Effect (cornerRadius 24)

private extension View {

    /// Applies frosted glass styling with a 24-pt corner radius.
    @ViewBuilder
    func glassEffect24() -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
