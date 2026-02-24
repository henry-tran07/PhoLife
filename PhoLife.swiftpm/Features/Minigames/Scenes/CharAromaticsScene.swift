import SpriteKit

class CharAromaticsScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Round State

    enum RoundState { case waiting, holding, released, transitioning }

    // MARK: - Constants

    private let ingredientNames = ["Onion Half", "Onion Half", "Ginger Slice", "Ginger Slice"]
    private let totalRounds = 4
    private let baseFillSpeed: CGFloat = 0.4        // full meter in ~2.5 s
    private let meterWidth: CGFloat = 40
    private let meterHeight: CGFloat = 400

    // MARK: - State

    private var currentRound = 0
    private var roundState: RoundState = .waiting
    private var meterValue: CGFloat = 0              // 0…1
    private var totalPoints = 0
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Nodes

    private var skilletNode: SKShapeNode!
    private var ingredientNode: SKShapeNode!
    private var meterBackground: SKShapeNode!
    private var meterFill: SKShapeNode!
    private var meterFillCrop: SKCropNode!
    private var greenZoneBand: SKShapeNode!
    private var indicatorLine: SKShapeNode!
    private var roundLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var smokeEmitter: SKEmitterNode!

    // MARK: - Zone Ranges (per round)

    /// Returns the green zone as a closed range within 0…1 for the given round index.
    private func greenZone(for round: Int) -> ClosedRange<CGFloat> {
        // Starts at 20% of meter, shrinks by ~2.7% each round down to ~12%
        let greenSize = max(0.12, 0.20 - CGFloat(round) * 0.027)
        let center: CGFloat = 0.55
        return (center - greenSize / 2)...(center + greenSize / 2)
    }

    private func yellowZoneLow(for round: Int) -> ClosedRange<CGFloat> {
        let green = greenZone(for: round)
        return 0.25...green.lowerBound
    }

    private func yellowZoneHigh(for round: Int) -> ClosedRange<CGFloat> {
        let green = greenZone(for: round)
        return green.upperBound...0.80
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 1)

        buildSkillet()
        buildIngredient()
        buildMeter()
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
        skilletNode.position = CGPoint(x: size.width * 0.45, y: size.height * 0.32)
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

    private func buildMeter() {
        let meterX = size.width - 80
        let meterY = size.height * 0.3

        // Background
        meterBackground = SKShapeNode(rect: CGRect(x: -meterWidth / 2, y: 0,
                                                    width: meterWidth, height: meterHeight),
                                      cornerRadius: 8)
        meterBackground.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        meterBackground.strokeColor = SKColor(white: 0.4, alpha: 1)
        meterBackground.lineWidth = 2
        meterBackground.position = CGPoint(x: meterX, y: meterY)
        meterBackground.zPosition = 5
        addChild(meterBackground)

        // Fill (uses a crop node so we can grow it from the bottom)
        meterFillCrop = SKCropNode()
        meterFillCrop.position = CGPoint(x: meterX, y: meterY)
        meterFillCrop.zPosition = 6

        let fillRect = SKShapeNode(rect: CGRect(x: -meterWidth / 2 + 3, y: 3,
                                                 width: meterWidth - 6,
                                                 height: meterHeight - 6),
                                   cornerRadius: 5)
        fillRect.fillColor = .gray
        fillRect.strokeColor = .clear
        fillRect.name = "meterFillRect"
        meterFill = fillRect
        meterFillCrop.addChild(fillRect)

        // Mask — a rect that we resize to reveal the fill from bottom
        let mask = SKSpriteNode(color: .white,
                                size: CGSize(width: meterWidth, height: 0))
        mask.anchorPoint = CGPoint(x: 0.5, y: 0)
        mask.position = CGPoint(x: 0, y: 0)
        mask.name = "fillMask"
        meterFillCrop.maskNode = mask

        addChild(meterFillCrop)

        // Green zone band
        greenZoneBand = SKShapeNode()
        greenZoneBand.zPosition = 5.5
        greenZoneBand.position = CGPoint(x: meterX, y: meterY)
        addChild(greenZoneBand)

        // Indicator line
        indicatorLine = SKShapeNode(rect: CGRect(x: -meterWidth / 2 - 6, y: -1,
                                                  width: meterWidth + 12, height: 2))
        indicatorLine.fillColor = .white
        indicatorLine.strokeColor = .clear
        indicatorLine.zPosition = 7
        indicatorLine.position = CGPoint(x: meterX, y: meterY)
        indicatorLine.alpha = 0
        addChild(indicatorLine)
    }

    private func updateGreenZoneBand() {
        let zone = greenZone(for: currentRound)
        let bandY = zone.lowerBound * meterHeight
        let bandH = (zone.upperBound - zone.lowerBound) * meterHeight

        let rect = CGRect(x: -meterWidth / 2 - 2, y: bandY,
                          width: meterWidth + 4, height: bandH)
        greenZoneBand.path = CGPath(roundedRect: rect, cornerWidth: 4,
                                    cornerHeight: 4, transform: nil)
        greenZoneBand.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.25)
        greenZoneBand.strokeColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.7)
        greenZoneBand.lineWidth = 1.5
        greenZoneBand.glowWidth = 3
    }

    /// Draw static zone color bands on the meter background.
    private func drawZoneBands() {
        // Remove old zone children
        meterBackground.children.forEach { $0.removeFromParent() }

        let inset: CGFloat = 3
        let barW = meterWidth - inset * 2
        let barH = meterHeight - inset * 2

        struct ZoneInfo {
            let start: CGFloat; let end: CGFloat; let color: SKColor
        }

        let green = greenZone(for: currentRound)
        let zones: [ZoneInfo] = [
            ZoneInfo(start: 0.0, end: 0.25,
                     color: SKColor(red: 0.45, green: 0.55, blue: 0.65, alpha: 0.35)),
            ZoneInfo(start: 0.25, end: green.lowerBound,
                     color: SKColor(red: 0.85, green: 0.75, blue: 0.20, alpha: 0.35)),
            ZoneInfo(start: green.lowerBound, end: green.upperBound,
                     color: SKColor(red: 0.20, green: 0.75, blue: 0.30, alpha: 0.35)),
            ZoneInfo(start: green.upperBound, end: 0.80,
                     color: SKColor(red: 0.85, green: 0.75, blue: 0.20, alpha: 0.35)),
            ZoneInfo(start: 0.80, end: 1.0,
                     color: SKColor(red: 0.85, green: 0.25, blue: 0.20, alpha: 0.35)),
        ]

        for z in zones {
            let y = inset + z.start * barH
            let h = (z.end - z.start) * barH
            let band = SKShapeNode(rect: CGRect(x: -meterWidth / 2 + inset, y: y,
                                                 width: barW, height: h))
            band.fillColor = z.color
            band.strokeColor = .clear
            band.zPosition = 0.1
            meterBackground.addChild(band)
        }
    }

    private func buildLabels() {
        roundLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        roundLabel.fontSize = 28
        roundLabel.fontColor = .white
        roundLabel.position = CGPoint(x: size.width * 0.45, y: size.height - 80)
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
        instructionLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.12)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 10
        instructionLabel.text = "Hold anywhere to heat — release in the green zone!"
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
                                                                     y: size.height * 0.34)
        smokeEmitter.zPosition = 3
        addChild(smokeEmitter)
    }

    /// Creates a small circular texture for smoke particles.
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
        meterValue = 0
        lastUpdateTime = 0

        configureIngredient()
        updateGreenZoneBand()
        drawZoneBands()
        updateMeterVisuals()

        roundLabel.text = "Round \(currentRound + 1)/\(totalRounds): \(ingredientNames[currentRound])"
        feedbackLabel.alpha = 0
        indicatorLine.alpha = 0
        instructionLabel.alpha = 1

        smokeEmitter.particleBirthRate = 0
        smokeEmitter.position = ingredientNode.position

        // Entrance animation for ingredient
        ingredientNode.setScale(0)
        ingredientNode.alpha = 1
        ingredientNode.run(.group([
            .scale(to: 1.0, duration: 0.35),
            .fadeAlpha(to: 1.0, duration: 0.35)
        ]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard roundState == .waiting else { return }
        roundState = .holding
        indicatorLine.alpha = 1
        instructionLabel.run(.fadeAlpha(to: 0.0, duration: 0.2))
        HapticManager.shared.light()
        AudioManager.shared.playSFX("sizzle")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard roundState == .holding else { return }
        roundState = .released
        evaluateAndShowFeedback()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard roundState == .holding else { return }
        roundState = .released
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

        guard roundState == .holding else { return }

        // Fill meter
        meterValue = min(1.0, meterValue + CGFloat(dt) * baseFillSpeed)

        updateMeterVisuals()
        updateIngredientChar()
        updateSmoke()

        // Auto-release if meter is full
        if meterValue >= 1.0 {
            roundState = .released
            evaluateAndShowFeedback()
        }
    }

    // MARK: - Meter Visuals

    private func updateMeterVisuals() {
        // Update mask height to reveal fill from bottom
        if let mask = meterFillCrop.maskNode as? SKSpriteNode {
            let fillH = meterValue * meterHeight
            mask.size = CGSize(width: meterWidth + 4, height: fillH)
        }

        // Color the fill bar based on current value
        let color = colorForMeterValue(meterValue)
        meterFill.fillColor = color

        // Move indicator line
        let meterBaseY = meterBackground.position.y
        indicatorLine.position = CGPoint(x: meterBackground.position.x,
                                         y: meterBaseY + meterValue * meterHeight)
    }

    private func colorForMeterValue(_ value: CGFloat) -> SKColor {
        let green = greenZone(for: currentRound)
        if value <= 0.25 {
            return SKColor(red: 0.45, green: 0.55, blue: 0.70, alpha: 1)    // raw (blue-gray)
        } else if value < green.lowerBound {
            return SKColor(red: 0.90, green: 0.80, blue: 0.25, alpha: 1)    // yellow low
        } else if value <= green.upperBound {
            return SKColor(red: 0.20, green: 0.85, blue: 0.35, alpha: 1)    // green
        } else if value <= 0.80 {
            return SKColor(red: 0.90, green: 0.80, blue: 0.25, alpha: 1)    // yellow high
        } else {
            return SKColor(red: 0.90, green: 0.25, blue: 0.20, alpha: 1)    // burned (red)
        }
    }

    // MARK: - Ingredient Charring

    private func updateIngredientChar() {
        // Darken the ingredient as the meter fills
        let darkness = meterValue * 0.7
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
            ? SKColor(red: 0.85, green: 0.78, blue: 0.60, alpha: 1)   // onion tan
            : SKColor(red: 0.85, green: 0.72, blue: 0.30, alpha: 1)   // ginger gold
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

    // MARK: - Smoke

    private func updateSmoke() {
        smokeEmitter.particleBirthRate = 5 + meterValue * 60
        smokeEmitter.position = ingredientNode.position
    }

    // MARK: - Evaluation

    private func evaluateAndShowFeedback() {
        let value = meterValue
        let green = greenZone(for: currentRound)
        let yellowLow = yellowZoneLow(for: currentRound)
        let yellowHigh = yellowZoneHigh(for: currentRound)

        let points: Int
        let text: String
        let color: SKColor

        if green.contains(value) {
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
        } else if yellowLow.contains(value) || yellowHigh.contains(value) {
            points = 2
            text = "Good"
            color = SKColor(red: 0.95, green: 0.85, blue: 0.25, alpha: 1)
            HapticManager.shared.medium()
        } else if value < yellowLow.lowerBound {
            points = 1
            text = "Too Raw!"
            color = SKColor(red: 0.5, green: 0.6, blue: 0.75, alpha: 1)
            HapticManager.shared.light()
        } else {
            points = 1
            text = "Burned!"
            color = SKColor(red: 0.95, green: 0.3, blue: 0.25, alpha: 1)
            HapticManager.shared.error()
            AudioManager.shared.playSFX("error-buzz")
        }

        totalPoints += points

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

        // Stop smoke growth
        smokeEmitter.particleBirthRate = max(smokeEmitter.particleBirthRate * 0.5, 2)

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
