import SwiftUI

@Observable
@MainActor
final class GameState {

    // MARK: - Phase

    enum AppPhase: Int, CaseIterable, Equatable {
        case splash
        case story
        case minigames
        case completion
    }

    // MARK: - Properties

    var currentPhase: AppPhase = .splash
    var currentMinigameIndex: Int = 0
    var minigameResults: [MinigameResult] = []
    var hasSeenStory: Bool = false

    // MARK: - Computed

    var totalStars: Int {
        minigameResults.reduce(0) { $0 + $1.stars }
    }

    var earnedTitle: String {
        switch totalStars {
        case 0...8:
            return "Street Food Curious"
        case 9...16:
            return "Hanoi Home Cook"
        case 17...21:
            return "Saigon Street Vendor"
        case 22...24:
            return "Pho Master"
        default:
            return "Pho Master"
        }
    }

    // MARK: - Methods

    func completeMinigame(result: MinigameResult) {
        minigameResults.append(result)
        if currentMinigameIndex == 7 {
            currentPhase = .completion
        } else {
            currentMinigameIndex += 1
        }
    }

    func resetForReplay() {
        currentMinigameIndex = 0
        minigameResults = []
        hasSeenStory = true
        currentPhase = .minigames
    }

    func skipToMinigames() {
        currentPhase = .minigames
    }
}
