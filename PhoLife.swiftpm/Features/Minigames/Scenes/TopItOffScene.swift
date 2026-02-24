import SpriteKit

class TopItOffScene: SKScene {

    // MARK: - Card Data Model

    struct CardData {
        let pairID: Int      // 0-5, each pair shares an ID
        let isTopping: Bool  // true = shows topping name, false = shows role text
        let text: String     // display text
    }

    // MARK: - Pair Definitions

    private static let pairs: [(topping: String, role: String)] = [
        ("🥬 Bean Sprouts", "Crunch & Freshness"),
        ("🌿 Thai Basil",   "Aromatic Sweetness"),
        ("🌱 Cilantro",     "Bright Herbiness"),
        ("🍋 Lime",         "Acidity & Brightness"),
        ("🫙 Hoisin",       "Rich Sweetness"),
        ("🌶️ Sriracha",     "Heat & Kick")
    ]

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game State

    private var totalFlips: Int = 0
    private var matchedPairs: Int = 0
    private var flippedCards: [SKNode] = []
    private var isCheckingMatch: Bool = false

    // MARK: - Layout Constants

    private let cardWidth: CGFloat = 120
    private let cardHeight: CGFloat = 160
    private let cardSpacing: CGFloat = 16
    private let columns: Int = 4
    private let rows: Int = 3
    private let cardCornerRadius: CGFloat = 14

    // MARK: - Colors

    private let cardBackColor = SKColor(red: 0.36, green: 0.20, blue: 0.09, alpha: 1.0)    // #5C3317
    private let cardFrontColor = SKColor(red: 0.96, green: 0.91, blue: 0.80, alpha: 1.0)    // warm cream
    private let toppingTextColor = SKColor(red: 0.30, green: 0.15, blue: 0.05, alpha: 1.0)
    private let roleTextColor = SKColor(red: 0.50, green: 0.30, blue: 0.12, alpha: 1.0)
    private let matchGlowColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)      // gold

    // MARK: - HUD

    private var flipsLabel: SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.18, green: 0.12, blue: 0.07, alpha: 1.0)

        setupHUD()
        setupCards()
    }

    // MARK: - HUD Setup

    private func setupHUD() {
        // Title
        let title = SKLabelNode(fontNamed: "SFProRounded-Bold")
        title.text = "Top It Off"
        title.fontSize = 32
        title.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height - 60)
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        addChild(title)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "SFProRounded-Regular")
        subtitle.text = "Match each topping to its role"
        subtitle.fontSize = 18
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.5)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height - 90)
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode = .center
        addChild(subtitle)

        // Flips counter
        flipsLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        flipsLabel.text = "Flips: 0"
        flipsLabel.fontSize = 20
        flipsLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        flipsLabel.position = CGPoint(x: size.width / 2, y: 50)
        flipsLabel.horizontalAlignmentMode = .center
        flipsLabel.verticalAlignmentMode = .center
        addChild(flipsLabel)
    }

    // MARK: - Card Setup

    private func setupCards() {
        // Build the 12 CardData entries (6 topping cards + 6 role cards)
        var allCards: [CardData] = []
        for (index, pair) in TopItOffScene.pairs.enumerated() {
            allCards.append(CardData(pairID: index, isTopping: true, text: pair.topping))
            allCards.append(CardData(pairID: index, isTopping: false, text: pair.role))
        }

        // Shuffle
        allCards.shuffle()

        // Calculate the grid origin so it is centered
        let totalGridWidth = CGFloat(columns) * cardWidth + CGFloat(columns - 1) * cardSpacing
        let totalGridHeight = CGFloat(rows) * cardHeight + CGFloat(rows - 1) * cardSpacing
        let originX = (size.width - totalGridWidth) / 2 + cardWidth / 2
        let originY = (size.height - totalGridHeight) / 2 + cardHeight / 2 + 10 // slight upward nudge for HUD space

        for (index, cardData) in allCards.enumerated() {
            let col = index % columns
            let row = index / columns

            let x = originX + CGFloat(col) * (cardWidth + cardSpacing)
            // Flip row order so top-left is index 0
            let y = originY + CGFloat(rows - 1 - row) * (cardHeight + cardSpacing)

            let cardNode = createCardNode(index: index, data: cardData)
            cardNode.position = CGPoint(x: x, y: y)
            addChild(cardNode)

            // Entrance animation: cards scale in with a stagger
            cardNode.setScale(0)
            let delay = Double(index) * 0.05
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
            scaleUp.timingMode = .easeOut
            cardNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                scaleUp
            ]))
        }
    }

    private func createCardNode(index: Int, data: CardData) -> SKNode {
        let container = SKNode()
        container.name = "card_\(index)"
        container.userData = NSMutableDictionary()
        container.userData?["pairID"] = data.pairID
        container.userData?["isTopping"] = data.isTopping
        container.userData?["text"] = data.text
        container.userData?["isFlipped"] = false
        container.userData?["isMatched"] = false

        // --- Back face ---
        let backFace = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: cardCornerRadius)
        backFace.fillColor = cardBackColor
        backFace.strokeColor = SKColor(red: 0.45, green: 0.28, blue: 0.14, alpha: 1.0)
        backFace.lineWidth = 2
        backFace.name = "backFace"

        // Decorative pattern on the back: a small star/diamond cluster
        let decorSize: CGFloat = 10
        let decorSpacing: CGFloat = 20
        for row in -1...1 {
            for col in -1...1 {
                let diamond = SKShapeNode(rectOf: CGSize(width: decorSize, height: decorSize), cornerRadius: 3)
                diamond.fillColor = SKColor(red: 0.42, green: 0.25, blue: 0.12, alpha: 0.6)
                diamond.strokeColor = .clear
                diamond.position = CGPoint(x: CGFloat(col) * decorSpacing, y: CGFloat(row) * decorSpacing)
                diamond.zRotation = .pi / 4
                backFace.addChild(diamond)
            }
        }

        // Small bowl icon on back
        let bowlIcon = SKLabelNode(text: "🍜")
        bowlIcon.fontSize = 26
        bowlIcon.verticalAlignmentMode = .center
        bowlIcon.horizontalAlignmentMode = .center
        bowlIcon.position = CGPoint(x: 0, y: 0)
        bowlIcon.alpha = 0.3
        backFace.addChild(bowlIcon)

        container.addChild(backFace)

        // --- Front face ---
        let frontFace = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: cardCornerRadius)
        frontFace.fillColor = cardFrontColor
        frontFace.strokeColor = SKColor(red: 0.80, green: 0.70, blue: 0.50, alpha: 1.0)
        frontFace.lineWidth = 2
        frontFace.name = "frontFace"
        frontFace.isHidden = true

        // Inner border accent
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 12, height: cardHeight - 12), cornerRadius: cardCornerRadius - 3)
        innerBorder.fillColor = .clear
        innerBorder.strokeColor = SKColor(red: 0.80, green: 0.65, blue: 0.40, alpha: 0.4)
        innerBorder.lineWidth = 1
        frontFace.addChild(innerBorder)

        if data.isTopping {
            // Topping card: show emoji + name
            // Split the emoji prefix from the name for layout
            let parts = data.text.split(separator: " ", maxSplits: 1)
            let emoji = parts.count > 1 ? String(parts[0]) : ""
            let name = parts.count > 1 ? String(parts[1]) : data.text

            let emojiLabel = SKLabelNode(text: emoji)
            emojiLabel.fontSize = 36
            emojiLabel.verticalAlignmentMode = .center
            emojiLabel.horizontalAlignmentMode = .center
            emojiLabel.position = CGPoint(x: 0, y: 20)
            frontFace.addChild(emojiLabel)

            let nameLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
            nameLabel.text = name
            nameLabel.fontSize = 15
            nameLabel.fontColor = toppingTextColor
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            nameLabel.position = CGPoint(x: 0, y: -20)
            frontFace.addChild(nameLabel)

            // Small label at top
            let typeLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            typeLabel.text = "TOPPING"
            typeLabel.fontSize = 9
            typeLabel.fontColor = SKColor(red: 0.65, green: 0.50, blue: 0.30, alpha: 0.7)
            typeLabel.verticalAlignmentMode = .center
            typeLabel.horizontalAlignmentMode = .center
            typeLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 16)
            frontFace.addChild(typeLabel)
        } else {
            // Role card: show text in italic style
            let roleLabel = SKLabelNode(fontNamed: "SFProRounded-RegularItalic")
            roleLabel.text = "\"\(data.text)\""
            roleLabel.fontSize = 14
            roleLabel.fontColor = roleTextColor
            roleLabel.verticalAlignmentMode = .center
            roleLabel.horizontalAlignmentMode = .center
            roleLabel.position = CGPoint(x: 0, y: -8)
            roleLabel.numberOfLines = 2
            roleLabel.preferredMaxLayoutWidth = cardWidth - 20
            frontFace.addChild(roleLabel)

            // A small utensil icon
            let icon = SKLabelNode(text: "✨")
            icon.fontSize = 28
            icon.verticalAlignmentMode = .center
            icon.horizontalAlignmentMode = .center
            icon.position = CGPoint(x: 0, y: 28)
            frontFace.addChild(icon)

            // Small label at top
            let typeLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            typeLabel.text = "ROLE"
            typeLabel.fontSize = 9
            typeLabel.fontColor = SKColor(red: 0.65, green: 0.50, blue: 0.30, alpha: 0.7)
            typeLabel.verticalAlignmentMode = .center
            typeLabel.horizontalAlignmentMode = .center
            typeLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 16)
            frontFace.addChild(typeLabel)
        }

        container.addChild(frontFace)

        return container
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCheckingMatch else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Find the card container node
        var cardNode: SKNode?
        for node in tappedNodes {
            // Walk up to find a card container
            var current: SKNode? = node
            while let c = current {
                if let name = c.name, name.hasPrefix("card_") {
                    cardNode = c
                    break
                }
                current = c.parent
            }
            if cardNode != nil { break }
        }

        guard let card = cardNode else { return }

        // Check if already flipped or matched
        let isFlipped = card.userData?["isFlipped"] as? Bool ?? false
        let isMatched = card.userData?["isMatched"] as? Bool ?? false
        guard !isFlipped && !isMatched else { return }

        // Flip the card
        totalFlips += 1
        flipsLabel.text = "Flips: \(totalFlips)"
        AudioManager.shared.playSFX("card-flip")
        flipCardFaceUp(card)

        flippedCards.append(card)

        if flippedCards.count == 2 {
            checkForMatch()
        }
    }

    // MARK: - Flip Animations

    private func flipCardFaceUp(_ card: SKNode) {
        card.userData?["isFlipped"] = true

        guard let backFace = card.childNode(withName: "backFace"),
              let frontFace = card.childNode(withName: "frontFace") else { return }

        // Satisfying tap feedback: small bounce
        let pressDown = SKAction.scale(to: 0.92, duration: 0.06)
        pressDown.timingMode = .easeIn
        let pressUp = SKAction.scale(to: 1.04, duration: 0.08)
        pressUp.timingMode = .easeOut
        let settleBack = SKAction.scale(to: 1.0, duration: 0.06)

        // Flip animation on X axis
        let flipFirstHalf = SKAction.scaleX(to: 0, duration: 0.15)
        flipFirstHalf.timingMode = .easeIn
        let swapFaces = SKAction.run {
            backFace.isHidden = true
            frontFace.isHidden = false
        }
        let flipSecondHalf = SKAction.scaleX(to: 1.0, duration: 0.15)
        flipSecondHalf.timingMode = .easeOut

        let flipSequence = SKAction.sequence([
            pressDown,
            pressUp,
            flipFirstHalf,
            swapFaces,
            flipSecondHalf,
            settleBack
        ])

        card.run(flipSequence)
    }

    private func flipCardFaceDown(_ card: SKNode) {
        card.userData?["isFlipped"] = false

        guard let backFace = card.childNode(withName: "backFace"),
              let frontFace = card.childNode(withName: "frontFace") else { return }

        // Sad wiggle before flipping back
        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.04, duration: 0.05),
            SKAction.rotate(byAngle: -0.08, duration: 0.1),
            SKAction.rotate(byAngle: 0.04, duration: 0.05)
        ])

        let flipFirstHalf = SKAction.scaleX(to: 0, duration: 0.15)
        flipFirstHalf.timingMode = .easeIn
        let swapFaces = SKAction.run {
            frontFace.isHidden = true
            backFace.isHidden = false
        }
        let flipSecondHalf = SKAction.scaleX(to: 1.0, duration: 0.15)
        flipSecondHalf.timingMode = .easeOut

        card.run(SKAction.sequence([
            wiggle,
            flipFirstHalf,
            swapFaces,
            flipSecondHalf
        ]))
    }

    // MARK: - Match Logic

    private func checkForMatch() {
        guard flippedCards.count == 2 else { return }

        isCheckingMatch = true

        let card1 = flippedCards[0]
        let card2 = flippedCards[1]

        let pairID1 = card1.userData?["pairID"] as? Int ?? -1
        let pairID2 = card2.userData?["pairID"] as? Int ?? -1
        let isTopping1 = card1.userData?["isTopping"] as? Bool ?? true
        let isTopping2 = card2.userData?["isTopping"] as? Bool ?? true

        // A match requires same pairID but different card types (one topping, one role)
        if pairID1 == pairID2 && isTopping1 != isTopping2 {
            // Match found
            card1.userData?["isMatched"] = true
            card2.userData?["isMatched"] = true
            matchedPairs += 1

            // Delay briefly to let the flip animation finish, then play match effects
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.35),
                SKAction.run { [weak self] in
                    AudioManager.shared.playSFX("success-chime")
                    self?.playMatchEffect(card1)
                    self?.playMatchEffect(card2)
                },
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.flippedCards.removeAll()
                    self?.isCheckingMatch = false
                    self?.checkGameComplete()
                }
            ]))
        } else {
            // No match — flip both back after a brief pause so the player can see them
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    AudioManager.shared.playSFX("error-buzz")
                    self?.flipCardFaceDown(card1)
                    self?.flipCardFaceDown(card2)
                },
                SKAction.wait(forDuration: 0.35),
                SKAction.run { [weak self] in
                    self?.flippedCards.removeAll()
                    self?.isCheckingMatch = false
                }
            ]))
        }
    }

    // MARK: - Match Effect

    private func playMatchEffect(_ card: SKNode) {
        guard let frontFace = card.childNode(withName: "frontFace") as? SKShapeNode else { return }

        // Golden glow outline behind the card
        let glowShape = SKShapeNode(rectOf: CGSize(width: cardWidth + 8, height: cardHeight + 8), cornerRadius: cardCornerRadius + 2)
        glowShape.fillColor = .clear
        glowShape.strokeColor = matchGlowColor
        glowShape.lineWidth = 4
        glowShape.alpha = 0
        glowShape.name = "matchGlow"
        glowShape.zPosition = -1
        card.addChild(glowShape)

        // Glow animation
        let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.2)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 0.9, duration: 0.6)
        ])
        glowShape.run(SKAction.sequence([
            fadeIn,
            SKAction.repeatForever(pulse)
        ]))

        // Flash the card front gold briefly
        let colorizeToGold = SKAction.customAction(withDuration: 0.15) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let progress = elapsed / 0.15
            shape.fillColor = SKColor(
                red: 0.96 + (1.0 - 0.96) * progress,
                green: 0.91 + (0.84 - 0.91) * progress,
                blue: 0.80 + (0.0 - 0.80) * progress,
                alpha: 1.0
            )
        }
        let colorizeBack = SKAction.customAction(withDuration: 0.3) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let progress = elapsed / 0.3
            shape.fillColor = SKColor(
                red: 1.0 + (0.96 - 1.0) * progress,
                green: 0.84 + (0.91 - 0.84) * progress,
                blue: 0.0 + (0.80 - 0.0) * progress,
                alpha: 1.0
            )
        }
        frontFace.run(SKAction.sequence([colorizeToGold, colorizeBack]))

        // Card celebratory bounce
        let bounceUp = SKAction.scale(to: 1.12, duration: 0.12)
        bounceUp.timingMode = .easeOut
        let bounceDown = SKAction.scale(to: 0.96, duration: 0.08)
        bounceDown.timingMode = .easeIn
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        settle.timingMode = .easeOut
        card.run(SKAction.sequence([bounceUp, bounceDown, settle]))

        // Sparkle particles around the card
        spawnSparkles(at: card.position)
    }

    private func spawnSparkles(at position: CGPoint) {
        let sparkleTexts = ["✦", "✧", "⭐"]
        for _ in 0..<6 {
            let sparkle = SKLabelNode(text: sparkleTexts.randomElement()!)
            sparkle.fontSize = CGFloat.random(in: 10...18)
            sparkle.alpha = 0
            sparkle.position = position
            sparkle.zPosition = 10
            addChild(sparkle)

            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let randomDist = CGFloat.random(in: 40...90)
            let dx = cos(randomAngle) * randomDist
            let dy = sin(randomAngle) * randomDist

            let sparkleAnim = SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.15),
                SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.5),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.fadeAlpha(to: 0, duration: 0.25)
                ]),
                SKAction.scale(to: 0.3, duration: 0.5)
            ])

            sparkle.run(SKAction.sequence([
                sparkleAnim,
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Game Completion

    private func checkGameComplete() {
        guard matchedPairs >= 6 else { return }

        // Determine stars and score
        let stars: Int
        if totalFlips <= 12 {
            stars = 3
        } else if totalFlips <= 18 {
            stars = 2
        } else {
            stars = 1
        }

        let score = max(0, 100 - (totalFlips - 12) * 5)

        // Celebratory delay before reporting completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                self?.playCompletionCelebration()
            },
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                self?.onComplete?(score, stars)
            }
        ]))
    }

    private func playCompletionCelebration() {
        // Flash all matched cards with a wave
        let allCards = children.filter { $0.name?.hasPrefix("card_") == true }
        for (i, card) in allCards.enumerated() {
            let delay = Double(i) * 0.06
            let bounce = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.scale(to: 1.1, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15)
            ])
            card.run(bounce)
        }

        // "Well Done!" label
        let doneLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        doneLabel.text = "Well Done!"
        doneLabel.fontSize = 48
        doneLabel.fontColor = matchGlowColor
        doneLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        doneLabel.horizontalAlignmentMode = .center
        doneLabel.verticalAlignmentMode = .center
        doneLabel.alpha = 0
        doneLabel.setScale(0.5)
        doneLabel.zPosition = 100
        addChild(doneLabel)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.scale(to: 1.2, duration: 0.3)
        ])
        appear.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        let hold = SKAction.wait(forDuration: 0.6)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.3)

        doneLabel.run(SKAction.sequence([appear, settle, hold, fadeOut, SKAction.removeFromParent()]))
    }
}
