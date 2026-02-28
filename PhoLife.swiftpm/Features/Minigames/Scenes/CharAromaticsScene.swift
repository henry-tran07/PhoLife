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
    private var timingBarFill: SKShapeNode!
    private var targetZoneNode: SKShapeNode!
    private var targetZoneGlow: SKShapeNode!
    private var cursorNode: SKShapeNode!
    private var cursorGlow: SKShapeNode!
    private var cursorTrail: SKEmitterNode!

    // Visual polish nodes
    private var vignetteNode: SKShapeNode!
    private var ambientEmitter: SKEmitterNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1)

        buildBackground()
        buildSkillet()
        buildIngredient()
        buildTimingBar()
        buildLabels()
        buildSmoke()
        buildHeatShimmer()
        buildAmbientParticles()

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

    // MARK: - Background

    private func buildBackground() {
        // Warm gradient floor
        let floorGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.5))
        floorGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        floorGlow.fillColor = SKColor(red: 0.18, green: 0.10, blue: 0.04, alpha: 0.4)
        floorGlow.strokeColor = .clear
        floorGlow.zPosition = -10
        addChild(floorGlow)

        // Warm central glow under the skillet
        let centerGlow = SKShapeNode(circleOfRadius: 250)
        centerGlow.position = CGPoint(x: size.width * 0.45, y: size.height * 0.38)
        centerGlow.fillColor = SKColor(red: 0.35, green: 0.15, blue: 0.04, alpha: 0.12)
        centerGlow.strokeColor = .clear
        centerGlow.zPosition = -8
        addChild(centerGlow)

        // Subtle vignette overlay using darkened edges
        let vignetteSize = max(size.width, size.height) * 1.2
        vignetteNode = SKShapeNode(circleOfRadius: vignetteSize / 2)
        vignetteNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignetteNode.fillColor = .clear
        vignetteNode.strokeColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.5)
        vignetteNode.lineWidth = vignetteSize * 0.25
        vignetteNode.zPosition = -1
        addChild(vignetteNode)
    }

    // MARK: - Build Nodes

    private func buildSkillet() {
        let skilletRadius: CGFloat = 160

        // Subtle drop shadow under skillet
        let shadow = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.5,
                                                     height: skilletRadius * 1.2))
        shadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width * 0.45 + 4, y: size.height * 0.38 - 8)
        shadow.zPosition = 0.5
        addChild(shadow)

        skilletNode = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.4,
                                                     height: skilletRadius * 1.4))
        skilletNode.fillColor = SKColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        skilletNode.strokeColor = SKColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1)
        skilletNode.lineWidth = 4
        skilletNode.position = CGPoint(x: size.width * 0.45, y: size.height * 0.38)
        skilletNode.zPosition = 1
        addChild(skilletNode)

        // Inner surface sheen
        let innerSheen = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.0,
                                                         height: skilletRadius * 1.1))
        innerSheen.fillColor = SKColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 0.6)
        innerSheen.strokeColor = .clear
        innerSheen.zPosition = 0.1
        skilletNode.addChild(innerSheen)

        // Highlight arc on skillet rim
        let highlightArc = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.2,
                                                           height: skilletRadius * 1.25))
        highlightArc.fillColor = .clear
        highlightArc.strokeColor = SKColor(white: 1.0, alpha: 0.06)
        highlightArc.lineWidth = 2
        highlightArc.zPosition = 0.2
        skilletNode.addChild(highlightArc)

        // Handle with gradient feel
        let handle = SKShapeNode(rect: CGRect(x: 0, y: -12, width: 120, height: 24),
                                 cornerRadius: 8)
        handle.fillColor = SKColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1)
        handle.strokeColor = SKColor(red: 0.30, green: 0.25, blue: 0.18, alpha: 1)
        handle.lineWidth = 2
        handle.position = CGPoint(x: skilletRadius * 1.2, y: 0)
        handle.zPosition = 0
        skilletNode.addChild(handle)

        // Handle rivet details
        for offsetX in [20, 100] as [CGFloat] {
            let rivet = SKShapeNode(circleOfRadius: 4)
            rivet.fillColor = SKColor(red: 0.30, green: 0.27, blue: 0.22, alpha: 1)
            rivet.strokeColor = SKColor(white: 0.4, alpha: 0.3)
            rivet.lineWidth = 1
            rivet.position = CGPoint(x: skilletRadius * 1.2 + offsetX, y: 0)
            rivet.zPosition = 0.3
            skilletNode.addChild(rivet)
        }

        // Heat glow under skillet
        let heatGlow = SKShapeNode(ellipseOf: CGSize(width: skilletRadius * 2.6,
                                                       height: skilletRadius * 0.8))
        heatGlow.fillColor = SKColor(red: 0.85, green: 0.35, blue: 0.05, alpha: 0.06)
        heatGlow.strokeColor = .clear
        heatGlow.position = CGPoint(x: size.width * 0.45, y: size.height * 0.38 - skilletRadius * 0.5)
        heatGlow.zPosition = 0.8
        addChild(heatGlow)
        heatGlow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.10, duration: 1.2),
            .fadeAlpha(to: 0.04, duration: 1.2)
        ])))
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

            // Add concentric ring detail with improved colors
            ingredientNode.removeAllChildren()
            for i in 1...3 {
                let ringRadius = CGFloat(i) * 15
                let ring = SKShapeNode(circleOfRadius: ringRadius)
                ring.fillColor = .clear
                ring.strokeColor = SKColor(red: 0.75, green: 0.68, blue: 0.50, alpha: 0.4)
                ring.lineWidth = 1.5
                ingredientNode.addChild(ring)
            }

            // Subtle center dot for onion core
            let core = SKShapeNode(circleOfRadius: 5)
            core.fillColor = SKColor(red: 0.90, green: 0.85, blue: 0.65, alpha: 0.8)
            core.strokeColor = .clear
            ingredientNode.addChild(core)

            // Highlight for 3D effect
            let highlight = SKShapeNode(ellipseOf: CGSize(width: radius * 0.8, height: radius * 0.5))
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.08)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -radius * 0.15, y: radius * 0.2)
            ingredientNode.addChild(highlight)
        } else {
            let rect = CGRect(x: -60, y: -22, width: 120, height: 44)
            let path = CGMutablePath()
            path.addRoundedRect(in: rect, cornerWidth: 10, cornerHeight: 10)
            ingredientNode.path = path
            ingredientNode.fillColor = SKColor(red: 0.85, green: 0.72, blue: 0.30, alpha: 1)
            ingredientNode.strokeColor = SKColor(red: 0.72, green: 0.58, blue: 0.22, alpha: 1)
            ingredientNode.lineWidth = 3
            ingredientNode.removeAllChildren()

            // Ginger texture lines
            for i in 0..<4 {
                let line = SKShapeNode(rectOf: CGSize(width: 2, height: 30))
                line.fillColor = SKColor(red: 0.78, green: 0.65, blue: 0.25, alpha: 0.3)
                line.strokeColor = .clear
                line.position = CGPoint(x: -30 + CGFloat(i) * 20, y: 0)
                ingredientNode.addChild(line)
            }

            // Highlight for 3D effect
            let highlight = SKShapeNode(rect: CGRect(x: -50, y: 4, width: 100, height: 12), cornerRadius: 6)
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.06)
            highlight.strokeColor = .clear
            ingredientNode.addChild(highlight)
        }

        ingredientNode.position = CGPoint(x: skilletPos.x, y: skilletPos.y + 5)
    }

    // MARK: - Timing Bar

    private func buildTimingBar() {
        let barX = size.width * 0.45
        let barY = size.height * 0.12

        // Subtle shadow under bar
        let barShadow = SKShapeNode(rectOf: CGSize(width: barWidth + 8, height: barHeight + 8),
                                     cornerRadius: (barHeight + 8) / 2)
        barShadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        barShadow.strokeColor = .clear
        barShadow.position = CGPoint(x: barX + 2, y: barY - 2)
        barShadow.zPosition = 9.5
        addChild(barShadow)

        // Dark background bar with improved styling
        timingBarBG = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                                  cornerRadius: barHeight / 2)
        timingBarBG.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
        timingBarBG.strokeColor = SKColor(white: 0.25, alpha: 0.8)
        timingBarBG.lineWidth = 2
        timingBarBG.position = CGPoint(x: barX, y: barY)
        timingBarBG.zPosition = 10
        addChild(timingBarBG)

        // Subtle inner bar fill (dark gradient simulation)
        timingBarFill = SKShapeNode(rectOf: CGSize(width: barWidth - 6, height: barHeight - 6),
                                     cornerRadius: (barHeight - 6) / 2)
        timingBarFill.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.06, alpha: 1)
        timingBarFill.strokeColor = .clear
        timingBarFill.position = CGPoint(x: barX, y: barY)
        timingBarFill.zPosition = 10.2
        addChild(timingBarFill)

        // Tick marks on the bar for visual polish
        for i in 1..<10 {
            let tickX = barX - barWidth / 2 + CGFloat(i) * (barWidth / 10)
            let tick = SKShapeNode(rectOf: CGSize(width: 1, height: barHeight * 0.4))
            tick.fillColor = SKColor(white: 0.2, alpha: 0.3)
            tick.strokeColor = .clear
            tick.position = CGPoint(x: tickX, y: barY)
            tick.zPosition = 10.3
            addChild(tick)
        }

        // Target zone glow (softer, behind the zone)
        targetZoneGlow = SKShapeNode()
        targetZoneGlow.fillColor = SKColor(red: 0.95, green: 0.45, blue: 0.1, alpha: 0.15)
        targetZoneGlow.strokeColor = .clear
        targetZoneGlow.zPosition = 10.5
        targetZoneGlow.position = CGPoint(x: barX, y: barY)
        addChild(targetZoneGlow)

        // Warm amber target zone (positioned each round)
        targetZoneNode = SKShapeNode()
        targetZoneNode.fillColor = SKColor(red: 0.95, green: 0.55, blue: 0.12, alpha: 1.0)
        targetZoneNode.strokeColor = SKColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 0.8)
        targetZoneNode.lineWidth = 1.5
        targetZoneNode.zPosition = 11
        targetZoneNode.position = CGPoint(x: barX, y: barY)
        addChild(targetZoneNode)

        // Pulsing glow on target zone
        targetZoneNode.run(.repeatForever(.sequence([
            .run { [weak self] in self?.targetZoneNode.glowWidth = 4 },
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.targetZoneNode.glowWidth = 1.5 },
            .wait(forDuration: 0.5)
        ])))

        // Cursor glow (behind cursor)
        cursorGlow = SKShapeNode(rectOf: CGSize(width: 14, height: barHeight + 16),
                                  cornerRadius: 7)
        cursorGlow.fillColor = SKColor(white: 1.0, alpha: 0.15)
        cursorGlow.strokeColor = .clear
        cursorGlow.zPosition = 11.5
        cursorGlow.position = CGPoint(x: barX - barWidth / 2, y: barY)
        addChild(cursorGlow)

        // White cursor bar with improved styling
        cursorNode = SKShapeNode(rectOf: CGSize(width: 6, height: barHeight + 10),
                                 cornerRadius: 3)
        cursorNode.fillColor = .white
        cursorNode.strokeColor = .clear
        cursorNode.glowWidth = 4
        cursorNode.zPosition = 12
        cursorNode.position = CGPoint(x: barX - barWidth / 2, y: barY)
        addChild(cursorNode)

        // Cursor trail emitter
        cursorTrail = SKEmitterNode()
        cursorTrail.particleTexture = createSmokeTexture()
        cursorTrail.particleBirthRate = 20
        cursorTrail.particleLifetime = 0.3
        cursorTrail.particleLifetimeRange = 0.1
        cursorTrail.particleSpeed = 0
        cursorTrail.particleScale = 0.08
        cursorTrail.particleScaleSpeed = -0.15
        cursorTrail.particleAlpha = 0.4
        cursorTrail.particleAlphaSpeed = -1.2
        cursorTrail.particleColor = .white
        cursorTrail.particleColorBlendFactor = 1.0
        cursorTrail.position = cursorNode.position
        cursorTrail.zPosition = 11.8
        cursorTrail.targetNode = self
        addChild(cursorTrail)
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

        // Update glow behind zone
        let glowRect = zoneRect.insetBy(dx: -6, dy: -6)
        targetZoneGlow.path = CGPath(roundedRect: glowRect, cornerWidth: 6,
                                      cornerHeight: 6, transform: nil)
        targetZoneGlow.position = CGPoint(x: zoneX, y: timingBarBG.position.y)

        // Reset cursor
        cursorPosition = 0
        cursorDirection = 1
        updateCursorPosition()
    }

    private func updateCursorPosition() {
        let barLeftX = timingBarBG.position.x - barWidth / 2
        let xPos = barLeftX + cursorPosition * barWidth
        let yPos = timingBarBG.position.y
        cursorNode.position = CGPoint(x: xPos, y: yPos)
        cursorGlow.position = CGPoint(x: xPos, y: yPos)
        cursorTrail.position = CGPoint(x: xPos, y: yPos)

        // Color cursor when it's in the target zone
        if cursorPosition >= targetStart && cursorPosition <= targetEnd {
            cursorNode.fillColor = SKColor(red: 1.0, green: 0.92, blue: 0.7, alpha: 1)
            cursorGlow.fillColor = SKColor(red: 0.95, green: 0.55, blue: 0.12, alpha: 0.25)
            cursorTrail.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1)
        } else {
            cursorNode.fillColor = .white
            cursorGlow.fillColor = SKColor(white: 1.0, alpha: 0.12)
            cursorTrail.particleColor = SKColor(white: 1.0, alpha: 0.5)
        }
    }

    private func buildLabels() {
        roundLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .bold))
        roundLabel.fontSize = 28
        roundLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1)
        roundLabel.position = CGPoint(x: size.width * 0.45, y: size.height - 160)
        roundLabel.horizontalAlignmentMode = .center
        roundLabel.verticalAlignmentMode = .center
        roundLabel.zPosition = 10
        addChild(roundLabel)

        feedbackLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .heavy))
        feedbackLabel.fontSize = 52
        feedbackLabel.fontColor = .white
        feedbackLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.62)
        feedbackLabel.horizontalAlignmentMode = .center
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.zPosition = 15
        feedbackLabel.alpha = 0
        addChild(feedbackLabel)

        instructionLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .medium))
        instructionLabel.fontSize = 22
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.55)
        instructionLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.22)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 10
        instructionLabel.text = "Tap when the cursor hits the golden zone!"
        addChild(instructionLabel)
    }

    private func buildSmoke() {
        smokeEmitter = SKEmitterNode()
        smokeEmitter.particleBirthRate = 0
        smokeEmitter.particleLifetime = 2.5
        smokeEmitter.particleLifetimeRange = 0.8
        smokeEmitter.particleColor = SKColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1)
        smokeEmitter.particleColorBlendFactor = 1.0
        smokeEmitter.particleColorAlphaSpeed = -0.4
        smokeEmitter.particleSpeed = 35
        smokeEmitter.particleSpeedRange = 18
        smokeEmitter.emissionAngle = .pi / 2
        smokeEmitter.emissionAngleRange = .pi / 5
        smokeEmitter.particleScale = 0.25
        smokeEmitter.particleScaleSpeed = 0.18
        smokeEmitter.particleScaleRange = 0.1
        smokeEmitter.particleAlpha = 0.45
        smokeEmitter.particleAlphaSpeed = -0.18
        smokeEmitter.particleTexture = createSmokeTexture()
        smokeEmitter.particlePositionRange = CGVector(dx: 60, dy: 10)
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
        for i in 0..<5 {
            let shimmer = SKShapeNode(rectOf: CGSize(width: 60 + CGFloat(i) * 25, height: 1.5))
            shimmer.fillColor = SKColor(white: 1.0, alpha: 0.025)
            shimmer.strokeColor = .clear
            shimmer.position = CGPoint(x: skilletPos.x + CGFloat.random(in: -40...40),
                                       y: skilletPos.y + 70 + CGFloat(i) * 22)
            shimmer.zPosition = 1.5
            shimmer.alpha = CGFloat.random(in: 0.3...1.0)
            addChild(shimmer)
            let wobble = SKAction.repeatForever(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18), y: 8, duration: 1.5 + Double(i) * 0.25),
                    .fadeAlpha(to: CGFloat.random(in: 0.2...0.8), duration: 1.5 + Double(i) * 0.25)
                ]),
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18), y: -8, duration: 1.5 + Double(i) * 0.25),
                    .fadeAlpha(to: CGFloat.random(in: 0.4...1.0), duration: 1.5 + Double(i) * 0.25)
                ])
            ]))
            shimmer.run(wobble)
        }
    }

    // MARK: - Ambient Particles

    private func buildAmbientParticles() {
        ambientEmitter = SKEmitterNode()
        ambientEmitter.particleTexture = createSmokeTexture()
        ambientEmitter.particleBirthRate = 1.5
        ambientEmitter.particleLifetime = 5.0
        ambientEmitter.particleLifetimeRange = 2.0
        ambientEmitter.particleSpeed = 8
        ambientEmitter.particleSpeedRange = 5
        ambientEmitter.emissionAngle = .pi / 2
        ambientEmitter.emissionAngleRange = .pi
        ambientEmitter.particleScale = 0.15
        ambientEmitter.particleScaleSpeed = 0.03
        ambientEmitter.particleAlpha = 0.06
        ambientEmitter.particleAlphaSpeed = -0.012
        ambientEmitter.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1)
        ambientEmitter.particleColorBlendFactor = 1.0
        ambientEmitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: size.height * 0.4)
        ambientEmitter.position = CGPoint(x: size.width * 0.45, y: size.height * 0.45)
        ambientEmitter.zPosition = 0.5
        addChild(ambientEmitter)
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

        // Entrance animation for ingredient with spring feel
        ingredientNode.setScale(0)
        ingredientNode.alpha = 1
        ingredientNode.run(.sequence([
            .group([
                .scale(to: 1.08, duration: 0.25),
                .fadeAlpha(to: 1.0, duration: 0.25)
            ]),
            .scale(to: 1.0, duration: 0.12)
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
            // Inside the target zone
            points = 3
            text = "Perfect Char!"
            color = SKColor(red: 0.3, green: 0.95, blue: 0.45, alpha: 1)
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

            // Golden particle burst for perfect
            spawnPerfectBurst(at: ingredientNode.position)

            // Screen flash for perfect hit
            let flashOverlay = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
            flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
            flashOverlay.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.12)
            flashOverlay.strokeColor = .clear
            flashOverlay.zPosition = 90
            addChild(flashOverlay)
            flashOverlay.run(.sequence([.fadeAlpha(to: 0, duration: 0.3), .removeFromParent()]))

        } else if distance <= goodThreshold {
            points = 2
            text = "Good"
            color = SKColor(red: 0.95, green: 0.85, blue: 0.25, alpha: 1)
            HapticManager.shared.medium()

            // Smaller warm burst for good
            spawnGoodBurst(at: ingredientNode.position)
        } else {
            points = 1
            text = "Missed!"
            color = SKColor(red: 0.95, green: 0.3, blue: 0.25, alpha: 1)
            HapticManager.shared.error()
            AudioManager.shared.playSFX("error-buzz")
            shakeCamera(intensity: 5)

            // Red flash overlay for miss
            let flashOverlay = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
            flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
            flashOverlay.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.1)
            flashOverlay.strokeColor = .clear
            flashOverlay.zPosition = 90
            addChild(flashOverlay)
            flashOverlay.run(.sequence([.fadeAlpha(to: 0, duration: 0.25), .removeFromParent()]))
        }

        totalPoints += points
        applyCharEffect(quality: points)

        // Show feedback with improved animation
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.alpha = 0
        feedbackLabel.setScale(0.3)
        feedbackLabel.run(.sequence([
            .group([
                .fadeAlpha(to: 1.0, duration: 0.12),
                .scale(to: 1.1, duration: 0.15)
            ]),
            .scale(to: 1.0, duration: 0.08)
        ]))

        // Flash the ingredient with a warm pulse
        ingredientNode.run(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.08),
            .fadeAlpha(to: 1.0, duration: 0.12)
        ]))

        // Flash cursor with result color
        cursorNode.run(.sequence([
            .run { [weak self] in self?.cursorNode.fillColor = color },
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.cursorNode.fillColor = .white }
        ]))

        // Increase smoke on hit
        smokeEmitter.particleBirthRate = 35
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in self?.smokeEmitter.particleBirthRate = 5 }
        ]))

        // Points label with improved animation
        let pointsLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .bold))
        pointsLabel.text = "+\(points)"
        pointsLabel.fontSize = 36
        pointsLabel.fontColor = color
        pointsLabel.position = CGPoint(x: feedbackLabel.position.x,
                                       y: feedbackLabel.position.y - 50)
        pointsLabel.zPosition = 15
        pointsLabel.alpha = 0
        pointsLabel.setScale(0.5)
        addChild(pointsLabel)
        pointsLabel.run(.sequence([
            .group([
                .fadeAlpha(to: 1.0, duration: 0.12),
                .scale(to: 1.2, duration: 0.15),
                .moveBy(x: 0, y: 10, duration: 0.15)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.08),
                .moveBy(x: 0, y: 25, duration: 0.7)
            ]),
            .fadeAlpha(to: 0.0, duration: 0.25),
            .removeFromParent()
        ]))

        // Advance round after delay
        roundState = .transitioning
        run(.sequence([
            .wait(forDuration: 1.4),
            .run { [weak self] in self?.advanceRound() }
        ]))
    }

    // MARK: - Particle Burst Effects

    private func spawnPerfectBurst(at position: CGPoint) {
        let particleCount = 28
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            particle.fillColor = SKColor(
                red: CGFloat.random(in: 0.9...1.0),
                green: CGFloat.random(in: 0.7...0.9),
                blue: CGFloat.random(in: 0.1...0.35),
                alpha: 1.0
            )
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 85
            particle.glowWidth = 2
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...110)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.35...0.65)

            particle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: lifetime),
                    .fadeOut(withDuration: lifetime),
                    .scale(to: 0.1, duration: lifetime)
                ]),
                .removeFromParent()
            ]))
        }

        // Central expanding ring
        let ring = SKShapeNode(circleOfRadius: 15)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.7)
        ring.lineWidth = 3
        ring.position = position
        ring.zPosition = 84
        addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 5.0, duration: 0.4),
                .fadeOut(withDuration: 0.4)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnGoodBurst(at position: CGPoint) {
        let particleCount = 14
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = SKColor(
                red: CGFloat.random(in: 0.85...1.0),
                green: CGFloat.random(in: 0.75...0.9),
                blue: CGFloat.random(in: 0.15...0.3),
                alpha: 1.0
            )
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 85
            particle.glowWidth = 1.5
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 25...60)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.25...0.5)

            particle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: lifetime),
                    .fadeOut(withDuration: lifetime),
                    .scale(to: 0.1, duration: lifetime)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func advanceRound() {
        currentRound += 1

        if currentRound >= totalRounds {
            finishGame()
        } else {
            // Fade out then configure next round with smoother transition
            let fadeOut = SKAction.group([
                SKAction.run { [weak self] in
                    self?.ingredientNode.run(.group([
                        .fadeAlpha(to: 0, duration: 0.3),
                        .scale(to: 0.8, duration: 0.3)
                    ]))
                    self?.feedbackLabel.run(.fadeAlpha(to: 0, duration: 0.25))
                    self?.smokeEmitter.particleBirthRate = 0
                }
            ])

            run(.sequence([
                fadeOut,
                .wait(forDuration: 0.4),
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
        if totalPoints >= 6 {
            stars = 3
        } else if totalPoints >= 4 {
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
