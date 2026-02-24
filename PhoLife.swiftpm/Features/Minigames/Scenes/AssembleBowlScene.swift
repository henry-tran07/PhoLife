import SpriteKit

class AssembleBowlScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Ingredient Model

    private struct Ingredient {
        let name: String
        let color: SKColor
        let iconBuilder: (CGFloat) -> SKNode  // builds the icon shape given card width
    }

    // MARK: - Correct Order

    /// The four ingredients in the order they must be placed.
    private let correctOrder: [String] = ["Noodles", "Brisket", "Raw Beef", "Broth"]

    /// All ingredient definitions.
    private lazy var ingredients: [Ingredient] = [
        Ingredient(name: "Noodles",
                   color: SKColor(red: 0.96, green: 0.93, blue: 0.82, alpha: 1.0),
                   iconBuilder: { width in Self.buildNoodleIcon(width: width) }),
        Ingredient(name: "Brisket",
                   color: SKColor(red: 0.50, green: 0.30, blue: 0.15, alpha: 1.0),
                   iconBuilder: { width in Self.buildBrisketIcon(width: width) }),
        Ingredient(name: "Raw Beef",
                   color: SKColor(red: 0.90, green: 0.20, blue: 0.18, alpha: 1.0),
                   iconBuilder: { width in Self.buildRawBeefIcon(width: width) }),
        Ingredient(name: "Broth",
                   color: SKColor(red: 0.85, green: 0.68, blue: 0.22, alpha: 1.0),
                   iconBuilder: { width in Self.buildBrothIcon(width: width) }),
    ]

    // MARK: - Game State

    private var currentStep: Int = 0            // 0 = Noodles, 1 = Brisket, 2 = Raw Beef, 3 = Broth
    private var attempts: [Int] = [0, 0, 0, 0]  // attempt count per step
    private var gameActive: Bool = false
    private var gameFinished: Bool = false

    // MARK: - Layout Constants

    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 100
    private let cardSpacing: CGFloat = 24
    private let cardCornerRadius: CGFloat = 16
    private let bowlWidth: CGFloat = 440
    private let bowlHeight: CGFloat = 220

    // MARK: - Nodes

    private var gameLayer: SKNode!
    private var cardNodes: [SKNode] = []
    private var bowlNode: SKShapeNode!
    private var bowlInterior: SKShapeNode!
    private var layerContainer: SKNode!        // holds ingredient layers inside the bowl
    private var stepLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!
    private var rawBeefLayerNode: SKShapeNode?  // reference for color change during broth pour

    // MARK: - Bowl Geometry

    private var bowlCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.28) }
    private var bowlRect: CGRect {
        CGRect(x: bowlCenter.x - bowlWidth / 2,
               y: bowlCenter.y - bowlHeight / 2,
               width: bowlWidth,
               height: bowlHeight)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.28, green: 0.20, blue: 0.13, alpha: 1.0)

        gameLayer = SKNode()
        gameLayer.position = CGPoint(x: 0, y: 0)
        gameLayer.zPosition = 0
        addChild(gameLayer)

        setupBackground()
        setupBowl()
        setupCards()
        setupHUD()

        gameActive = true
        updateHintPulse()
    }

    // MARK: - Background

    private func setupBackground() {
        // Warm kitchen counter surface
        let counter = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height * 0.42))
        counter.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        counter.fillColor = SKColor(red: 0.35, green: 0.24, blue: 0.14, alpha: 1.0)
        counter.strokeColor = SKColor(red: 0.42, green: 0.30, blue: 0.18, alpha: 1.0)
        counter.lineWidth = 2
        counter.zPosition = -10
        gameLayer.addChild(counter)

        // Subtle wood grain lines on counter
        for i in 0..<8 {
            let lineY = size.height * 0.05 + CGFloat(i) * (size.height * 0.04)
            let grainLine = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 1))
            grainLine.position = CGPoint(x: size.width / 2 + CGFloat.random(in: -20...20), y: lineY)
            grainLine.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 0.15)
            grainLine.strokeColor = .clear
            grainLine.zPosition = -9
            gameLayer.addChild(grainLine)
        }

        // Warm ambient glow at top
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.12))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.06)
        topGlow.fillColor = SKColor(red: 0.40, green: 0.28, blue: 0.12, alpha: 0.12)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        gameLayer.addChild(topGlow)
    }

    // MARK: - Bowl Setup

    private func setupBowl() {
        let center = bowlCenter

        // Shadow under the bowl
        let shadowPath = CGPath(
            ellipseIn: CGRect(x: -bowlWidth * 0.55, y: -bowlHeight * 0.35,
                              width: bowlWidth * 1.1, height: bowlHeight * 0.35),
            transform: nil
        )
        let shadow = SKShapeNode(path: shadowPath)
        shadow.fillColor = SKColor(red: 0.10, green: 0.06, blue: 0.02, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: center.x, y: center.y - bowlHeight * 0.32)
        shadow.zPosition = 0
        gameLayer.addChild(shadow)

        // Bowl outer rim — gives a 3D rim effect
        let rimPath = CGPath(
            ellipseIn: CGRect(x: -bowlWidth * 0.54, y: -bowlHeight * 0.54,
                              width: bowlWidth * 1.08, height: bowlHeight * 1.08),
            transform: nil
        )
        let rimNode = SKShapeNode(path: rimPath)
        rimNode.fillColor = SKColor(red: 0.88, green: 0.84, blue: 0.78, alpha: 1.0)
        rimNode.strokeColor = SKColor(red: 0.75, green: 0.70, blue: 0.62, alpha: 1.0)
        rimNode.lineWidth = 3
        rimNode.position = center
        rimNode.zPosition = 1
        gameLayer.addChild(rimNode)

        // Bowl main body — cream/white ceramic
        let bowlPath = CGPath(
            ellipseIn: CGRect(x: -bowlWidth / 2, y: -bowlHeight / 2,
                              width: bowlWidth, height: bowlHeight),
            transform: nil
        )
        bowlNode = SKShapeNode(path: bowlPath)
        bowlNode.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        bowlNode.strokeColor = SKColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1.0)
        bowlNode.lineWidth = 2.5
        bowlNode.position = center
        bowlNode.zPosition = 2
        gameLayer.addChild(bowlNode)

        // Bowl interior — slightly darker for depth
        let interiorInset: CGFloat = 16
        let interiorPath = CGPath(
            ellipseIn: CGRect(x: -(bowlWidth / 2 - interiorInset),
                              y: -(bowlHeight / 2 - interiorInset),
                              width: bowlWidth - interiorInset * 2,
                              height: bowlHeight - interiorInset * 2),
            transform: nil
        )
        bowlInterior = SKShapeNode(path: interiorPath)
        bowlInterior.fillColor = SKColor(red: 0.90, green: 0.87, blue: 0.80, alpha: 1.0)
        bowlInterior.strokeColor = .clear
        bowlInterior.position = center
        bowlInterior.zPosition = 3
        gameLayer.addChild(bowlInterior)

        // Specular highlight on rim (crescent at top-left)
        let highlightPath = CGMutablePath()
        highlightPath.addArc(center: CGPoint(x: -bowlWidth * 0.18, y: bowlHeight * 0.12),
                             radius: bowlWidth * 0.22,
                             startAngle: .pi * 0.1,
                             endAngle: .pi * 0.55,
                             clockwise: false)
        let highlight = SKShapeNode(path: highlightPath)
        highlight.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        highlight.lineWidth = 4
        highlight.fillColor = .clear
        highlight.position = center
        highlight.zPosition = 4
        gameLayer.addChild(highlight)

        // Container for ingredient layers inside the bowl
        layerContainer = SKNode()
        layerContainer.position = center
        layerContainer.zPosition = 5
        gameLayer.addChild(layerContainer)
    }

    // MARK: - Cards Setup

    private func setupCards() {
        let totalWidth = CGFloat(ingredients.count) * cardWidth + CGFloat(ingredients.count - 1) * cardSpacing
        let startX = (size.width - totalWidth) / 2 + cardWidth / 2
        let cardsY = size.height - 180

        for (index, ingredient) in ingredients.enumerated() {
            let x = startX + CGFloat(index) * (cardWidth + cardSpacing)
            let card = createCardNode(ingredient: ingredient, index: index)
            card.position = CGPoint(x: x, y: cardsY)
            card.name = "card_\(index)"
            card.zPosition = 50
            gameLayer.addChild(card)
            cardNodes.append(card)

            // Entrance stagger animation
            card.setScale(0)
            card.alpha = 0
            let delay = Double(index) * 0.1
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.35),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.35)
                ])
            ]))
        }
    }

    private func createCardNode(ingredient: Ingredient, index: Int) -> SKNode {
        let container = SKNode()
        container.userData = NSMutableDictionary()
        container.userData?["ingredientIndex"] = index
        container.userData?["ingredientName"] = ingredient.name

        // Card background
        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight),
                             cornerRadius: cardCornerRadius)
        bg.fillColor = SKColor(red: 0.22, green: 0.15, blue: 0.08, alpha: 0.92)
        bg.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.22, alpha: 0.8)
        bg.lineWidth = 2
        bg.name = "cardBG_\(index)"
        container.addChild(bg)

        // Inner accent border
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 10, height: cardHeight - 10),
                                      cornerRadius: cardCornerRadius - 2)
        innerBorder.fillColor = .clear
        innerBorder.strokeColor = SKColor(red: 0.50, green: 0.40, blue: 0.25, alpha: 0.25)
        innerBorder.lineWidth = 1
        bg.addChild(innerBorder)

        // Color swatch / icon on the left side
        let icon = ingredient.iconBuilder(cardWidth)
        icon.position = CGPoint(x: -cardWidth * 0.28, y: 0)
        icon.zPosition = 1
        container.addChild(icon)

        // Name label on the right
        let nameLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        nameLabel.text = ingredient.name
        nameLabel.fontSize = 20
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -cardWidth * 0.10, y: 0)
        nameLabel.zPosition = 1
        container.addChild(nameLabel)

        return container
    }

    // MARK: - Icon Builders

    private static func buildNoodleIcon(width: CGFloat) -> SKNode {
        let node = SKNode()
        // Three wavy lines to represent noodles
        for i in 0..<3 {
            let path = CGMutablePath()
            let baseY = CGFloat(i - 1) * 10
            path.move(to: CGPoint(x: -18, y: baseY))
            path.addCurve(to: CGPoint(x: 18, y: baseY),
                          control1: CGPoint(x: -8, y: baseY + 8),
                          control2: CGPoint(x: 8, y: baseY - 8))
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor(red: 0.96, green: 0.93, blue: 0.82, alpha: 1.0)
            line.lineWidth = 2.5
            line.fillColor = .clear
            line.lineCap = .round
            node.addChild(line)
        }
        return node
    }

    private static func buildBrisketIcon(width: CGFloat) -> SKNode {
        let rect = SKShapeNode(rectOf: CGSize(width: 34, height: 20), cornerRadius: 4)
        rect.fillColor = SKColor(red: 0.50, green: 0.30, blue: 0.15, alpha: 1.0)
        rect.strokeColor = SKColor(red: 0.40, green: 0.22, blue: 0.10, alpha: 1.0)
        rect.lineWidth = 1.5
        return rect
    }

    private static func buildRawBeefIcon(width: CGFloat) -> SKNode {
        let rect = SKShapeNode(rectOf: CGSize(width: 34, height: 20), cornerRadius: 4)
        rect.fillColor = SKColor(red: 0.90, green: 0.20, blue: 0.18, alpha: 1.0)
        rect.strokeColor = SKColor(red: 0.75, green: 0.15, blue: 0.12, alpha: 1.0)
        rect.lineWidth = 1.5
        return rect
    }

    private static func buildBrothIcon(width: CGFloat) -> SKNode {
        let node = SKNode()
        // Golden circle representing ladle of broth
        let circle = SKShapeNode(circleOfRadius: 16)
        circle.fillColor = SKColor(red: 0.85, green: 0.68, blue: 0.22, alpha: 1.0)
        circle.strokeColor = SKColor(red: 0.72, green: 0.55, blue: 0.15, alpha: 1.0)
        circle.lineWidth = 1.5
        node.addChild(circle)
        // Small handle line
        let handlePath = CGMutablePath()
        handlePath.move(to: CGPoint(x: 12, y: 8))
        handlePath.addLine(to: CGPoint(x: 22, y: 16))
        let handle = SKShapeNode(path: handlePath)
        handle.strokeColor = SKColor(red: 0.60, green: 0.50, blue: 0.30, alpha: 1.0)
        handle.lineWidth = 3
        handle.lineCap = .round
        node.addChild(handle)
        return node
    }

    // MARK: - HUD

    private func setupHUD() {
        // Title
        let title = SKLabelNode(fontNamed: "SFProRounded-Bold")
        title.text = "Build Your Bowl"
        title.fontSize = 34
        title.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height - 60)
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.zPosition = 100
        gameLayer.addChild(title)

        // Step indicator
        stepLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        stepLabel.text = "Step 1/4"
        stepLabel.fontSize = 22
        stepLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        stepLabel.position = CGPoint(x: size.width / 2, y: size.height - 95)
        stepLabel.horizontalAlignmentMode = .center
        stepLabel.verticalAlignmentMode = .center
        stepLabel.zPosition = 100
        gameLayer.addChild(stepLabel)

        // Feedback label (hidden by default)
        feedbackLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        feedbackLabel.text = ""
        feedbackLabel.fontSize = 24
        feedbackLabel.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 1.0)
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        feedbackLabel.horizontalAlignmentMode = .center
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.zPosition = 100
        feedbackLabel.alpha = 0
        gameLayer.addChild(feedbackLabel)
    }

    private func updateStepLabel() {
        let display = min(currentStep + 1, 4)
        stepLabel.text = "Step \(display)/4"
    }

    // MARK: - Hint Pulse

    /// Subtly pulses the card for the current correct ingredient.
    private func updateHintPulse() {
        // Remove existing pulses from all cards
        for card in cardNodes {
            card.removeAction(forKey: "hintPulse")
            if let bg = card.childNode(withName: "cardBG_\(card.userData?["ingredientIndex"] as? Int ?? -1)") as? SKShapeNode {
                bg.glowWidth = 0
            }
        }

        guard currentStep < correctOrder.count else { return }

        // Find the card matching the current step
        let targetName = correctOrder[currentStep]
        for card in cardNodes {
            guard let name = card.userData?["ingredientName"] as? String,
                  name == targetName else { continue }

            let idx = card.userData?["ingredientIndex"] as? Int ?? 0
            guard let bg = card.childNode(withName: "cardBG_\(idx)") as? SKShapeNode else { continue }

            // Subtle glow pulse
            bg.glowWidth = 1
            let pulseUp = SKAction.customAction(withDuration: 0.8) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let t = elapsed / 0.8
                shape.glowWidth = 1 + 4 * sin(t * .pi)
            }
            let pulseDown = SKAction.customAction(withDuration: 0.8) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let t = elapsed / 0.8
                shape.glowWidth = 1 + 4 * sin((.pi) + t * .pi)
            }
            let pulseSequence = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
            bg.run(pulseSequence, withKey: "hintPulse")
            break
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, !gameFinished else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: gameLayer)
        let tappedNodes = gameLayer.nodes(at: location)

        // Walk up to find a card container
        var tappedCard: SKNode?
        for node in tappedNodes {
            var current: SKNode? = node
            while let c = current {
                if let name = c.name, name.hasPrefix("card_") {
                    tappedCard = c
                    break
                }
                current = c.parent
            }
            if tappedCard != nil { break }
        }

        guard let card = tappedCard else { return }
        guard let ingredientName = card.userData?["ingredientName"] as? String else { return }

        let expectedName = correctOrder[currentStep]

        if ingredientName == expectedName {
            handleCorrectTap(card: card)
        } else {
            handleWrongTap(card: card, tappedName: ingredientName)
        }
    }

    // MARK: - Correct Tap

    private func handleCorrectTap(card: SKNode) {
        guard currentStep < correctOrder.count else { return }
        gameActive = false  // disable input during animation

        attempts[currentStep] += 1
        let attemptCount = attempts[currentStep]

        HapticManager.shared.medium()

        // Remove hint pulse
        let idx = card.userData?["ingredientIndex"] as? Int ?? 0
        if let bg = card.childNode(withName: "cardBG_\(idx)") as? SKShapeNode {
            bg.removeAction(forKey: "hintPulse")
            bg.glowWidth = 0
        }

        // Check if this is the broth (step 3 = index 3)
        if currentStep == 3 {
            // Disable the card visually
            disableCard(card)
            // The broth gets the cinematic pour treatment
            currentStep += 1
            updateStepLabel()
            startBrothPour()
            return
        }

        // --- Ingredient drop animation ---
        let ingredientIndex = currentStep
        let startPos = card.position
        let bowlTarget = bowlCenter

        // Create a flying copy of the ingredient
        let flyingNode = createFlyingIngredient(for: ingredientIndex)
        flyingNode.position = startPos
        flyingNode.zPosition = 80
        flyingNode.setScale(1.0)
        gameLayer.addChild(flyingNode)

        // Disable the card visually
        disableCard(card)

        // Arc motion to the bowl
        let midPoint = CGPoint(x: (startPos.x + bowlTarget.x) / 2,
                               y: max(startPos.y, bowlTarget.y) + 60)

        let arcDuration: TimeInterval = 0.55
        let arcPath = CGMutablePath()
        arcPath.move(to: startPos)
        arcPath.addQuadCurve(to: bowlTarget, control: midPoint)

        let followArc = SKAction.follow(arcPath, asOffset: false, orientToPath: false,
                                         duration: arcDuration)
        followArc.timingMode = .easeIn

        let shrink = SKAction.scale(to: 0.6, duration: arcDuration)

        let dropSequence = SKAction.sequence([
            SKAction.group([followArc, shrink]),
            SKAction.run { [weak self] in
                flyingNode.removeFromParent()
                self?.addLayerToBowl(ingredientIndex: ingredientIndex)
                HapticManager.shared.heavy()
            },
            SKAction.wait(forDuration: 0.15)
        ])

        flyingNode.run(dropSequence) { [weak self] in
            guard let self = self else { return }
            self.currentStep += 1
            self.updateStepLabel()
            self.updateHintPulse()
            self.gameActive = true
        }

        // Show points
        let points = pointsForAttempt(attemptCount)
        showFloatingPoints("+\(points)", at: bowlTarget, color: SKColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1.0))
    }

    // MARK: - Wrong Tap

    private func handleWrongTap(card: SKNode, tappedName: String) {
        attempts[currentStep] += 1

        HapticManager.shared.error()

        // Shake/wiggle the card
        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.06, duration: 0.05),
            SKAction.rotate(byAngle: -0.12, duration: 0.1),
            SKAction.rotate(byAngle: 0.12, duration: 0.1),
            SKAction.rotate(byAngle: -0.06, duration: 0.05)
        ])
        card.run(wiggle)

        // Brief red flash on the card
        let idx = card.userData?["ingredientIndex"] as? Int ?? 0
        if let bg = card.childNode(withName: "cardBG_\(idx)") as? SKShapeNode {
            let originalColor = bg.fillColor
            let flashRed = SKAction.customAction(withDuration: 0.15) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let t = elapsed / 0.15
                let r: CGFloat = 0.70 + (0.22 - 0.70) * t
                let g: CGFloat = 0.15 + (0.15 - 0.15) * t
                let b: CGFloat = 0.12 + (0.08 - 0.12) * t
                shape.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.92)
            }
            let restoreColor = SKAction.run {
                bg.fillColor = originalColor
            }
            bg.run(SKAction.sequence([flashRed, restoreColor]))
        }

        // Show feedback text
        let feedbackText = wrongFeedbackText(tappedName: tappedName)
        feedbackLabel.text = feedbackText
        feedbackLabel.fontColor = SKColor(red: 1.0, green: 0.55, blue: 0.45, alpha: 1.0)
        feedbackLabel.alpha = 0
        feedbackLabel.setScale(0.8)

        let showFeedback = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let hideFeedback = SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeAlpha(to: 0.0, duration: 0.4)
        ])
        feedbackLabel.run(SKAction.sequence([showFeedback, hideFeedback]))
    }

    private func wrongFeedbackText(tappedName: String) -> String {
        switch currentStep {
        case 0:
            // Noodles should be first
            return "Start with the noodles!"
        case 1:
            // Brisket should be second
            if tappedName == "Raw Beef" || tappedName == "Broth" {
                return "Add the brisket first!"
            }
            return "Add the brisket first!"
        case 2:
            // Raw beef should be third
            if tappedName == "Broth" {
                return "Raw beef goes on top so the broth cooks it!"
            }
            return "Raw beef goes on top!"
        case 3:
            return "Time for the broth!"
        default:
            return "Not quite!"
        }
    }

    // MARK: - Card Visual States

    private func disableCard(_ card: SKNode) {
        let fadeDown = SKAction.fadeAlpha(to: 0.30, duration: 0.3)
        card.run(fadeDown)
        card.userData?["disabled"] = true
    }

    // MARK: - Flying Ingredient

    private func createFlyingIngredient(for index: Int) -> SKNode {
        let node = SKNode()
        let ingredient = ingredients[index]

        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth * 0.6, height: cardHeight * 0.6),
                             cornerRadius: 10)
        bg.fillColor = ingredient.color.withAlphaComponent(0.9)
        bg.strokeColor = .clear
        node.addChild(bg)

        return node
    }

    // MARK: - Bowl Layers

    private func addLayerToBowl(ingredientIndex: Int) {
        let inset: CGFloat = 30
        let layerWidth = bowlWidth - inset * 2
        let layerHeight: CGFloat = 32
        let ingredient = ingredients[ingredientIndex]

        // Vertical position inside the bowl: stack layers from bottom
        // Bowl interior ellipse vertical range approx -bowlHeight/2+16 to bowlHeight/2-16
        let baseY: CGFloat = -bowlHeight * 0.30
        let stepOffset = CGFloat(ingredientIndex) * (layerHeight + 6)
        let layerY = baseY + stepOffset

        if ingredientIndex == 0 {
            // Noodles: wavy layer
            let noodleLayer = SKNode()
            let noodleRect = SKShapeNode(rectOf: CGSize(width: layerWidth, height: layerHeight),
                                         cornerRadius: 8)
            noodleRect.fillColor = SKColor(red: 0.96, green: 0.93, blue: 0.82, alpha: 1.0)
            noodleRect.strokeColor = SKColor(red: 0.88, green: 0.84, blue: 0.72, alpha: 1.0)
            noodleRect.lineWidth = 1
            noodleLayer.addChild(noodleRect)

            // Wavy lines across it
            for i in 0..<5 {
                let path = CGMutablePath()
                let waveBaseY = CGFloat(i - 2) * 6
                path.move(to: CGPoint(x: -layerWidth * 0.4, y: waveBaseY))
                path.addCurve(to: CGPoint(x: layerWidth * 0.4, y: waveBaseY),
                              control1: CGPoint(x: -layerWidth * 0.15, y: waveBaseY + 5),
                              control2: CGPoint(x: layerWidth * 0.15, y: waveBaseY - 5))
                let waveLine = SKShapeNode(path: path)
                waveLine.strokeColor = SKColor(red: 0.88, green: 0.85, blue: 0.74, alpha: 0.6)
                waveLine.lineWidth = 1.5
                waveLine.fillColor = .clear
                waveLine.lineCap = .round
                noodleLayer.addChild(waveLine)
            }

            noodleLayer.position = CGPoint(x: 0, y: layerY)
            noodleLayer.zPosition = 1
            noodleLayer.setScale(0.3)
            noodleLayer.alpha = 0
            layerContainer.addChild(noodleLayer)

            // Landing animation: bounce settle
            let landAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.1, duration: 0.15),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ]),
                SKAction.scale(to: 0.95, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.06)
            ])
            noodleLayer.run(landAnimation)

        } else if ingredientIndex == 1 {
            // Brisket: brown layer
            let brisketLayer = SKShapeNode(rectOf: CGSize(width: layerWidth * 0.85, height: layerHeight),
                                           cornerRadius: 6)
            brisketLayer.fillColor = SKColor(red: 0.50, green: 0.30, blue: 0.15, alpha: 1.0)
            brisketLayer.strokeColor = SKColor(red: 0.42, green: 0.24, blue: 0.10, alpha: 1.0)
            brisketLayer.lineWidth = 1
            brisketLayer.position = CGPoint(x: 0, y: layerY)
            brisketLayer.zPosition = 2
            brisketLayer.setScale(0.3)
            brisketLayer.alpha = 0
            layerContainer.addChild(brisketLayer)

            // Add subtle marbling lines
            for _ in 0..<3 {
                let mx = CGFloat.random(in: -layerWidth * 0.3...layerWidth * 0.3)
                let mw = CGFloat.random(in: 20...50)
                let marble = SKShapeNode(rectOf: CGSize(width: mw, height: 2), cornerRadius: 1)
                marble.fillColor = SKColor(red: 0.58, green: 0.38, blue: 0.22, alpha: 0.5)
                marble.strokeColor = .clear
                marble.position = CGPoint(x: mx, y: CGFloat.random(in: -8...8))
                brisketLayer.addChild(marble)
            }

            let landAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.1, duration: 0.15),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ]),
                SKAction.scale(to: 0.95, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.06)
            ])
            brisketLayer.run(landAnimation)

        } else if ingredientIndex == 2 {
            // Raw beef: bright red layer
            let beefLayer = SKShapeNode(rectOf: CGSize(width: layerWidth * 0.75, height: layerHeight * 0.8),
                                        cornerRadius: 5)
            beefLayer.fillColor = SKColor(red: 0.90, green: 0.20, blue: 0.18, alpha: 1.0)
            beefLayer.strokeColor = SKColor(red: 0.78, green: 0.15, blue: 0.12, alpha: 1.0)
            beefLayer.lineWidth = 1
            beefLayer.position = CGPoint(x: 0, y: layerY)
            beefLayer.zPosition = 3
            beefLayer.setScale(0.3)
            beefLayer.alpha = 0
            layerContainer.addChild(beefLayer)

            // Keep reference for the broth pour color change
            rawBeefLayerNode = beefLayer

            let landAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.1, duration: 0.15),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ]),
                SKAction.scale(to: 0.95, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.06)
            ])
            beefLayer.run(landAnimation)
        }
    }

    // MARK: - Scoring

    private func pointsForAttempt(_ attempt: Int) -> Int {
        switch attempt {
        case 1: return 3
        case 2: return 2
        default: return 1
        }
    }

    private func showFloatingPoints(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(fontNamed: "SFProRounded-Bold")
        label.text = text
        label.fontSize = 28
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 40)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 120
        label.alpha = 0
        gameLayer.addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.12),
                SKAction.moveBy(x: 0, y: 60, duration: 0.8),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.4),
                    SKAction.fadeAlpha(to: 0, duration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - ============================================
    // MARK: - HERO BROTH POUR CINEMATIC
    // MARK: - ============================================

    private func startBrothPour() {
        gameActive = false
        gameFinished = true

        // Show points for broth step
        let brothAttempt = attempts[3]
        let brothPoints = pointsForAttempt(brothAttempt)
        showFloatingPoints("+\(brothPoints)", at: bowlCenter, color: SKColor(red: 0.85, green: 0.68, blue: 0.22, alpha: 1.0))

        HapticManager.shared.success()

        // Phase 0: Brief anticipation pause
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.pourPhase1_ladleAppear() }
        ]))
    }

    // --- Phase 1: Ladle appears above the bowl ---

    private func pourPhase1_ladleAppear() {
        let ladleNode = SKNode()
        ladleNode.name = "ladle"
        ladleNode.zPosition = 60

        // Ladle bowl (the cup part)
        let ladleBowl = SKShapeNode(ellipseOf: CGSize(width: 90, height: 65))
        ladleBowl.fillColor = SKColor(red: 0.50, green: 0.42, blue: 0.32, alpha: 1.0)
        ladleBowl.strokeColor = SKColor(red: 0.40, green: 0.32, blue: 0.22, alpha: 1.0)
        ladleBowl.lineWidth = 2.5
        ladleBowl.name = "ladleBowl"
        ladleNode.addChild(ladleBowl)

        // Broth visible inside the ladle
        let brothInLadle = SKShapeNode(ellipseOf: CGSize(width: 72, height: 48))
        brothInLadle.fillColor = SKColor(red: 0.85, green: 0.68, blue: 0.22, alpha: 1.0)
        brothInLadle.strokeColor = .clear
        brothInLadle.position = CGPoint(x: 0, y: -3)
        brothInLadle.name = "brothInLadle"
        ladleNode.addChild(brothInLadle)

        // Handle
        let handlePath = CGMutablePath()
        handlePath.move(to: CGPoint(x: 40, y: 15))
        handlePath.addLine(to: CGPoint(x: 130, y: 70))
        let handleNode = SKShapeNode(path: handlePath)
        handleNode.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        handleNode.lineWidth = 8
        handleNode.lineCap = .round
        ladleNode.addChild(handleNode)

        // Specular highlight on ladle bowl
        let ladleHighlight = SKShapeNode(ellipseOf: CGSize(width: 30, height: 16))
        ladleHighlight.fillColor = SKColor(white: 1.0, alpha: 0.25)
        ladleHighlight.strokeColor = .clear
        ladleHighlight.position = CGPoint(x: -15, y: 10)
        ladleNode.addChild(ladleHighlight)

        // Starting position: above and to the right
        ladleNode.position = CGPoint(x: bowlCenter.x + 100, y: bowlCenter.y + 280)
        ladleNode.alpha = 0
        ladleNode.setScale(0.6)
        gameLayer.addChild(ladleNode)

        // Animate in: sweep to position above bowl center
        let targetPos = CGPoint(x: bowlCenter.x + 20, y: bowlCenter.y + 180)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.5),
            SKAction.move(to: targetPos, duration: 0.6)
        ])
        appear.timingMode = .easeOut

        ladleNode.run(SKAction.sequence([
            appear,
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in self?.pourPhase2_tiltAndPour(ladleNode: ladleNode) }
        ]))
    }

    // --- Phase 2: Ladle tilts and broth stream begins ---

    private func pourPhase2_tiltAndPour(ladleNode: SKNode) {
        HapticManager.shared.heavy()

        // Tilt the ladle
        let tilt = SKAction.rotate(toAngle: -.pi / 5, duration: 0.5)
        tilt.timingMode = .easeInEaseOut

        // Move ladle slightly left and down as it tilts
        let shift = SKAction.moveBy(x: -30, y: -20, duration: 0.5)
        shift.timingMode = .easeInEaseOut

        ladleNode.run(SKAction.group([tilt, shift]))

        // Start the broth stream after a brief tilt
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                self?.pourPhase3_brothStream(ladleNode: ladleNode)
            }
        ]))
    }

    // --- Phase 3: Golden broth stream flows from ladle to bowl ---

    private func pourPhase3_brothStream(ladleNode: SKNode) {
        // The stream origin: tip of the tilted ladle
        let streamOrigin = CGPoint(
            x: ladleNode.position.x - 35,
            y: ladleNode.position.y - 30
        )
        let streamTarget = CGPoint(x: bowlCenter.x, y: bowlCenter.y + 20)

        // Create stream node: thin golden rectangle that extends downward
        let streamNode = SKShapeNode()
        streamNode.zPosition = 55
        streamNode.name = "brothStream"
        gameLayer.addChild(streamNode)

        // Animated stream extension
        let streamDuration: TimeInterval = 0.8
        let streamExtend = SKAction.customAction(withDuration: streamDuration) { [weak streamNode] _, elapsed in
            guard let stream = streamNode as? SKShapeNode else { return }
            let progress = min(elapsed / streamDuration, 1.0)

            let currentEndY = streamOrigin.y + (streamTarget.y - streamOrigin.y) * progress
            let currentEndX = streamOrigin.x + (streamTarget.x - streamOrigin.x) * progress

            // Stream width varies: thicker at top, thinner at bottom
            let topWidth: CGFloat = 14
            let bottomWidth: CGFloat = 8 + 6 * (1 - progress)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: streamOrigin.x - topWidth / 2, y: streamOrigin.y))
            path.addLine(to: CGPoint(x: streamOrigin.x + topWidth / 2, y: streamOrigin.y))
            path.addLine(to: CGPoint(x: currentEndX + bottomWidth / 2, y: currentEndY))
            path.addLine(to: CGPoint(x: currentEndX - bottomWidth / 2, y: currentEndY))
            path.closeSubpath()

            stream.path = path
            stream.fillColor = SKColor(red: 0.85, green: 0.68, blue: 0.22, alpha: 0.9)
            stream.strokeColor = SKColor(red: 0.78, green: 0.60, blue: 0.18, alpha: 0.5)
            stream.lineWidth = 1
        }

        // Small droplet particles along the stream for realism
        let spawnDroplets = SKAction.repeat(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnBrothDroplet(near: streamOrigin, target: streamTarget)
                },
                SKAction.wait(forDuration: 0.06)
            ]),
            count: 12
        )

        streamNode.run(SKAction.sequence([
            streamExtend,
            SKAction.run { [weak self] in
                self?.pourPhase4_bowlFill(streamNode: streamNode, ladleNode: ladleNode)
            }
        ]))

        run(spawnDroplets)
    }

    private func spawnBrothDroplet(near origin: CGPoint, target: CGPoint) {
        let t = CGFloat.random(in: 0.2...0.9)
        let dropX = origin.x + (target.x - origin.x) * t + CGFloat.random(in: -12...12)
        let dropY = origin.y + (target.y - origin.y) * t + CGFloat.random(in: -8...8)

        let droplet = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
        droplet.fillColor = SKColor(red: 0.88, green: 0.72, blue: 0.28, alpha: 0.8)
        droplet.strokeColor = .clear
        droplet.position = CGPoint(x: dropX, y: dropY)
        droplet.zPosition = 56
        gameLayer.addChild(droplet)

        droplet.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -8...8), y: -20, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.2, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // --- Phase 4: Bowl fills with golden broth ---

    private func pourPhase4_bowlFill(streamNode: SKShapeNode, ladleNode: SKNode) {
        HapticManager.shared.heavy()

        // Create the broth fill inside the bowl — animated fill from bottom
        let inset: CGFloat = 24
        let fillWidth = bowlWidth - inset * 2
        let fillMaxHeight: CGFloat = bowlHeight * 0.65

        let brothFillNode = SKShapeNode()
        brothFillNode.zPosition = 4  // between bowl interior and ingredient layers
        brothFillNode.position = bowlCenter
        brothFillNode.name = "brothFill"
        gameLayer.addChild(brothFillNode)

        let fillDuration: TimeInterval = 1.5

        let fillAnimation = SKAction.customAction(withDuration: fillDuration) { [weak brothFillNode, weak self] _, elapsed in
            guard let fill = brothFillNode as? SKShapeNode, let self = self else { return }
            let progress = min(elapsed / fillDuration, 1.0)

            let currentHeight = fillMaxHeight * progress
            let bottomY = -self.bowlHeight * 0.35

            // Elliptical shape for the broth surface
            let path = CGMutablePath()
            let fillRect = CGRect(x: -fillWidth / 2, y: bottomY,
                                  width: fillWidth, height: currentHeight)
            path.addRoundedRect(in: fillRect, cornerWidth: fillWidth * 0.15,
                                cornerHeight: min(currentHeight * 0.3, 20))

            fill.path = path

            // Broth color: golden with slight amber depth
            let depth = 0.08 * progress
            fill.fillColor = SKColor(red: 0.85 - depth,
                                     green: 0.68 - depth * 0.5,
                                     blue: 0.22 - depth * 0.3,
                                     alpha: 0.92)
            fill.strokeColor = .clear
        }

        // Also start cooking the raw beef (color change from red to pink)
        let cookBeef = SKAction.customAction(withDuration: 1.5) { [weak self] _, elapsed in
            guard let beef = self?.rawBeefLayerNode else { return }
            let progress = min(elapsed / 1.5, 1.0)
            // Red -> pink transition
            let r: CGFloat = 0.90 + (0.88 - 0.90) * progress
            let g: CGFloat = 0.20 + (0.55 - 0.20) * progress
            let b: CGFloat = 0.18 + (0.50 - 0.18) * progress
            beef.fillColor = SKColor(red: r, green: g, blue: b, alpha: 1.0)

            // Also lighten the stroke
            let sr: CGFloat = 0.78 + (0.75 - 0.78) * progress
            let sg: CGFloat = 0.15 + (0.45 - 0.15) * progress
            let sb: CGFloat = 0.12 + (0.40 - 0.12) * progress
            beef.strokeColor = SKColor(red: sr, green: sg, blue: sb, alpha: 1.0)
        }

        // Run fill and cook simultaneously
        run(SKAction.group([
            SKAction.run { brothFillNode.run(fillAnimation) },
            cookBeef
        ]))

        // Continue stream particles during the fill
        let continuedDroplets = SKAction.repeat(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let streamOrigin = CGPoint(
                        x: ladleNode.position.x - 35,
                        y: ladleNode.position.y - 30
                    )
                    let streamTarget = CGPoint(x: self.bowlCenter.x, y: self.bowlCenter.y + 20)
                    self.spawnBrothDroplet(near: streamOrigin, target: streamTarget)
                },
                SKAction.wait(forDuration: 0.08)
            ]),
            count: 18
        )
        run(continuedDroplets)

        // After fill completes, move to steam burst
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.6),
            SKAction.run { [weak self] in
                // Fade out the stream
                streamNode.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))

                // Ladle retreats
                let retreat = SKAction.group([
                    SKAction.moveBy(x: 120, y: 100, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.rotate(toAngle: 0, duration: 0.4)
                ])
                retreat.timingMode = .easeIn
                ladleNode.run(SKAction.sequence([retreat, SKAction.removeFromParent()]))

                // Fade the broth in ladle
                if let brothInLadle = ladleNode.childNode(withName: "brothInLadle") as? SKShapeNode {
                    brothInLadle.run(SKAction.fadeOut(withDuration: 0.3))
                }
            },
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in self?.pourPhase5_steamBurst() }
        ]))
    }

    // --- Phase 5: Massive steam burst + zoom ---

    private func pourPhase5_steamBurst() {
        HapticManager.shared.heavy()

        // Create programmatic steam emitter
        let steamEmitter = createSteamEmitter()
        steamEmitter.position = CGPoint(x: bowlCenter.x, y: bowlCenter.y + bowlHeight * 0.25)
        steamEmitter.zPosition = 70
        gameLayer.addChild(steamEmitter)

        // Also spawn a burst of large steam puffs for extra drama
        spawnSteamPuffs(count: 20)

        // Camera-like zoom: scale gameLayer to 1.2x centered on the bowl
        // First, we need to adjust the position so the zoom centers on the bowl
        let zoomScale: CGFloat = 1.2
        let zoomDuration: TimeInterval = 0.8

        // Calculate the anchor offset for centering the zoom on the bowl
        let bowlInScene = bowlCenter
        let offsetX = bowlInScene.x * (1 - zoomScale)
        let offsetY = bowlInScene.y * (1 - zoomScale)

        let zoomIn = SKAction.group([
            SKAction.scale(to: zoomScale, duration: zoomDuration),
            SKAction.move(to: CGPoint(x: offsetX, y: offsetY), duration: zoomDuration)
        ])
        zoomIn.timingMode = .easeOut
        gameLayer.run(zoomIn)

        // Add a warm golden overlay flash
        let goldenFlash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        goldenFlash.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.55, alpha: 0.0)
        goldenFlash.strokeColor = .clear
        goldenFlash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        goldenFlash.zPosition = 200
        addChild(goldenFlash)

        goldenFlash.run(SKAction.sequence([
            SKAction.customAction(withDuration: 0.3) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let progress = elapsed / 0.3
                shape.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.55,
                                          alpha: 0.18 * progress)
            },
            SKAction.wait(forDuration: 0.6),
            SKAction.customAction(withDuration: 0.6) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let progress = elapsed / 0.6
                shape.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.55,
                                          alpha: 0.18 * (1 - progress))
            },
            SKAction.removeFromParent()
        ]))

        // Surface shimmer on the broth
        spawnBrothShimmer()

        // After the full cinematic moment, call completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                // Stop the emitter
                steamEmitter.particleBirthRate = 0

                // Zoom back
                let zoomOut = SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.5),
                    SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.5)
                ])
                zoomOut.timingMode = .easeInEaseOut
                self?.gameLayer.run(zoomOut)
            },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.reportScore() }
        ]))
    }

    // MARK: - Steam Emitter (Programmatic)

    private func createSteamEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 150
        emitter.numParticlesToEmit = 300  // total across ~2 seconds
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.8

        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = .pi / 2                // upward
        emitter.emissionAngleRange = .pi / 3           // wide upward spread

        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.08
        emitter.particleScaleSpeed = 0.12

        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.35
        emitter.particleAlphaRange = 0.2

        emitter.particleColor = SKColor(white: 0.95, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 1.0, alpha: 1.0),
                SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.8),
                SKColor(white: 0.9, alpha: 0.0)
            ],
            times: [0.0, 0.5, 1.0]
        )

        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 0.3

        emitter.xAcceleration = 0
        emitter.yAcceleration = 20          // slight upward push

        emitter.particlePositionRange = CGVector(dx: bowlWidth * 0.6, dy: 15)

        // Create a circle texture for the particles
        emitter.particleTexture = createSteamTexture()

        return emitter
    }

    private func createSteamTexture() -> SKTexture {
        let texSize: CGFloat = 64
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: texSize, height: texSize))
        let image = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: texSize, height: texSize)
            // Radial gradient: bright center, transparent edge
            let center = CGPoint(x: texSize / 2, y: texSize / 2)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(white: 1.0, alpha: 1.0).cgColor,
                UIColor(white: 1.0, alpha: 0.6).cgColor,
                UIColor(white: 1.0, alpha: 0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.5, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: texSize / 2,
                    options: .drawsAfterEndLocation
                )
            } else {
                // Fallback: simple circle
                ctx.cgContext.setFillColor(UIColor.white.cgColor)
                ctx.cgContext.fillEllipse(in: rect)
            }
        }
        return SKTexture(image: image)
    }

    // MARK: - Extra Steam Puffs

    private func spawnSteamPuffs(count: Int) {
        for i in 0..<count {
            let delay = Double(i) * 0.08 + Double.random(in: 0...0.15)
            let puffSize = CGFloat.random(in: 14...40)

            let puff = SKShapeNode(circleOfRadius: puffSize)
            puff.fillColor = SKColor(white: 0.95, alpha: CGFloat.random(in: 0.15...0.45))
            puff.strokeColor = .clear
            puff.zPosition = 65

            let startX = bowlCenter.x + CGFloat.random(in: -bowlWidth * 0.3...bowlWidth * 0.3)
            let startY = bowlCenter.y + bowlHeight * 0.15 + CGFloat.random(in: -10...10)
            puff.position = CGPoint(x: startX, y: startY)
            puff.setScale(0.3)
            puff.alpha = 0
            gameLayer.addChild(puff)

            let driftX = CGFloat.random(in: -50...50)
            let driftY = CGFloat.random(in: 80...200)
            let lifetime = Double.random(in: 1.2...2.5)

            puff.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.40), duration: 0.2),
                    SKAction.scale(to: CGFloat.random(in: 1.0...2.0), duration: lifetime),
                    SKAction.moveBy(x: driftX, y: driftY, duration: lifetime),
                    SKAction.sequence([
                        SKAction.wait(forDuration: lifetime * 0.5),
                        SKAction.fadeOut(withDuration: lifetime * 0.5)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Broth Surface Shimmer

    private func spawnBrothShimmer() {
        // Sparkling golden highlights on the broth surface
        for _ in 0..<12 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            sparkle.fillColor = SKColor(red: 1.0, green: 0.92, blue: 0.60, alpha: 0.0)
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 3

            let x = bowlCenter.x + CGFloat.random(in: -bowlWidth * 0.3...bowlWidth * 0.3)
            let y = bowlCenter.y + CGFloat.random(in: -bowlHeight * 0.1...bowlHeight * 0.15)
            sparkle.position = CGPoint(x: x, y: y)
            sparkle.zPosition = 68
            gameLayer.addChild(sparkle)

            let delay = Double.random(in: 0.2...1.5)
            let twinkle = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...0.9), duration: 0.3),
                SKAction.fadeAlpha(to: 0.0, duration: 0.4),
                SKAction.wait(forDuration: Double.random(in: 0.2...0.5)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.3...0.7), duration: 0.25),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ])
            sparkle.run(twinkle)
        }
    }

    // MARK: - Score Calculation

    private func reportScore() {
        var totalPoints = 0
        for i in 0..<4 {
            totalPoints += pointsForAttempt(attempts[i])
        }

        let score = Int((Double(totalPoints) / 12.0) * 100.0)

        let stars: Int
        if totalPoints >= 11 {
            stars = 3
        } else if totalPoints >= 8 {
            stars = 2
        } else {
            stars = 1
        }

        HapticManager.shared.success()
        onComplete?(score, stars)
    }
}
