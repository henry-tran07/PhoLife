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

            // Layer 2: Progress bar + skip button at top
            VStack {
                HStack {
                    Spacer()
                    ProgressBarView(currentStep: gameState.currentMinigameIndex)
                    Spacer()
                    // Debug: skip minigame
                    if phase == .playing {
                        Button {
                            completionHandler()(50, 1)
                        } label: {
                            Text("Skip ▸")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 16)
                Spacer()
            }
            .allowsHitTesting(phase == .playing)

            // Layer 3: Intro card
            if phase == .intro {
                MinigameIntroCard(
                    minigameIndex: gameState.currentMinigameIndex,
                    onStart: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            phase = .playing
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.8))
                ))
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
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            phase = .intro
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .scoreReveal:
                AudioManager.shared.playSFX("star-reveal")
            case .playing:
                AudioManager.shared.playAmbient("kitchen-ambient")
            case .intro:
                AudioManager.shared.stopAmbient()
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
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
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
