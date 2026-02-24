import SpriteKit

class PlaceholderMinigameScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1)

        let gameIndex = (userData?["index"] as? Int ?? 0) + 1

        // Title label
        let titleLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        titleLabel.text = "Minigame \(gameIndex)"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        addChild(titleLabel)

        // Instruction label
        let instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Tap to Complete"
        instructionLabel.fontSize = 22
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        addChild(instructionLabel)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onComplete?(85, 2)
    }
}
