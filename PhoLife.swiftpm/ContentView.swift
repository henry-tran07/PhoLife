import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()

    /// Tracks the previous phase so we can determine transition direction.
    @State private var previousPhase: GameState.AppPhase = .splash

    var body: some View {
        ZStack {
            // Dark background that persists across all phases to avoid white flashes.
            Color(red: 0.08, green: 0.05, blue: 0.03)
                .ignoresSafeArea()

            ZStack {
                switch gameState.currentPhase {
                case .splash:
                    SplashView(onComplete: {
                        gameState.currentPhase = .story
                    })
                    .transition(splashTransition)

                case .story:
                    StoryView(
                        onComplete: {
                            gameState.currentPhase = .minigames
                        },
                        onSkip: {
                            gameState.skipToMinigames()
                        }
                    )
                    .transition(storyTransition)

                case .minigames:
                    MinigameContainerView(gameState: gameState)
                        .transition(minigamesTransition)

                case .completion:
                    CompletionView(gameState: gameState)
                        .transition(completionTransition)
                }
            }
        }
        .animation(.smooth(duration: 0.7, extraBounce: 0.02), value: gameState.currentPhase)
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onChange(of: gameState.currentPhase) { oldPhase, newPhase in
            previousPhase = oldPhase

            switch newPhase {
            case .splash, .story:
                break
            case .minigames:
                AudioManager.shared.playMusic("gameplay-music")
            case .completion:
                AudioManager.shared.playMusic("completion-music")
            }
        }
    }

    // MARK: - Phase Transitions

    /// Splash fades out with a slight scale-up, as if the title card is
    /// expanding and dissolving before the story begins.
    private var splashTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity,
            removal: .opacity.combined(with: .scale(scale: 1.05))
        )
    }

    /// Story slides in from the trailing edge and fades/shrinks out
    /// when advancing to minigames.
    private var storyTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.94))
        )
    }

    /// Minigames zoom in from a slightly smaller size with a fade, giving
    /// a dramatic "enter the kitchen" feel. Exits by scaling up and fading.
    private var minigamesTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 1.06))
        )
    }

    /// Completion enters with a warm scale-up bloom (celebratory reveal).
    private var completionTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.85).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.94))
        )
    }
}
