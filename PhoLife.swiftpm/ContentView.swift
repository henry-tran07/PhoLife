import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()

    var body: some View {
        ZStack {
            switch gameState.currentPhase {
            case .splash:
                SplashView(onComplete: {
                    gameState.currentPhase = .story
                })
            case .story:
                StoryView(
                    onComplete: {
                        gameState.currentPhase = .minigames
                    },
                    onSkip: {
                        gameState.skipToMinigames()
                    }
                )
            case .minigames:
                MinigameContainerView(gameState: gameState)
            case .completion:
                CompletionView(gameState: gameState)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: gameState.currentPhase)
        .ignoresSafeArea()
        .statusBarHidden(true)
    }
}
