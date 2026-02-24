import SpriteKit

class CharAromaticsScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Round State

    enum RoundState { case waiting, playing, released, transitioning }

    // MARK: - Constants

    private let ingredientNames = ["Onion Half", "Onion Half", "Ginger Slice", "Ginger Slice"]
    private let totalRounds = 4

    // Timing bar
    private let barWidth: CGFloat = 500
    private let barHeight: CGFloat = 24

    // Target zone shrinks per round: 18%, 16%, 14%, 12%
    private func targetZoneWidth(for round: Int) -> CGFloat {
        return barWidth * max(0.12, 0.18 - CGFloat(round) * 0.02)
    }

    // Cursor speed increases per round
    private func cursorSpeed(for round: Int) -> CGFloat {
        return 0.55 + CGFloat(round) * 0.12
    }

    // Scoring: distance from target center as fraction of bar width
    private let perfectThreshold: CGFloat = 0.09   // within 9% of bar = Perfect
    private let goodThreshold: CGFloat = 0.18       // within 18% of bar = Good

    // MARK: - State

    private var currentRound = 0
    private var roundState: RoundState = .waiting
    private var totalPoints = 0
    private var lastUpdateTime: TimeInterval = 0

    // Cursor
    private var cursorPosition: CGFloat = 0      // 0…1 across bar
    private var cursorDirection: CGFloat = 1     // 1 = right, -1 = left

    // Target zone (in 0…1 space)
    private var targetStart: CGFloat = 0
    private var targetEnd: CGFloat = 0

    // MARK: - Nodes

    private var skilletNode: SKShapeNode!
    private var ingredientNode: SKShapeNode!
    private var roundLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var smokeEmitter: SKEmitterNode!

    // Timing bar nodes
    private var timingBarBG: SKShapeNode!
    private var targetZoneNode: SKShapeNode!
    private var cursorNode: SKShapeNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 1)

        buildSkillet()
        buildIngredient()
        buildTimingBar()
        buildLabels()
        buildSmoke()
        buildHeatShimmer()

        configureRound()

        // Scene entrance curtain
        let curtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        curtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        curtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 1.0)
        curtain.strokeColor = .clear
        curtain.zPosition = 500
        addChild(curtain)
        curtain.run(.sequence([.wait(forDuration: 0.2), .fadeAlpha(to: 0, duration: 0.6), .removeFromParent()]))
    }

    // MARK: - Build Nodes

    private func buildSkillet() {
        let skilletRadius: CGFloat = 160
        skilletNode = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.4,
                                                     height: skilletRadius * 1.4))
        skilletNode.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        skilletNode.strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        skilletNode.lineWidth = 4
        skilletNode.position = CGPoint(x: size.width * 0.45, y: size.height * 0.38)
        skilletNode.zPosition = 1
        addChild(skilletNode)

        // Handle
        let handle = SKShapeNode(rect: CGRect(x: 0, y: -12, width: 120, height: 24),
                                 cornerRadius: 8)
        handle.fillColor = SKColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1)
        handle.strokeColor = SKColor(red: 0.30, green: 0.25, blue: 0.18, alpha: 1)
        handle.lineWidth = 2
        handle.position = CGPoint(x: skilletRadius * 1.2, y: 0)
        handle.zPosition = 0
        skilletNode.addChild(handle)
    }

    private func buildIngredient() {
        ingredientNode = SKShapeNode()
        ingredientNode.zPosition = 2
        addChild(ingredientNode)
    }

    private func configureIngredient() {
        ingredientNode.removeAllActions()

        let isOnion = currentRound < 2
        let skilletPos = skilletNode.position

        if isOnion {
            let radius: CGFloat = 55
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -radius, y: -radius,
                                       width: radius * 2, height: radius * 2))
            ingredientNode.path = path
            ingredientNode.fillColor = SKColor(red: 0.85, green: 0.78, blue: 0.60, alpha: 1)
            ingredientNode.strokeColor = SKColor(red: 0.70, green: 0.62, blue: 0.42, alpha: 1)
            ingredientNode.lineWidth = 3

            // Add concentric ring detail
            ingredientNode.removeAllChildren()
            for i in 1...3 {
                let ringRadius = CGFloat(i) * 15
                let ring = SKShapeNode(circleOfRadius: ringRadius)
                ring.fillColor = .clear
                ring.strokeColor = SKColor(red: 0.75, green: 0.68, blue: 0.50, alpha: 0.5)
                ring.lineWidth = 1.5
                ingredientNode.addChild(ring)
            }
        } else {
            let rect = CGRect(x: -60, y: -22, width: 120, height: 44)
            let path = CGMutablePath()
            path.addRoundedRect(in: rect, cornerWidth: 10, cornerHeight: 10)
            ingredientNode.path = path
            ingredientNode.fillColor = SKColor(red: 0.85, green: 0.72, blue: 0.30, alpha: 1)
            ingredientNode.strokeColor = SKColor(red: 0.72, green: 0.58, blue: 0.22, alpha: 1)
            ingredientNode.lineWidth = 3
            ingredientNode.removeAllChildren()
        }

        ingredientNode.position = CGPoint(x: skilletPos.x, y: skilletPos.y + 5)
    }

    // MARK: - Timing Bar

    private func buildTimingBar() {
        let barX = size.width * 0.45
        let barY = size.height * 0.12

        // Black background bar
        timingBarBG = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                                  cornerRadius: barHeight / 2)
        timingBarBG.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        timingBarBG.strokeColor = SKColor(white: 0.3, alpha: 0.8)
        timingBarBG.lineWidth = 2
        timingBarBG.position = CGPoint(x: barX, y: barY)
        timingBarBG.zPosition = 10
        addChild(timingBarBG)

        // Red target zone (positioned each round)
        targetZoneNode = SKShapeNode()
        targetZoneNode.fillColor = SKColor(red: 0.85, green: 0.18, blue: 0.15, alpha: 1.0)
        targetZoneNode.strokeColor = .clear
        targetZoneNode.zPosition = 11
        targetZoneNode.position = CGPoint(x: barX, y: barY)
        addChild(targetZoneNode)

        // White cursor bar
        cursorNode = SKShapeNode(rectOf: CGSize(width: 6, height: barHeight + 8),
                                 cornerRadius: 3)
        cursorNode.fillColor = .white
        cursorNode.strokeColor = .clear
        cursorNode.glowWidth = 3
        cursorNode.zPosition = 12
        cursorNode.position = CGPoint(x: barX - barWidth / 2, y: barY)
        addChild(cursorNode)
    }

    private func configureTimingBar() {
        let zoneWidth = targetZoneWidth(for: currentRound)
        let zoneFraction = zoneWidth / barWidth

        // Random center for the target zone, keeping it within bounds
        let minCenter = zoneFraction / 2 + 0.05
        let maxCenter = 1.0 - zoneFraction / 2 - 0.05
        let center = CGFloat.random(in: minCenter...maxCenter)

        targetStart = center - zoneFraction / 2
        targetEnd = center + zoneFraction / 2

        // Update visual
        let barLeftX = timingBarBG.position.x - barWidth / 2
        let zoneX = barLeftX + center * barWidth
        let zoneRect = CGRect(x: -zoneWidth / 2, y: -barHeight / 2 + 3,
                              width: zoneWidth, height: barHeight - 6)
        targetZoneNode.path = CGPath(roundedRect: zoneRect, cornerWidth: 4,
                                     cornerHeight: 4, transform: nil)
        targetZoneNode.position = CGPoint(x: zoneX, y: timingBarBG.position.y)

        // Reset cursor
        cursorPosition = 0
        cursorDirection = 1
        updateCursorPosition()
    }

    private func updateCursorPosition() {
        let barLeftX = timingBarBG.position.x - barWidth / 2
        cursorNode.position = CGPoint(x: barLeftX + cursorPosition * barWidth,
                                      y: timingBarBG.position.y)
    }

    private func buildLabels() {
        roundLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        roundLabel.fontSize = 28
        roundLabel.fontColor = .white
        roundLabel.position = CGPoint(x: size.width * 0.45, y: size.height - 100)
        roundLabel.horizontalAlignmentMode = .center
        roundLabel.verticalAlignmentMode = .center
        roundLabel.zPosition = 10
        addChild(roundLabel)

        feedbackLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        feedbackLabel.fontSize = 48
        feedbackLabel.fontColor = .white
        feedbackLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.62)
        feedbackLabel.horizontalAlignmentMode = .center
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.zPosition = 15
        feedbackLabel.alpha = 0
        addChild(feedbackLabel)

        instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.fontSize = 22
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        instructionLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.22)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 10
        instructionLabel.text = "Tap when the white bar hits the red zone!"
        addChild(instructionLabel)
    }

    private func buildSmoke() {
        smokeEmitter = SKEmitterNode()
        smokeEmitter.particleBirthRate = 0
        smokeEmitter.particleLifetime = 2.0
        smokeEmitter.particleColor = .gray
        smokeEmitter.particleColorAlphaSpeed = -0.5
        smokeEmitter.particleSpeed = 30
        smokeEmitter.particleSpeedRange = 15
        smokeEmitter.emissionAngle = .pi / 2
        smokeEmitter.emissionAngleRange = .pi / 6
        smokeEmitter.particleScale = 0.3
        smokeEmitter.particleScaleSpeed = 0.2
        smokeEmitter.particleAlpha = 0.6
        smokeEmitter.particleTexture = createSmokeTexture()
        smokeEmitter.position = ingredientNode?.position ?? CGPoint(x: size.width * 0.45,
                                                                     y: size.height * 0.40)
        smokeEmitter.zPosition = 3
        addChild(smokeEmitter)
    }

    private func createSmokeTexture() -> SKTexture {
        let texSize: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: texSize, height: texSize))
        let image = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: texSize, height: texSize)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
        return SKTexture(image: image)
    }

    // MARK: - Heat Shimmer

    private func buildHeatShimmer() {
        let skilletPos = skilletNode.position
        for i in 0..<3 {
            let shimmer = SKShapeNode(rectOf: CGSize(width: 80 + CGFloat(i) * 30, height: 2))
            shimmer.fillColor = SKColor(white: 1.0, alpha: 0.03)
            shimmer.strokeColor = .clear
            shimmer.position = CGPoint(x: skilletPos.x, y: skilletPos.y + 80 + CGFloat(i) * 25)
            shimmer.zPosition = 1.5
            addChild(shimmer)
            let wobble = SKAction.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: -15...15), y: 5, duration: 1.5 + Double(i) * 0.3),
                .moveBy(x: CGFloat.random(in: -15...15), y: -5, duration: 1.5 + Double(i) * 0.3)
            ]))
            shimmer.run(wobble)
        }
    }

    // MARK: - Round Management

    private func configureRound() {
        roundState = .waiting
        lastUpdateTime = 0

        configureIngredient()
        configureTimingBar()

        roundLabel.text = "Round \(currentRound + 1)/\(totalRounds): \(ingredientNames[currentRound])"
        feedbackLabel.alpha = 0
        instructionLabel.alpha = 1
        cursorNode.alpha = 1

        smokeEmitter.particleBirthRate = 3
        smokeEmitter.position = ingredientNode.position

        // Entrance animation for ingredient
        ingredientNode.setScale(0)
        ingredientNode.alpha = 1
        ingredientNode.run(.group([
            .scale(to: 1.0, duration: 0.35),
            .fadeAlpha(to: 1.0, duration: 0.35)
        ]))

        // Auto-start cursor after brief delay
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.roundState = .playing
                self?.instructionLabel.run(.fadeAlpha(to: 0.3, duration: 0.5))
            }
        ]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard roundState == .playing else { return }
        roundState = .released
        HapticManager.shared.light()
        AudioManager.shared.playSFX("sizzle")
        evaluateAndShowFeedback()
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        guard roundState == .playing else { return }

        // Move cursor
        let speed = cursorSpeed(for: currentRound)
        cursorPosition += cursorDirection * speed * CGFloat(dt)

        // Bounce off edges
        if cursorPosition >= 1.0 {
            cursorPosition = 1.0
            cursorDirection = -1
        } else if cursorPosition <= 0.0 {
            cursorPosition = 0.0
            cursorDirection = 1
        }

        updateCursorPosition()

        // Update smoke intensity with a gentle pulse
        smokeEmitter.particleBirthRate = 3 + 12 * abs(sin(CGFloat(currentTime) * 2))
        smokeEmitter.position = ingredientNode.position
    }

    // MARK: - Ingredient Charring

    private func applyCharEffect(quality: Int) {
        // Darken ingredient based on quality: 3 = perfect char, 1 = over/under
        let darkness: CGFloat
        switch quality {
        case 3: darkness = 0.35  // nice golden-brown
        case 2: darkness = 0.25
        default: darkness = 0.15
        }

        let blendColor = SKColor(red: 0.15, green: 0.08, blue: 0.0, alpha: 1)
        ingredientNode.fillColor = blendedColor(base: baseIngredientColor(),
                                                 blend: blendColor,
                                                 factor: darkness)
        ingredientNode.strokeColor = blendedColor(base: baseIngredientStrokeColor(),
                                                   blend: blendColor,
                                                   factor: darkness)
    }

    private func baseIngredientColor() -> SKColor {
        return currentRound < 2
            ? SKColor(red: 0.85, green: 0.78, blue: 0.60, alpha: 1)
            : SKColor(red: 0.85, green: 0.72, blue: 0.30, alpha: 1)
    }

    private func baseIngredientStrokeColor() -> SKColor {
        return currentRound < 2
            ? SKColor(red: 0.70, green: 0.62, blue: 0.42, alpha: 1)
            : SKColor(red: 0.72, green: 0.58, blue: 0.22, alpha: 1)
    }

    private func blendedColor(base: SKColor, blend: SKColor, factor: CGFloat) -> SKColor {
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
        base.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        blend.getRed(&dr, green: &dg, blue: &db, alpha: &da)
        let f = min(max(factor, 0), 1)
        return SKColor(red: br + (dr - br) * f,
                       green: bg + (dg - bg) * f,
                       blue: bb + (db - bb) * f,
                       alpha: 1)
    }

    // MARK: - Evaluation

    private func evaluateAndShowFeedback() {
        let targetCenter = (targetStart + targetEnd) / 2
        let distance = abs(cursorPosition - targetCenter)

        let points: Int
        let text: String
        let color: SKColor

        if cursorPosition >= targetStart && cursorPosition <= targetEnd {
            // Inside the red zone
            points = 3
            text = "Perfect Char!"
            color = SKColor(red: 0.2, green: 0.9, blue: 0.35, alpha: 1)
            HapticManager.shared.success()
            AudioManager.shared.playSFX("success-chime")

            // Grill marks on perfect char
            for i in 0..<3 {
                let mark = SKShapeNode(rectOf: CGSize(width: 40, height: 3))
                mark.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.0, alpha: 0.7)
                mark.strokeColor = .clear
                mark.position = CGPoint(x: CGFloat(i - 1) * 18, y: CGFloat(i - 1) * 8 - 5)
                mark.zRotation = -0.1
                ingredientNode.addChild(mark)
            }
        } else if distance <= goodThreshold {
            points = 2
            text = "Good"
            color = SKColor(red: 0.95, green: 0.85, blue: 0.25, alpha: 1)
            HapticManager.shared.medium()
        } else {
            points = 1
            text = "Missed!"
            color = SKColor(red: 0.95, green: 0.3, blue: 0.25, alpha: 1)
            HapticManager.shared.error()
            AudioManager.shared.playSFX("error-buzz")
        }

        totalPoints += points
        applyCharEffect(quality: points)

        // Show feedback
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.alpha = 0
        feedbackLabel.setScale(0.5)
        feedbackLabel.run(.group([
            .fadeAlpha(to: 1.0, duration: 0.15),
            .scale(to: 1.0, duration: 0.2)
        ]))

        // Flash the ingredient
        ingredientNode.run(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.1),
            .fadeAlpha(to: 1.0, duration: 0.1)
        ]))

        // Flash cursor with result color
        cursorNode.run(.sequence([
            .run { [weak self] in self?.cursorNode.fillColor = color },
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.cursorNode.fillColor = .white }
        ]))

        // Increase smoke on hit
        smokeEmitter.particleBirthRate = 30
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.smokeEmitter.particleBirthRate = 5 }
        ]))

        // Points label
        let pointsLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        pointsLabel.text = "+\(points)"
        pointsLabel.fontSize = 32
        pointsLabel.fontColor = color
        pointsLabel.position = CGPoint(x: feedbackLabel.position.x,
                                       y: feedbackLabel.position.y - 50)
        pointsLabel.zPosition = 15
        pointsLabel.alpha = 0
        addChild(pointsLabel)
        pointsLabel.run(.sequence([
            .group([
                .fadeAlpha(to: 1.0, duration: 0.15),
                .moveBy(x: 0, y: 30, duration: 0.8)
            ]),
            .fadeAlpha(to: 0.0, duration: 0.3),
            .removeFromParent()
        ]))

        // Advance round after delay
        roundState = .transitioning
        run(.sequence([
            .wait(forDuration: 1.4),
            .run { [weak self] in self?.advanceRound() }
        ]))
    }

    private func advanceRound() {
        currentRound += 1

        if currentRound >= totalRounds {
            finishGame()
        } else {
            // Fade out then configure next round
            let fadeOut = SKAction.group([
                SKAction.run { [weak self] in
                    self?.ingredientNode.run(.fadeAlpha(to: 0, duration: 0.25))
                    self?.feedbackLabel.run(.fadeAlpha(to: 0, duration: 0.25))
                    self?.smokeEmitter.particleBirthRate = 0
                }
            ])

            run(.sequence([
                fadeOut,
                .wait(forDuration: 0.35),
                .run { [weak self] in self?.configureRound() }
            ]))
        }
    }

    // MARK: - Finish

    private func finishGame() {
        feedbackLabel.run(.fadeAlpha(to: 0, duration: 0.3))
        smokeEmitter.particleBirthRate = 0
        HapticManager.shared.success()

        let score = Int((CGFloat(totalPoints) / 12.0) * 100.0)
        let stars: Int
        if totalPoints >= 10 {
            stars = 3
        } else if totalPoints >= 7 {
            stars = 2
        } else {
            stars = 1
        }

        // Scene exit curtain
        let exitCurtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        exitCurtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        exitCurtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0)
        exitCurtain.strokeColor = .clear
        exitCurtain.zPosition = 500
        addChild(exitCurtain)
        exitCurtain.run(.sequence([
            .wait(forDuration: 0.6),
            .fadeAlpha(to: 1.0, duration: 0.4),
            .run { [weak self] in self?.onComplete?(score, stars) }
        ]))
    }
}
