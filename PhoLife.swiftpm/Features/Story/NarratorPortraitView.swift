import SwiftUI

struct NarratorPortraitView: View {

    let expression: NarratorExpression
    let isSpeaking: Bool

    // MARK: - State

    @State private var breatheScale: CGFloat = 1.0
    @State private var speakOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(NarratorExpression.allCases, id: \.self) { expr in
                Image(expr.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(expr == expression ? 1 : 0)
                    .animation(.easeInOut(duration: 0.35), value: expression)
            }
        }
        .scaleEffect(breatheScale)
        .offset(y: speakOffset)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.02
            }
        }
        .onChange(of: isSpeaking) { _, speaking in
            if speaking {
                withAnimation(
                    .easeInOut(duration: 0.15)
                    .repeatForever(autoreverses: true)
                ) {
                    speakOffset = -3
                }
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    speakOffset = 0
                }
            }
        }
    }
}
