import SwiftUI

struct StoryView: View {

    var onComplete: () -> Void
    var onSkip: () -> Void

    // MARK: - State

    @State private var currentIndex = 1

    // MARK: - Constants

    private let panels = StoryPanel.allPanels
    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)  // #D4A574
    private let lastPanelID = 10

    // MARK: - Body

    var body: some View {
        ZStack {
            // Paging story content
            TabView(selection: $currentIndex) {
                ForEach(panels) { panel in
                    StoryPanelView(panel: panel)
                        .tag(panel.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Top-right skip button — always visible
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip to Cook ▸")
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

            // Bottom overlay: page dots or "Let's Cook" button
            VStack {
                Spacer()

                if currentIndex == lastPanelID {
                    // Final panel — show "Let's Cook" CTA
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
                    .padding(.bottom, 48)
                } else {
                    // Page indicator dots
                    HStack(spacing: 8) {
                        ForEach(panels) { panel in
                            Circle()
                                .fill(panel.id == currentIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .animation(.easeInOut(duration: 0.25), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 48)
                }
            }
        }
    }
}
