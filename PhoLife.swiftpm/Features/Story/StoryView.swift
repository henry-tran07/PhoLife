import SwiftUI

struct StoryView: View {

    var onComplete: () -> Void
    var onSkip: () -> Void

    // MARK: - State

    @State private var currentIndex: Int? = 1

    // MARK: - Constants

    private let panels = StoryPanel.allPanels
    private let lastPanelID = 10

    // MARK: - Body

    var body: some View {
        ZStack {
            // Paging story content
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(panels) { panel in
                        StoryPanelView(
                            panel: panel,
                            onComplete: panel.id == lastPanelID ? onComplete : nil
                        )
                            .containerRelativeFrame(.horizontal)
                            .scrollTransition(.animated(.easeInOut(duration: 0.4))) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.6)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentIndex)
            .scrollIndicators(.hidden)
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

            // Bottom overlay: page dots
            VStack {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(panels) { panel in
                        Circle()
                            .fill(panel.id == currentIndex ? .white : .white.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .animation(.easeInOut(duration: 0.25), value: currentIndex)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}
