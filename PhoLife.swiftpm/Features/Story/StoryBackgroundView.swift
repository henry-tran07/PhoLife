import SwiftUI

struct StoryBackgroundView: View {

    let currentImageName: String
    let panelId: Int

    // MARK: - State

    @State private var imageScale: CGFloat = 1.0

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)

    // MARK: - Body

    var body: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            Image(currentImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(imageScale)
                .clipped()
                .ignoresSafeArea()
                .accessibilityLabel("Story illustration")
                .id(currentImageName)
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
        }
        .animation(.easeInOut(duration: 0.6), value: currentImageName)
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0)) {
                imageScale = 1.08
            }
        }
        .onChange(of: panelId) { _, _ in
            imageScale = 1.0
            withAnimation(.easeInOut(duration: 8.0)) {
                imageScale = 1.08
            }
        }
    }
}
