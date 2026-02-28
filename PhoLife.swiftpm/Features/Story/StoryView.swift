import SwiftUI

struct StoryView: View {

    var onComplete: () -> Void
    var onSkip: () -> Void

    // MARK: - State

    @State private var currentPanelIndex: Int = 0
    @State private var currentSegmentIndex: Int = 0
    @State private var isTypewriting: Bool = false
    @State private var typewriterComplete: Bool = false

    // MARK: - Constants

    private let panels = StoryPanel.allPanels
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)

    /// Current panel from the panels array.
    private var currentPanel: StoryPanel {
        panels[currentPanelIndex]
    }

    // MARK: - Progress Calculation

    /// Total number of "steps" across all panels (panels with empty segments count as 1).
    private var totalSteps: Int {
        panels.reduce(0) { $0 + max($1.dialogueSegments.count, 1) }
    }

    /// Number of completed steps so far.
    private var completedSteps: Int {
        var count = 0
        for i in 0..<currentPanelIndex {
            count += max(panels[i].dialogueSegments.count, 1)
        }
        count += currentSegmentIndex
        return count
    }

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(completedSteps) / CGFloat(totalSteps)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: Background
            StoryBackgroundView(
                currentImageName: currentPanel.imageName,
                panelId: currentPanel.id
            )

            // Layer 2: Dialogue overlay
            StoryPanelView(
                panel: currentPanel,
                segmentIndex: currentSegmentIndex,
                isTypewriting: $isTypewriting,
                typewriterComplete: $typewriterComplete,
                onComplete: currentPanel.id == 10 ? onComplete : nil
            )
            .id("\(currentPanel.id)-\(currentSegmentIndex)")

            // Layer 3: Full-screen tap target (disabled on final panel so CTA button is tappable)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }
                .allowsHitTesting(!(currentPanel.id == panels.last?.id && !isTypewriting && currentSegmentIndex >= currentPanel.dialogueSegments.count - 1))

            // Layer 4: Skip button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip to Cook \u{25B8}")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .glassContainer()
                    }
                    .accessibilityLabel("Skip to cooking minigames")
                    .padding(.top, 16)
                    .padding(.trailing, 24)
                }
                Spacer()
            }

            // Layer 5: Progress bar (bottom)
            VStack {
                Spacer()
                progressBar
                    .padding(.horizontal, 48)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            Capsule()
                .fill(warmAmber.opacity(0.2))
                .frame(height: 3)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(warmAmber.opacity(0.5))
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
        }
        .frame(height: 3)
    }

    // MARK: - Tap Handler

    private func handleTap() {
        let panel = currentPanel

        // 1. If typewriting, skip to end of current text
        if isTypewriting {
            typewriterComplete = true
            return
        }

        // 2. If more segments in this panel, advance segment
        if !panel.dialogueSegments.isEmpty,
           currentSegmentIndex < panel.dialogueSegments.count - 1 {
            HapticManager.shared.light()
            AudioManager.shared.playSFX("button-tap")
            typewriterComplete = false
            currentSegmentIndex += 1
            return
        }

        // 3. If more panels, advance to next panel
        if currentPanelIndex < panels.count - 1 {
            HapticManager.shared.light()
            AudioManager.shared.playSFX("button-tap")
            currentPanelIndex += 1
            currentSegmentIndex = 0
            typewriterComplete = false
            return
        }

        // 4. Final panel — do nothing (CTA button handles exit)
    }
}
