import SwiftUI

struct StoryPanelView: View {

    let panel: StoryPanel
    let segmentIndex: Int
    @Binding var isTypewriting: Bool
    @Binding var typewriterComplete: Bool
    var onComplete: (() -> Void)? = nil

    // MARK: - State

    @State private var titleVisible = false
    @State private var dialogueVisible = false
    @State private var displayedCharCount = 0
    @State private var showTapIndicator = false
    @State private var ctaVisible = false

    // MARK: - Constants

    private let warmBackground = Color(red: 0.08, green: 0.05, blue: 0.03)
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)

    /// True when this panel is a title card (no dialogue segments).
    private var isTitleCard: Bool { panel.dialogueSegments.isEmpty }

    /// The current dialogue segment, if any.
    private var currentSegment: DialogueSegment? {
        guard !panel.dialogueSegments.isEmpty,
              segmentIndex < panel.dialogueSegments.count else { return nil }
        return panel.dialogueSegments[segmentIndex]
    }

    /// Typewriter attributed string — unrevealed characters are transparent for stable layout.
    private var typewriterText: AttributedString {
        guard let segment = currentSegment else { return AttributedString("") }
        var result = AttributedString(segment.text)
        let total = segment.text.count
        guard displayedCharCount < total else { return result }
        let visibleEnd = result.characters.index(result.startIndex, offsetBy: displayedCharCount)
        result[visibleEnd..<result.endIndex].foregroundColor = .clear
        return result
    }

    // MARK: - Body

    var body: some View {
        if isTitleCard {
            titleCardLayout
        } else {
            normalPanelLayout
        }
    }

    // MARK: - Title Card Layout

    private var titleCardLayout: some View {
        VStack {
            Spacer()

            ViewThatFits(in: .vertical) {
                titleText(fontSize: 52)
                titleText(fontSize: 46)
                titleText(fontSize: 40)
            }
            .padding(.horizontal, 48)

            Spacer()

            // Small narrator peek at bottom
            NarratorPortraitView(expression: panel.expression, isSpeaking: false)
                .frame(width: 120, height: 120)
                .opacity(titleVisible ? 1 : 0)
                .animation(.spring(duration: 0.6).delay(0.2), value: titleVisible)
                .padding(.bottom, 48)
        }
        .onAppear { animateEntrance() }
    }

    // MARK: - Normal Panel Layout

    private var normalPanelLayout: some View {
        VStack {
            titleText(fontSize: 46)
                .padding(.top, 56)

            Spacer(minLength: 16)

            // CTA button for the final panel
            if panel.id == 10, let onComplete {
                Button {
                    HapticManager.shared.heavy()
                    onComplete()
                } label: {
                    Text("Let's Cook")
                        .font(.custom("SFCompactRounded-Bold", size: 22))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 18)
                        .background(warmAmber, in: Capsule())
                }
                .accessibilityLabel("Start cooking minigames")
                .opacity(ctaVisible ? 1 : 0)
                .offset(y: ctaVisible ? 0 : 10)
                .animation(.spring(duration: 0.5), value: ctaVisible)
                .padding(.bottom, 16)
            }

            // Dialogue box
            dialogueBox
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.75
                }
                .padding(.bottom, 32)
        }
        .onAppear { animateEntrance() }
        .task(id: "\(panel.id)-\(segmentIndex)") {
            await runTypewriter()
        }
    }

    // MARK: - Dialogue Box

    private var dialogueBox: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Narrator portrait
            NarratorPortraitView(
                expression: isTypewriting ? .speak : .happy,
                isSpeaking: isTypewriting
            )
            .frame(width: 140, height: 140)
            .opacity(dialogueVisible ? 1 : 0)
            .animation(.spring(duration: 0.6).delay(0.2), value: dialogueVisible)

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text("Narrator")
                    .font(.custom("SFCompactRounded-Bold", size: 18))
                    .foregroundStyle(warmAmber)

                Text(typewriterText)
                    .font(.custom("SFCompactRounded-Medium", size: 30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)

                // Tap-to-continue indicator
                if showTapIndicator {
                    Text("\u{25BC}")
                        .font(.custom("SFCompactRounded-Regular", size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .modifier(PulseModifier())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .glassContainer()
        .opacity(dialogueVisible ? 1 : 0)
        .offset(y: dialogueVisible ? 0 : 30)
        .animation(.spring(duration: 0.5).delay(0.2), value: dialogueVisible)
    }

    // MARK: - Title Text

    @ViewBuilder
    private func titleText(fontSize: CGFloat) -> some View {
        Text(panel.title)
            .font(.custom("SFCompactRounded-Bold", size: fontSize))
            .foregroundStyle(warmAmber)
            .shadow(color: .black.opacity(0.6), radius: 5, x: 0, y: 2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .glassEffect24()
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 15)
            .animation(.spring(duration: 0.6).delay(0.1), value: titleVisible)
    }

    // MARK: - Animation Choreography

    private func animateEntrance() {
        titleVisible = false
        dialogueVisible = false
        showTapIndicator = false
        ctaVisible = false
        displayedCharCount = 0

        // T+100ms: Title slides in
        withAnimation(.spring(duration: 0.6).delay(0.1)) {
            titleVisible = true
        }

        // T+200ms: Dialogue box slides up
        if !isTitleCard {
            withAnimation(.spring(duration: 0.5).delay(0.2)) {
                dialogueVisible = true
            }
        }
    }

    // MARK: - Typewriter

    private func runTypewriter() async {
        guard let segment = currentSegment else { return }

        displayedCharCount = 0
        showTapIndicator = false
        ctaVisible = false
        typewriterComplete = false
        isTypewriting = true

        // Wait 400ms for entrance animations
        try? await Task.sleep(for: .milliseconds(400))

        let totalChars = segment.text.count
        for i in 1...totalChars {
            if Task.isCancelled { return }

            // If user tapped to skip, reveal all immediately
            if typewriterComplete {
                displayedCharCount = totalChars
                break
            }

            displayedCharCount = i
            let charIndex = segment.text.index(segment.text.startIndex, offsetBy: i - 1)
            let char = segment.text[charIndex]
            if !char.isWhitespace && !".,!?;:—\u{2014}".contains(char) {
                AudioManager.shared.playSFX("text-blip-\(Int.random(in: 0...2))")
            }
            try? await Task.sleep(for: .milliseconds(25))
        }

        isTypewriting = false

        // Wait 300ms then show tap indicator
        try? await Task.sleep(for: .milliseconds(300))
        if Task.isCancelled { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            showTapIndicator = true
        }

        // Show CTA on final panel after typewriter
        if panel.id == 10 && segmentIndex == panel.dialogueSegments.count - 1 {
            withAnimation(.spring(duration: 0.5)) {
                ctaVisible = true
            }
        }
    }
}

// MARK: - Pulse Modifier

private struct PulseModifier: ViewModifier {

    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.3 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
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
