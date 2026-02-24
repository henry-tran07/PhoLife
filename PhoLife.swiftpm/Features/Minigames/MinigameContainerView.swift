import SwiftUI
import SpriteKit

struct MinigameContainerView: View {

    // MARK: - Input

    let gameState: GameState

    // MARK: - Phase

    enum MinigamePhase {
        case intro
        case playing
        case scoreReveal
    }

    // MARK: - State

    @State private var phase: MinigamePhase = .intro
    @State private var lastScore: Int = 0
    @State private var lastStars: Int = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: SpriteKit scene
            SpriteView(scene: makeScene())
                .ignoresSafeArea()
                .id(gameState.currentMinigameIndex)

            // Layer 2: Progress bar at top — non-interactive so touches pass through
            VStack {
                ProgressBarView(currentStep: gameState.currentMinigameIndex)
                    .padding(.top, 16)
                Spacer()
            }
            .allowsHitTesting(false)

            // Layer 3: Intro card
            if phase == .intro {
                MinigameIntroCard(
                    minigameIndex: gameState.currentMinigameIndex,
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            phase = .playing
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Layer 4: Score reveal card
            if phase == .scoreReveal {
                MinigameScoreCard(
                    stars: lastStars,
                    score: lastScore,
                    minigameIndex: gameState.currentMinigameIndex,
                    onContinue: {
                        let result = MinigameResult(
                            minigameIndex: gameState.currentMinigameIndex,
                            stars: lastStars,
                            score: lastScore
                        )
                        gameState.completeMinigame(result: result)
                        withAnimation(.easeInOut(duration: 0.4)) {
                            phase = .intro
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    // MARK: - Scene Factory

    private func makeScene() -> SKScene {
        let scene: SKScene
        switch gameState.currentMinigameIndex {
        case 0:
            let s = CharAromaticsScene()
            s.onComplete = completionHandler()
            scene = s
        case 1:
            let s = ToastSpicesScene()
            s.onComplete = completionHandler()
            scene = s
        case 2:
            let s = CleanBonesScene()
            s.onComplete = completionHandler()
            scene = s
        case 3:
            let s = SimmerBrothScene()
            s.onComplete = completionHandler()
            scene = s
        case 4:
            let s = SliceBeefScene()
            s.onComplete = completionHandler()
            scene = s
        case 5:
            let s = SeasonBrothScene()
            s.onComplete = completionHandler()
            scene = s
        case 6:
            let s = AssembleBowlScene()
            s.onComplete = completionHandler()
            scene = s
        case 7:
            let s = TopItOffScene()
            s.onComplete = completionHandler()
            scene = s
        default:
            let s = PlaceholderMinigameScene()
            s.onComplete = completionHandler()
            scene = s
        }
        scene.size = CGSize(width: 1194, height: 834)
        scene.scaleMode = .aspectFill
        return scene
    }

    private func completionHandler() -> (Int, Int) -> Void {
        return { (score: Int, stars: Int) in
            self.lastScore = score
            self.lastStars = stars
            withAnimation(.easeInOut(duration: 0.4)) {
                self.phase = .scoreReveal
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MinigameContainerView(gameState: GameState())
        .preferredColorScheme(.dark)
}
