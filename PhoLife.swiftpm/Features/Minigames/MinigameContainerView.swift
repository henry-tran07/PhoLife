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
    @State private var sceneBlur: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: SpriteKit scene with dynamic blur
            SpriteView(scene: makeScene())
                .ignoresSafeArea()
                .id(gameState.currentMinigameIndex)
                .blur(radius: sceneBlur)
                .animation(.easeInOut(duration: 0.4), value: sceneBlur)

            // Layer 2: Progress bar + skip button at top
            VStack {
                HStack {
                    Spacer()
                    ProgressBarView(currentStep: gameState.currentMinigameIndex)
                    Spacer()
                    // Debug: skip minigame — hidden for now
//                    if phase == .playing {
//                        Button {
//                            completionHandler()(50, 1)
//                        } label: {
//                            Text("Skip ▸")
//                                .font(.system(size: 13, weight: .medium))
//                                .foregroundStyle(.white.opacity(0.7))
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(.ultraThinMaterial, in: Capsule())
//                        }
//                        .padding(.trailing, 16)
//                    }
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
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            phase = .playing
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 0.92))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8)),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.85))
                        .combined(with: .offset(y: -30))
                        .animation(.easeIn(duration: 0.35))
                ))
                .zIndex(2)
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
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            phase = .intro
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 0.9))
                        .combined(with: .offset(y: 40))
                        .animation(.spring(response: 0.55, dampingFraction: 0.78)),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.92))
                        .animation(.easeIn(duration: 0.3))
                ))
                .zIndex(3)
            }
        }
        .onChange(of: phase) { _, newPhase in
            // Update scene blur based on phase (blur when cards overlay)
            switch newPhase {
            case .intro:
                sceneBlur = 3
                AudioManager.shared.stopAmbient()
            case .playing:
                sceneBlur = 0
                AudioManager.shared.playAmbient("kitchen-ambient")
            case .scoreReveal:
                sceneBlur = 4
                AudioManager.shared.playSFX("star-reveal")
            }
        }
        .onAppear {
            // Start with blur since intro card is showing
            sceneBlur = 3
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
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
