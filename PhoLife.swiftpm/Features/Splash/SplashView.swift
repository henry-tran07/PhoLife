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
                // Bowl image with steam effect
                Image("splash-bowl")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
                    .scaleEffect(bowlVisible ? 1.05 : 1.0)
                    .opacity(bowlVisible ? 1 : 0)
                    .accessibilityLabel("A beautiful bowl of Vietnamese pho")
                    .overlay(alignment: .top) {
                        // Steam effect — overlaid circles with blur that drift upward
                        ZStack {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(.white.opacity(0.15))
                                    .frame(width: CGFloat(30 + i * 15), height: CGFloat(30 + i * 15))
                                    .blur(radius: 15)
                                    .offset(
                                        x: CGFloat([-20, 5, 20][i]),
                                        y: bowlVisible ? CGFloat(-80 - i * 30) : -20
                                    )
                                    .opacity(bowlVisible ? 0 : 0.6)
                            }
                        }
                        .allowsHitTesting(false)
                    }

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
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
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
