import SwiftUI

struct SplashView: View {

    var onComplete: () -> Void

    // MARK: - Animation State

    @State private var bowlVisible = false
    @State private var titleVisible = false
    @State private var subtitleVisible = false

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let cream = Color(red: 1.0, green: 248 / 255, blue: 220 / 255)             // #FFF8DC

    // MARK: - Body

    var body: some View {
        ZStack {
            warmBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Bowl placeholder
                Text("🍜")
                    .font(.system(size: 120))
                    .opacity(bowlVisible ? 1 : 0)

                // Title
                Text("PhoLife")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(warmAmber)
                    .opacity(titleVisible ? 1 : 0)

                // Subtitle
                Text("The story of Vietnamese phở")
                    .font(.system(size: 20))
                    .foregroundStyle(cream.opacity(0.7))
                    .opacity(subtitleVisible ? 1 : 0)
            }
        }
        .transition(.opacity)
        .onAppear {
            // Staggered fade-in: bowl first, title 0.5s later, subtitle 0.5s after
            withAnimation(.easeIn(duration: 0.8)) {
                bowlVisible = true
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
                titleVisible = true
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.0)) {
                subtitleVisible = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(3.5))
            onComplete()
        }
    }
}
