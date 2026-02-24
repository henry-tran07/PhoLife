import Foundation

struct MinigameResult: Identifiable {
    let id = UUID()
    let minigameIndex: Int
    let stars: Int // 1-3
    let score: Int
}
