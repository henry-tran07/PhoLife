import SwiftUI

struct StoryPanelView: View {

    let panel: StoryPanel

    // MARK: - State

    @State private var textVisible = false
    @State private var imageScale: CGFloat = 1.0

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let placeholderColor = Color(red: 0.15, green: 0.1, blue: 0.08)
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)  // #FFF8DC

    // MARK: - Body

    var body: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            // Panel image — fills the screen with slow zoom
            Image(panel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(imageScale)
                .clipped()
                .ignoresSafeArea()
                .accessibilityLabel("Story illustration: \(panel.title)")

            // Text overlay
            VStack {
                // Title at top
                Text(panel.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .glassContainer()
                    .opacity(textVisible ? 1 : 0)
                    .padding(.top, 64)

                Spacer()

                // Body text at bottom
                if !panel.bodyText.isEmpty {
                    Text(panel.bodyText)
                        .font(.system(size: 18))
                        .foregroundStyle(cream)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .glassContainer()
                        .opacity(textVisible ? 1 : 0)
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            textVisible = false
            imageScale = 1.0
            withAnimation(.easeIn(duration: 0.8)) {
                textVisible = true
            }
            withAnimation(.easeInOut(duration: 8.0)) {
                imageScale = 1.08
            }
        }
    }
}
