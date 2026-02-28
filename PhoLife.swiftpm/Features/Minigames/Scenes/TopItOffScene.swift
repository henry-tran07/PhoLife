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
        ("\u{1F96C} Bean Sprouts", "Crunch & Freshness"),
        ("\u{1F33F} Thai Basil",   "Aromatic Sweetness"),
        ("\u{1F331} Cilantro",     "Bright Herbiness"),
        ("\u{1F34B} Lime",         "Acidity & Brightness"),
        ("\u{1FAD9} Hoisin",       "Rich Sweetness"),
        ("\u{1F336}\u{FE0F} Sriracha",     "Heat & Kick")
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

    private let cardBackColor = SKColor(red: 0.36, green: 0.20, blue: 0.09, alpha: 1.0)
    private let cardFrontColor = SKColor(red: 0.96, green: 0.91, blue: 0.80, alpha: 1.0)
    private let toppingTextColor = SKColor(red: 0.30, green: 0.15, blue: 0.05, alpha: 1.0)
    private let roleTextColor = SKColor(red: 0.50, green: 0.30, blue: 0.12, alpha: 1.0)
    private let matchGlowColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)

    // MARK: - HUD

    private var flipsLabel: SKLabelNode!
    private var matchLabel: SKLabelNode!
    private var collectBowlNode: SKShapeNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.07, blue: 0.03, alpha: 1.0)

        setupBackground()
        setupHUD()
        setupCards()
        setupCollectBowl()
        setupAmbientParticles()
        addVignette()
        addAmbientParticles(color: SKColor(red: 0.60, green: 0.80, blue: 0.50, alpha: 1), birthRate: 1.5)

        // Scene entrance curtain
        let curtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        curtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        curtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 1.0)
        curtain.strokeColor = .clear
        curtain.zPosition = 500
        addChild(curtain)
        curtain.run(.sequence([.wait(forDuration: 0.2), .fadeAlpha(to: 0, duration: 0.6), .removeFromParent()]))
    }

    // MARK: - Background

    private func setupBackground() {
        // Warm gradient base
        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height * 0.5))
        bottomGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottomGlow.fillColor = SKColor(red: 0.16, green: 0.10, blue: 0.05, alpha: 0.6)
        bottomGlow.strokeColor = .clear
        bottomGlow.zPosition = -10
        addChild(bottomGlow)

        // Warm overhead glow
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.12))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.06)
        topGlow.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 0.10)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        addChild(topGlow)

        // Subtle center spotlight for the card grid
        let spotlight = SKShapeNode(circleOfRadius: size.width * 0.35)
        spotlight.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        spotlight.fillColor = SKColor(red: 0.22, green: 0.15, blue: 0.07, alpha: 0.15)
        spotlight.strokeColor = .clear
        spotlight.zPosition = -9
        addChild(spotlight)
    }

    // MARK: - Ambient Particles

    private func setupAmbientParticles() {
        // Subtle floating herb aroma wisps
        for i in 0..<4 {
            let wisp = SKShapeNode(circleOfRadius: CGFloat.random(in: 6...14))
            wisp.fillColor = SKColor(red: 0.60, green: 0.80, blue: 0.50, alpha: 0.03)
            wisp.strokeColor = .clear
            wisp.position = CGPoint(
                x: CGFloat.random(in: size.width * 0.15...size.width * 0.85),
                y: CGFloat.random(in: size.height * 0.3...size.height * 0.7)
            )
            wisp.zPosition = -3
            addChild(wisp)

            let driftDuration = 3.0 + Double(i) * 0.5
            let drift = SKAction.repeatForever(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 20...50), duration: driftDuration),
                    .fadeAlpha(to: 0.0, duration: driftDuration),
                    .scale(to: 1.8, duration: driftDuration)
                ]),
                .run { [weak self] in
                    guard let self = self else { return }
                    wisp.position = CGPoint(
                        x: CGFloat.random(in: self.size.width * 0.15...self.size.width * 0.85),
                        y: CGFloat.random(in: self.size.height * 0.25...self.size.height * 0.55)
                    )
                    wisp.alpha = CGFloat.random(in: 0.02...0.04)
                    wisp.setScale(1.0)
                }
            ]))
            wisp.run(.sequence([.wait(forDuration: Double(i) * 0.8), drift]))
        }
    }

    // MARK: - HUD Setup

    private func setupHUD() {
        // Title
        let title = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        title.text = "Top It Off"
        title.fontSize = 34
        title.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height - 100)
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.zPosition = 100
        addChild(title)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "SFProRounded-Medium")
        subtitle.text = "Match each topping to its role"
        subtitle.fontSize = 18
        subtitle.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 0.45)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height - 130)
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode = .center
        subtitle.zPosition = 100
        addChild(subtitle)

        subtitle.run(.sequence([
            .wait(forDuration: 4.0),
            .fadeOut(withDuration: 1.0),
            .removeFromParent()
        ]))

        // HUD background pill for counters
        let hudPillWidth: CGFloat = 260
        let hudPill = SKShapeNode(rectOf: CGSize(width: hudPillWidth, height: 36), cornerRadius: 18)
        hudPill.position = CGPoint(x: size.width / 2, y: 50)
        hudPill.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 0.7)
        hudPill.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.4)
        hudPill.lineWidth = 1
        hudPill.zPosition = 99
        addChild(hudPill)

        // Flips counter
        flipsLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        flipsLabel.text = "Flips: 0"
        flipsLabel.fontSize = 20
        flipsLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 0.7)
        flipsLabel.position = CGPoint(x: size.width / 2 - 70, y: 50)
        flipsLabel.horizontalAlignmentMode = .center
        flipsLabel.verticalAlignmentMode = .center
        flipsLabel.zPosition = 100
        addChild(flipsLabel)

        // Match counter
        matchLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        matchLabel.text = "Matches: 0/6"
        matchLabel.fontSize = 20
        matchLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1.0)
        matchLabel.position = CGPoint(x: size.width / 2 + 70, y: 50)
        matchLabel.horizontalAlignmentMode = .center
        matchLabel.verticalAlignmentMode = .center
        matchLabel.zPosition = 100
        addChild(matchLabel)
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
        let originY = (size.height - totalGridHeight) / 2 + cardHeight / 2 + 10

        for (index, cardData) in allCards.enumerated() {
            let col = index % columns
            let row = index / columns

            let x = originX + CGFloat(col) * (cardWidth + cardSpacing)
            let y = originY + CGFloat(rows - 1 - row) * (cardHeight + cardSpacing)

            let cardNode = createCardNode(index: index, data: cardData)
            cardNode.position = CGPoint(x: x, y: y)
            addChild(cardNode)

            // Entrance animation: cards scale in with a stagger
            cardNode.setScale(0)
            cardNode.alpha = 0
            let delay = Double(index) * 0.05
            let scaleUp = SKAction.group([
                .scale(to: 1.0, duration: 0.35),
                .fadeAlpha(to: 1.0, duration: 0.3)
            ])
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

        // Card shadow
        let cardShadow = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: cardCornerRadius)
        cardShadow.fillColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.30)
        cardShadow.strokeColor = .clear
        cardShadow.position = CGPoint(x: 3, y: -3)
        cardShadow.zPosition = -0.5
        cardShadow.name = "cardShadow"
        container.addChild(cardShadow)

        // --- Back face ---
        let backFace = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: cardCornerRadius)
        backFace.fillColor = cardBackColor
        backFace.strokeColor = SKColor(red: 0.48, green: 0.30, blue: 0.16, alpha: 1.0)
        backFace.lineWidth = 2
        backFace.name = "backFace"

        // Decorative pattern on the back: a small star/diamond cluster
        let decorSize: CGFloat = 10
        let decorSpacing: CGFloat = 20
        for row in -1...1 {
            for col in -1...1 {
                let diamond = SKShapeNode(rectOf: CGSize(width: decorSize, height: decorSize), cornerRadius: 3)
                diamond.fillColor = SKColor(red: 0.44, green: 0.27, blue: 0.14, alpha: 0.5)
                diamond.strokeColor = .clear
                diamond.position = CGPoint(x: CGFloat(col) * decorSpacing, y: CGFloat(row) * decorSpacing)
                diamond.zRotation = .pi / 4
                backFace.addChild(diamond)
            }
        }

        // Small bowl icon on back
        let bowlIcon = SKLabelNode(text: "\u{1F35C}")
        bowlIcon.fontSize = 26
        bowlIcon.verticalAlignmentMode = .center
        bowlIcon.horizontalAlignmentMode = .center
        bowlIcon.position = CGPoint(x: 0, y: 0)
        bowlIcon.alpha = 0.25
        backFace.addChild(bowlIcon)

        // Subtle highlight on back top edge
        let backHighlight = SKShapeNode(rectOf: CGSize(width: cardWidth - 12, height: 4), cornerRadius: 2)
        backHighlight.fillColor = SKColor(white: 1.0, alpha: 0.08)
        backHighlight.strokeColor = .clear
        backHighlight.position = CGPoint(x: 0, y: cardHeight / 2 - 10)
        backFace.addChild(backHighlight)

        container.addChild(backFace)

        // --- Front face ---
        let frontFace = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: cardCornerRadius)
        frontFace.fillColor = cardFrontColor
        frontFace.strokeColor = SKColor(red: 0.82, green: 0.72, blue: 0.52, alpha: 1.0)
        frontFace.lineWidth = 2
        frontFace.name = "frontFace"
        frontFace.isHidden = true

        // Inner border accent
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 12, height: cardHeight - 12), cornerRadius: cardCornerRadius - 3)
        innerBorder.fillColor = .clear
        innerBorder.strokeColor = SKColor(red: 0.80, green: 0.65, blue: 0.40, alpha: 0.35)
        innerBorder.lineWidth = 1
        frontFace.addChild(innerBorder)

        if data.isTopping {
            let parts = data.text.split(separator: " ", maxSplits: 1)
            let emoji = parts.count > 1 ? String(parts[0]) : ""
            let name = parts.count > 1 ? String(parts[1]) : data.text

            let emojiLabel = SKLabelNode(text: emoji)
            emojiLabel.fontSize = 38
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
            nameLabel.position = CGPoint(x: 0, y: -22)
            frontFace.addChild(nameLabel)

            let typeLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            typeLabel.text = "TOPPING"
            typeLabel.fontSize = 9
            typeLabel.fontColor = SKColor(red: 0.65, green: 0.50, blue: 0.30, alpha: 0.6)
            typeLabel.verticalAlignmentMode = .center
            typeLabel.horizontalAlignmentMode = .center
            typeLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 16)
            frontFace.addChild(typeLabel)
        } else {
            let roleLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            roleLabel.text = "\"\(data.text)\""
            roleLabel.fontSize = 14
            roleLabel.fontColor = roleTextColor
            roleLabel.verticalAlignmentMode = .center
            roleLabel.horizontalAlignmentMode = .center
            roleLabel.position = CGPoint(x: 0, y: -8)
            roleLabel.numberOfLines = 2
            roleLabel.preferredMaxLayoutWidth = cardWidth - 20
            frontFace.addChild(roleLabel)

            let icon = SKLabelNode(text: "\u{2728}")
            icon.fontSize = 28
            icon.verticalAlignmentMode = .center
            icon.horizontalAlignmentMode = .center
            icon.position = CGPoint(x: 0, y: 28)
            frontFace.addChild(icon)

            let typeLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            typeLabel.text = "ROLE"
            typeLabel.fontSize = 9
            typeLabel.fontColor = SKColor(red: 0.65, green: 0.50, blue: 0.30, alpha: 0.6)
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
        HapticManager.shared.light()

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

        // Brief red flash on the front before flipping back
        if let front = frontFace as? SKShapeNode {
            let originalColor = front.fillColor
            front.run(.sequence([
                .customAction(withDuration: 0.1) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let t = elapsed / 0.1
                    shape.fillColor = SKColor(
                        red: 0.96 + (1.0 - 0.96) * t,
                        green: 0.91 - 0.25 * t,
                        blue: 0.80 - 0.40 * t,
                        alpha: 1.0
                    )
                },
                .customAction(withDuration: 0.15) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let t = elapsed / 0.15
                    shape.fillColor = SKColor(
                        red: 1.0 + (0.96 - 1.0) * t,
                        green: 0.66 + (0.91 - 0.66) * t,
                        blue: 0.40 + (0.80 - 0.40) * t,
                        alpha: 1.0
                    )
                },
                .run { front.fillColor = originalColor }
            ]))
        }

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
            matchLabel.text = "Matches: \(matchedPairs)/6"

            // Pulse the match label
            matchLabel.run(.sequence([
                .scale(to: 1.15, duration: 0.08),
                .scale(to: 1.0, duration: 0.1)
            ]))

            HapticManager.shared.medium()

            // Match visual effects
            let midpoint = CGPoint(
                x: (card1.position.x + card2.position.x) / 2,
                y: (card1.position.y + card2.position.y) / 2
            )
            expandingRing(at: midpoint, color: matchGlowColor)
            floatingScoreText("Matched!", at: midpoint)

            let capturedPairID = pairID1
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.35),
                SKAction.run { [weak self] in
                    AudioManager.shared.playSFX("success-chime")
                    self?.playMatchEffect(card1)
                    self?.playMatchEffect(card2)
                    self?.floatCardsToBowl(card1, card2, pairIndex: capturedPairID)
                },
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.flippedCards.removeAll()
                    self?.isCheckingMatch = false
                    self?.checkGameComplete()
                }
            ]))
        } else {
            // No match
            shakeCamera(intensity: 5)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    HapticManager.shared.light()
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
        let glowShape = SKShapeNode(rectOf: CGSize(width: cardWidth + 10, height: cardHeight + 10), cornerRadius: cardCornerRadius + 3)
        glowShape.fillColor = .clear
        glowShape.strokeColor = matchGlowColor
        glowShape.lineWidth = 4
        glowShape.glowWidth = 4
        glowShape.alpha = 0
        glowShape.name = "matchGlow"
        glowShape.zPosition = -1
        card.addChild(glowShape)

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
        // Mix of golden shape sparkles and warm dots
        for _ in 0..<8 {
            let isGoldenDot = Bool.random()
            if isGoldenDot {
                let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
                sparkle.fillColor = SKColor(
                    red: CGFloat.random(in: 0.90...1.0),
                    green: CGFloat.random(in: 0.75...0.90),
                    blue: CGFloat.random(in: 0.10...0.35),
                    alpha: 1.0
                )
                sparkle.strokeColor = .clear
                sparkle.glowWidth = 2
                sparkle.alpha = 0
                sparkle.position = position
                sparkle.zPosition = 10
                addChild(sparkle)

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 40...100)
                let dx = cos(angle) * dist
                let dy = sin(angle) * dist

                sparkle.run(.sequence([
                    .group([
                        .fadeAlpha(to: 1.0, duration: 0.1),
                        .moveBy(x: dx, y: dy, duration: 0.5),
                        .sequence([
                            .wait(forDuration: 0.25),
                            .fadeOut(withDuration: 0.25)
                        ]),
                        .scale(to: 0.2, duration: 0.5)
                    ]),
                    .removeFromParent()
                ]))
            } else {
                let sparkleTexts = ["\u{2726}", "\u{2727}", "\u{2B50}"]
                let sparkle = SKLabelNode(text: sparkleTexts.randomElement()!)
                sparkle.fontSize = CGFloat.random(in: 10...18)
                sparkle.alpha = 0
                sparkle.position = position
                sparkle.zPosition = 10
                addChild(sparkle)

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 40...90)
                let dx = cos(angle) * dist
                let dy = sin(angle) * dist

                sparkle.run(.sequence([
                    .group([
                        .fadeAlpha(to: 1.0, duration: 0.15),
                        .moveBy(x: dx, y: dy, duration: 0.5),
                        .sequence([
                            .wait(forDuration: 0.25),
                            .fadeOut(withDuration: 0.25)
                        ]),
                        .scale(to: 0.3, duration: 0.5)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }

    // MARK: - Game Completion

    private func checkGameComplete() {
        guard matchedPairs >= 6 else { return }

        // Determine stars and score
        let stars: Int
        if totalFlips < 30 {
            stars = 3
        } else if totalFlips < 40 {
            stars = 2
        } else {
            stars = 1
        }

        let score = max(10, 100 - max(0, totalFlips - 12) * 2)

        // Celebratory delay before reporting completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                HapticManager.shared.success()
                self?.playCompletionCelebration()
            },
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let exitCurtain = SKShapeNode(rectOf: CGSize(width: self.size.width + 20, height: self.size.height + 20))
                exitCurtain.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
                exitCurtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0)
                exitCurtain.strokeColor = .clear
                exitCurtain.zPosition = 500
                self.addChild(exitCurtain)
                exitCurtain.run(.sequence([
                    .fadeAlpha(to: 1.0, duration: 0.4),
                    .run { [weak self] in self?.onComplete?(score, stars) }
                ]))
            }
        ]))
    }

    private func playCompletionCelebration() {
        // Golden burst from center
        let burst = SKShapeNode(circleOfRadius: 10)
        burst.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.40, alpha: 0.25)
        burst.strokeColor = .clear
        burst.position = CGPoint(x: size.width / 2, y: size.height / 2)
        burst.zPosition = 90
        addChild(burst)
        burst.run(.sequence([
            .scale(to: 25, duration: 0.5),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))

        // Celebration sparkles
        for _ in 0..<20 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            sparkle.fillColor = SKColor(
                red: CGFloat.random(in: 0.88...1.0),
                green: CGFloat.random(in: 0.70...0.92),
                blue: CGFloat.random(in: 0.10...0.45),
                alpha: 1.0
            )
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 2
            sparkle.position = CGPoint(x: size.width / 2, y: size.height / 2)
            sparkle.zPosition = 92
            addChild(sparkle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 80...200)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.8),
                    .fadeOut(withDuration: 0.8),
                    .scale(to: 0.1, duration: 0.8)
                ]),
                .removeFromParent()
            ]))
        }

        // Flash remaining cards with a wave
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
        let doneLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        doneLabel.text = "Well Done!"
        doneLabel.fontSize = 48
        doneLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0)
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

        // Bowl warm glow pulse
        if let bowl = collectBowlNode {
            let bowlGlow = SKShapeNode(ellipseOf: CGSize(width: 160, height: 100))
            bowlGlow.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.40, alpha: 0.15)
            bowlGlow.strokeColor = .clear
            bowlGlow.position = bowl.position
            bowlGlow.zPosition = 1
            addChild(bowlGlow)
            bowlGlow.run(.sequence([
                .scale(to: 1.5, duration: 0.5),
                .fadeOut(withDuration: 0.5),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Collect Bowl

    private func setupCollectBowl() {
        let bowlX = size.width - 130
        let bowlY: CGFloat = 100

        // Bowl shadow
        let bowlShadow = SKShapeNode(ellipseOf: CGSize(width: 130, height: 45))
        bowlShadow.fillColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.30)
        bowlShadow.strokeColor = .clear
        bowlShadow.position = CGPoint(x: bowlX + 3, y: bowlY - 25)
        bowlShadow.zPosition = 1
        addChild(bowlShadow)

        // Bowl body
        collectBowlNode = SKShapeNode(ellipseOf: CGSize(width: 120, height: 70))
        collectBowlNode.fillColor = SKColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1)
        collectBowlNode.strokeColor = SKColor(red: 0.78, green: 0.72, blue: 0.62, alpha: 1)
        collectBowlNode.lineWidth = 2
        collectBowlNode.position = CGPoint(x: bowlX, y: bowlY)
        collectBowlNode.zPosition = 2
        addChild(collectBowlNode)

        // Bowl rim
        let rim = SKShapeNode(ellipseOf: CGSize(width: 130, height: 78))
        rim.fillColor = .clear
        rim.strokeColor = SKColor(red: 0.72, green: 0.66, blue: 0.58, alpha: 1)
        rim.lineWidth = 2
        rim.position = CGPoint(x: bowlX, y: bowlY + 5)
        rim.zPosition = 3
        addChild(rim)

        // Rim highlight
        let rimHighlightPath = CGMutablePath()
        rimHighlightPath.addArc(center: .zero, radius: 63,
                                startAngle: .pi * 0.2, endAngle: .pi * 0.8, clockwise: false)
        let rimHighlight = SKShapeNode(path: rimHighlightPath)
        rimHighlight.strokeColor = SKColor(white: 1.0, alpha: 0.20)
        rimHighlight.lineWidth = 2
        rimHighlight.fillColor = .clear
        rimHighlight.lineCap = .round
        rimHighlight.position = CGPoint(x: bowlX, y: bowlY + 5)
        rimHighlight.zPosition = 3.5
        addChild(rimHighlight)

        // "Your Bowl" label
        let bowlLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        bowlLabel.text = "Your Bowl"
        bowlLabel.fontSize = 14
        bowlLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 0.55)
        bowlLabel.position = CGPoint(x: bowlX, y: bowlY - 55)
        bowlLabel.zPosition = 3
        addChild(bowlLabel)
    }

    // MARK: - Float-to-Bowl Animation

    private func floatCardsToBowl(_ card1: SKNode, _ card2: SKNode, pairIndex: Int) {
        let bowlPos = collectBowlNode.position
        let floatDelay = SKAction.wait(forDuration: 0.8)
        let floatToBowl = SKAction.group([
            .move(to: bowlPos, duration: 0.5),
            .scale(to: 0.2, duration: 0.5),
            .fadeAlpha(to: 0.4, duration: 0.5)
        ])
        floatToBowl.timingMode = .easeIn
        let sequence = SKAction.sequence([floatDelay, floatToBowl, .removeFromParent()])

        card1.run(sequence)
        card2.run(sequence)

        // Add a topping indicator in the bowl after cards arrive
        run(.sequence([.wait(forDuration: 1.3), .run { [weak self] in
            self?.addToppingToBowl(pairIndex: pairIndex)
        }]))
    }

    private func addToppingToBowl(pairIndex: Int) {
        let toppingEmojis = ["\u{1F33F}", "\u{1FAD8}", "\u{1F336}\u{FE0F}", "\u{1F34B}", "\u{1F9C5}", "\u{1FAD1}"]
        let emoji = toppingEmojis[safe: pairIndex] ?? "\u{2726}"
        let label = SKLabelNode(text: emoji)
        label.fontSize = 22
        label.position = CGPoint(
            x: collectBowlNode.position.x + CGFloat.random(in: -25...25),
            y: collectBowlNode.position.y + CGFloat.random(in: -10...15)
        )
        label.zPosition = 4
        label.setScale(0.1)
        label.alpha = 0
        addChild(label)

        // Pop in with golden sparkle
        label.run(.sequence([
            .group([
                .scale(to: 1.0, duration: 0.2),
                .fadeAlpha(to: 1.0, duration: 0.15)
            ]),
            .repeatForever(.sequence([
                .scale(to: 1.05, duration: 0.8),
                .scale(to: 0.95, duration: 0.8)
            ]))
        ]))

        // Small golden sparkle at placement
        let sparkle = SKShapeNode(circleOfRadius: 3)
        sparkle.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.40, alpha: 0.8)
        sparkle.strokeColor = .clear
        sparkle.glowWidth = 3
        sparkle.position = label.position
        sparkle.zPosition = 5
        addChild(sparkle)
        sparkle.run(.sequence([
            .group([
                .scale(to: 4, duration: 0.3),
                .fadeOut(withDuration: 0.3)
            ]),
            .removeFromParent()
        ]))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
