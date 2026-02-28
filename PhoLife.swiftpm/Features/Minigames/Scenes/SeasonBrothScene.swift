import SpriteKit

class SeasonBrothScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Target Values

    private let targetFishSauce: CGFloat = 0.6
    private let targetSalt: CGFloat = 0.4
    private let targetSugar: CGFloat = 0.2

    // MARK: - Slider State

    private struct SliderData {
        let label: String
        var value: CGFloat
        let trackColor: SKColor
        var trackNode: SKShapeNode?
        var thumbNode: SKShapeNode?
        var labelNode: SKLabelNode?
        var valueLabel: SKLabelNode?
    }

    private var sliders: [SliderData] = []
    private var activeSliderIndex: Int? = nil

    // MARK: - Layout Constants

    private let trackWidth: CGFloat = 300
    private let trackHeight: CGFloat = 6
    private let thumbRadius: CGFloat = 12
    private let sliderStartY: CGFloat = 280
    private let sliderSpacing: CGFloat = 70

    // MARK: - Game State

    private var currentAttempt: Int = 0
    private let maxAttempts: Int = 1
    private var bestScore: Int = 0
    private var bestStars: Int = 1
    private var gameEnded: Bool = false
    // MARK: - Nodes

    private var brothBowlOuter: SKShapeNode!
    private var brothBowlFill: SKShapeNode!
    private var brothGlow: SKShapeNode!
    private var brothHighlight: SKShapeNode!
    private var harmonyArc: SKShapeNode!
    private var harmonyLabel: SKLabelNode!
    private var attemptLabel: SKLabelNode!
    private var tasteButton: SKShapeNode!
    private var tasteButtonLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1.0)

        setupBackground()
        setupBrothBowl()
        setupHarmonyMeter()
        setupSliders()
        setupTasteButton()
        setupHUD()
        updateBrothVisuals()
        updateHarmonyMeter()
        buildSteamWisps()
        addVignette()
        addAmbientParticles(color: SKColor(red: 1.0, green: 0.80, blue: 0.45, alpha: 1), birthRate: 1.0)

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
        // Warm kitchen gradient layers
        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height * 0.5))
        bottomGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottomGlow.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 0.6)
        bottomGlow.strokeColor = .clear
        bottomGlow.zPosition = -10
        addChild(bottomGlow)

        // Subtle warm glow at top
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.15))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.075)
        topGlow.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 0.12)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        addChild(topGlow)

        // Radial warm spotlight on the bowl area
        let spotlightGlow = SKShapeNode(circleOfRadius: 180)
        spotlightGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        spotlightGlow.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.08, alpha: 0.18)
        spotlightGlow.strokeColor = .clear
        spotlightGlow.zPosition = -9
        addChild(spotlightGlow)

        // Counter surface at bottom
        let counter = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: 80))
        counter.position = CGPoint(x: size.width / 2, y: 40)
        counter.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 1.0)
        counter.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.08, alpha: 0.6)
        counter.lineWidth = 1.5
        counter.zPosition = -5
        addChild(counter)
    }

    // MARK: - Broth Bowl

    private func setupBrothBowl() {
        let bowlCenterX = size.width / 2
        let bowlCenterY = size.height * 0.62
        let bowlRadius: CGFloat = 100

        // Shadow under the bowl
        let bowlShadow = SKShapeNode(ellipseOf: CGSize(width: bowlRadius * 2.3, height: bowlRadius * 0.7))
        bowlShadow.position = CGPoint(x: bowlCenterX + 3, y: bowlCenterY - bowlRadius * 0.55)
        bowlShadow.fillColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.35)
        bowlShadow.strokeColor = .clear
        bowlShadow.zPosition = -1
        addChild(bowlShadow)

        // Bowl glow (behind fill)
        brothGlow = SKShapeNode(circleOfRadius: bowlRadius + 25)
        brothGlow.position = CGPoint(x: bowlCenterX, y: bowlCenterY)
        brothGlow.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.12)
        brothGlow.strokeColor = .clear
        brothGlow.zPosition = 0
        addChild(brothGlow)

        // Outer bowl rim
        brothBowlOuter = SKShapeNode(circleOfRadius: bowlRadius + 8)
        brothBowlOuter.position = CGPoint(x: bowlCenterX, y: bowlCenterY)
        brothBowlOuter.fillColor = SKColor(red: 0.85, green: 0.80, blue: 0.72, alpha: 1.0)
        brothBowlOuter.strokeColor = SKColor(red: 0.70, green: 0.62, blue: 0.50, alpha: 1.0)
        brothBowlOuter.lineWidth = 2.5
        brothBowlOuter.zPosition = 1
        addChild(brothBowlOuter)

        // Inner broth fill
        brothBowlFill = SKShapeNode(circleOfRadius: bowlRadius)
        brothBowlFill.position = CGPoint(x: bowlCenterX, y: bowlCenterY)
        brothBowlFill.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        brothBowlFill.strokeColor = .clear
        brothBowlFill.zPosition = 2
        addChild(brothBowlFill)

        // Rim highlight (crescent at top for 3D effect)
        let rimHighlightPath = CGMutablePath()
        rimHighlightPath.addArc(center: .zero, radius: bowlRadius + 6,
                                startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: false)
        let rimHighlight = SKShapeNode(path: rimHighlightPath)
        rimHighlight.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        rimHighlight.lineWidth = 3
        rimHighlight.fillColor = .clear
        rimHighlight.lineCap = .round
        rimHighlight.position = CGPoint(x: bowlCenterX, y: bowlCenterY)
        rimHighlight.zPosition = 2.5
        addChild(rimHighlight)

        // Specular highlight on the broth surface
        brothHighlight = SKShapeNode(ellipseOf: CGSize(width: bowlRadius * 0.75, height: bowlRadius * 0.35))
        brothHighlight.position = CGPoint(x: bowlCenterX - 20, y: bowlCenterY + 30)
        brothHighlight.fillColor = SKColor(white: 1.0, alpha: 0.14)
        brothHighlight.strokeColor = .clear
        brothHighlight.zPosition = 3
        addChild(brothHighlight)

        // Secondary smaller highlight
        let highlight2 = SKShapeNode(ellipseOf: CGSize(width: bowlRadius * 0.3, height: bowlRadius * 0.15))
        highlight2.position = CGPoint(x: bowlCenterX + 30, y: bowlCenterY - 10)
        highlight2.fillColor = SKColor(white: 1.0, alpha: 0.07)
        highlight2.strokeColor = .clear
        highlight2.zPosition = 3
        addChild(highlight2)

        // Gentle horizontal sway on the specular highlight
        let sway = SKAction.repeatForever(.sequence([
            .moveBy(x: 8, y: 0, duration: 1.5),
            .moveBy(x: -8, y: 0, duration: 1.5)
        ]))
        sway.timingMode = .easeInEaseOut
        brothHighlight.run(sway)

        // Subtle broth surface shimmer
        let shimmer = SKAction.repeatForever(.sequence([
            .moveBy(x: -5, y: 2, duration: 2.0),
            .moveBy(x: 5, y: -2, duration: 2.0)
        ]))
        shimmer.timingMode = .easeInEaseOut
        highlight2.run(shimmer)
    }

    // MARK: - Harmony Meter

    private func setupHarmonyMeter() {
        let centerX = size.width / 2
        let arcCenterY = size.height * 0.62  // inside the bowl

        // The semicircular arc background
        let arcRadius: CGFloat = 45
        let bgArcPath = CGMutablePath()
        bgArcPath.addArc(center: .zero, radius: arcRadius,
                         startAngle: .pi, endAngle: 0, clockwise: false)
        let bgArc = SKShapeNode(path: bgArcPath)
        bgArc.position = CGPoint(x: centerX, y: arcCenterY)
        bgArc.strokeColor = SKColor(white: 0.3, alpha: 0.4)
        bgArc.lineWidth = 6
        bgArc.fillColor = .clear
        bgArc.lineCap = .round
        bgArc.zPosition = 5
        addChild(bgArc)

        // The colored harmony arc (overlaid)
        harmonyArc = SKShapeNode(path: bgArcPath)
        harmonyArc.position = CGPoint(x: centerX, y: arcCenterY)
        harmonyArc.strokeColor = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
        harmonyArc.lineWidth = 7
        harmonyArc.fillColor = .clear
        harmonyArc.lineCap = .round
        harmonyArc.glowWidth = 3
        harmonyArc.zPosition = 6
        addChild(harmonyArc)

        // "Balance" label
        harmonyLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        harmonyLabel.text = "Balance"
        harmonyLabel.fontSize = 14
        harmonyLabel.fontColor = SKColor(white: 1.0, alpha: 0.5)
        harmonyLabel.position = CGPoint(x: centerX, y: arcCenterY - 10)
        harmonyLabel.horizontalAlignmentMode = .center
        harmonyLabel.verticalAlignmentMode = .center
        harmonyLabel.zPosition = 7
        addChild(harmonyLabel)
    }

    private func updateHarmonyMeter() {
        let error = calculateError()
        // error range is roughly 0 to 2.0; normalize to 0..1 where 0 = perfect
        let normalizedError = min(error / 1.5, 1.0)
        let harmony = 1.0 - normalizedError  // 1.0 = perfect, 0.0 = terrible

        // Color: green for good, yellow for mid, red for bad
        let arcColor: SKColor
        if harmony > 0.75 {
            // Green
            arcColor = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
        } else if harmony > 0.5 {
            // Yellow-green blend
            let t = (harmony - 0.5) / 0.25
            arcColor = SKColor(red: 0.2 + (0.85 - 0.2) * (1.0 - t),
                               green: 0.85 - (0.85 - 0.75) * (1.0 - t),
                               blue: 0.3 - (0.3 - 0.15) * (1.0 - t),
                               alpha: 1.0)
        } else if harmony > 0.25 {
            // Yellow to orange
            let t = (harmony - 0.25) / 0.25
            arcColor = SKColor(red: 0.95 - 0.1 * t,
                               green: 0.5 + 0.25 * t,
                               blue: 0.1 + 0.05 * t,
                               alpha: 1.0)
        } else {
            // Red
            arcColor = SKColor(red: 0.95, green: 0.25, blue: 0.15, alpha: 1.0)
        }

        harmonyArc.strokeColor = arcColor

        // Redraw the arc to represent the harmony level
        let arcRadius: CGFloat = 45
        let sweepAngle = CGFloat.pi * harmony
        let arcPath = CGMutablePath()
        arcPath.addArc(center: .zero, radius: arcRadius,
                       startAngle: .pi, endAngle: .pi - sweepAngle, clockwise: true)

        harmonyArc.path = arcPath
    }

    // MARK: - Sliders

    private func setupSliders() {
        let centerX = size.width / 2

        let sliderConfigs: [(String, CGFloat, SKColor)] = [
            ("Fish Sauce", 0.5, SKColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1.0)),
            ("Salt",       0.5, SKColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0)),
            ("Sugar",      0.5, SKColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0))
        ]

        for (index, config) in sliderConfigs.enumerated() {
            let y = sliderStartY - CGFloat(index) * sliderSpacing

            // Track background
            let trackBG = SKShapeNode(rectOf: CGSize(width: trackWidth, height: trackHeight + 2),
                                      cornerRadius: (trackHeight + 2) / 2)
            trackBG.position = CGPoint(x: centerX + 30, y: y)
            trackBG.fillColor = SKColor(white: 0.12, alpha: 0.9)
            trackBG.strokeColor = SKColor(white: 0.22, alpha: 0.4)
            trackBG.lineWidth = 1
            trackBG.zPosition = 10
            addChild(trackBG)

            // Colored track fill
            let track = SKShapeNode(rectOf: CGSize(width: trackWidth, height: trackHeight),
                                    cornerRadius: trackHeight / 2)
            track.position = CGPoint(x: centerX + 30, y: y)
            track.fillColor = config.2.withAlphaComponent(0.35)
            track.strokeColor = .clear
            track.zPosition = 11
            addChild(track)

            // Thumb with inner highlight for depth
            let thumbX = centerX + 30 - trackWidth / 2 + trackWidth * config.1
            let thumb = SKShapeNode(circleOfRadius: thumbRadius)
            thumb.position = CGPoint(x: thumbX, y: y)
            thumb.fillColor = config.2
            thumb.strokeColor = SKColor(white: 1.0, alpha: 0.5)
            thumb.lineWidth = 2
            thumb.zPosition = 15
            thumb.glowWidth = 3
            thumb.name = "thumb_\(index)"
            addChild(thumb)

            // Inner highlight on thumb
            let thumbHighlight = SKShapeNode(circleOfRadius: thumbRadius * 0.5)
            thumbHighlight.fillColor = SKColor(white: 1.0, alpha: 0.20)
            thumbHighlight.strokeColor = .clear
            thumbHighlight.position = CGPoint(x: -2, y: 2)
            thumbHighlight.zPosition = 0.1
            thumb.addChild(thumbHighlight)

            // Label on the left
            let label = SKLabelNode(fontNamed: "SFProRounded-Bold")
            label.text = config.0
            label.fontSize = 18
            label.fontColor = config.2
            label.position = CGPoint(x: centerX + 30 - trackWidth / 2 - 70, y: y)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 10
            addChild(label)

            // Value label on the right
            let valueLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
            valueLabel.text = String(format: "%.0f%%", config.1 * 100)
            valueLabel.fontSize = 16
            valueLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
            valueLabel.position = CGPoint(x: centerX + 30 + trackWidth / 2 + 40, y: y)
            valueLabel.horizontalAlignmentMode = .center
            valueLabel.verticalAlignmentMode = .center
            valueLabel.zPosition = 10
            addChild(valueLabel)

            var data = SliderData(label: config.0,
                                  value: config.1,
                                  trackColor: config.2)
            data.trackNode = track
            data.thumbNode = thumb
            data.labelNode = label
            data.valueLabel = valueLabel

            sliders.append(data)
        }
    }

    // MARK: - Taste Button

    private func setupTasteButton() {
        let buttonCenterX = size.width / 2
        let buttonCenterY: CGFloat = 70

        let buttonWidth: CGFloat = 190
        let buttonHeight: CGFloat = 52

        // Button shadow
        let buttonShadow = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight),
                                        cornerRadius: buttonHeight / 2)
        buttonShadow.position = CGPoint(x: buttonCenterX + 2, y: buttonCenterY - 3)
        buttonShadow.fillColor = SKColor(red: 0.06, green: 0.03, blue: 0.01, alpha: 0.4)
        buttonShadow.strokeColor = .clear
        buttonShadow.zPosition = 19
        addChild(buttonShadow)

        tasteButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight),
                                  cornerRadius: buttonHeight / 2)
        tasteButton.position = CGPoint(x: buttonCenterX, y: buttonCenterY)
        tasteButton.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        tasteButton.strokeColor = SKColor(red: 0.95, green: 0.78, blue: 0.30, alpha: 1.0)
        tasteButton.lineWidth = 2
        tasteButton.zPosition = 20
        tasteButton.name = "tasteButton"
        tasteButton.glowWidth = 4
        addChild(tasteButton)

        // Inner highlight on button
        let btnHighlight = SKShapeNode(rectOf: CGSize(width: buttonWidth - 16, height: buttonHeight * 0.35),
                                        cornerRadius: 8)
        btnHighlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        btnHighlight.strokeColor = .clear
        btnHighlight.position = CGPoint(x: 0, y: buttonHeight * 0.12)
        btnHighlight.zPosition = 0.1
        tasteButton.addChild(btnHighlight)

        tasteButtonLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        tasteButtonLabel.text = "Taste"
        tasteButtonLabel.fontSize = 24
        tasteButtonLabel.fontColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 1.0)
        tasteButtonLabel.position = CGPoint(x: buttonCenterX, y: buttonCenterY)
        tasteButtonLabel.horizontalAlignmentMode = .center
        tasteButtonLabel.verticalAlignmentMode = .center
        tasteButtonLabel.zPosition = 21
        addChild(tasteButtonLabel)

        // Subtle breathing pulse on the button
        let breathe = SKAction.repeatForever(.sequence([
            .scale(to: 1.03, duration: 1.2),
            .scale(to: 1.0, duration: 1.2)
        ]))
        breathe.timingMode = .easeInEaseOut
        tasteButton.run(breathe)
    }

    // MARK: - HUD

    private func setupHUD() {
        // Title label below progress bar
        attemptLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        attemptLabel.text = "Season the Broth"
        attemptLabel.fontSize = 30
        attemptLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        attemptLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        attemptLabel.horizontalAlignmentMode = .center
        attemptLabel.verticalAlignmentMode = .center
        attemptLabel.zPosition = 100
        addChild(attemptLabel)

        // Instruction subtitle
        let instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Adjust the sliders to find the perfect balance"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.5)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height - 190)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        instructionLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))

        // Feedback label (hidden initially)
        feedbackLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        feedbackLabel.text = ""
        feedbackLabel.fontSize = 38
        feedbackLabel.fontColor = .white
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.44)
        feedbackLabel.horizontalAlignmentMode = .center
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.zPosition = 50
        feedbackLabel.alpha = 0
        addChild(feedbackLabel)

        // Score label (hidden initially)
        scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        scoreLabel.text = ""
        scoreLabel.fontSize = 26
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 50
        scoreLabel.alpha = 0
        addChild(scoreLabel)
    }

    // MARK: - Broth Visuals

    private func updateBrothVisuals() {
        let fish = sliders.isEmpty ? 0.5 : sliders[0].value
        let salt = sliders.isEmpty ? 0.5 : sliders[1].value
        let sugar = sliders.isEmpty ? 0.5 : sliders[2].value

        // Calculate the broth color based on slider values
        let brothColor = calculateBrothColor(fish: fish, salt: salt, sugar: sugar)
        brothBowlFill.fillColor = brothColor

        // Update the glow color to match with lower alpha
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        brothColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        brothGlow.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.2)
    }

    private func calculateBrothColor(fish: CGFloat, salt: CGFloat, sugar: CGFloat) -> SKColor {
        // Perfect balance: warm golden #DAA520 (0.855, 0.647, 0.125)
        // Too much fish sauce: dark amber (darker, browner)
        // Too much salt: harsh white/bright (washed out)
        // Too much sugar: orange/amber glow

        // Start from the golden base
        var baseR: CGFloat = 0.855
        var baseG: CGFloat = 0.647
        var baseB: CGFloat = 0.125

        // Fish sauce influence: excess darkens toward dark amber
        let fishExcess = max(0, fish - targetFishSauce)
        let fishDeficit = max(0, targetFishSauce - fish)
        // Excess fish sauce: darken significantly
        baseR -= fishExcess * 0.6
        baseG -= fishExcess * 0.5
        baseB -= fishExcess * 0.15
        // Deficit fish sauce: slightly lighter/more yellow
        baseR += fishDeficit * 0.1
        baseG += fishDeficit * 0.15
        baseB += fishDeficit * 0.1

        // Salt influence: excess brightens/washes out toward harsh white
        let saltExcess = max(0, salt - targetSalt)
        let saltDeficit = max(0, targetSalt - salt)
        // Excess salt: push toward white
        baseR += saltExcess * 0.3
        baseG += saltExcess * 0.4
        baseB += saltExcess * 0.6
        // Deficit salt: slightly duller
        baseR -= saltDeficit * 0.05
        baseG -= saltDeficit * 0.08
        baseB -= saltDeficit * 0.03

        // Sugar influence: excess shifts toward orange/amber
        let sugarExcess = max(0, sugar - targetSugar)
        let sugarDeficit = max(0, targetSugar - sugar)
        // Excess sugar: push toward orange
        baseR += sugarExcess * 0.15
        baseG -= sugarExcess * 0.1
        baseB -= sugarExcess * 0.1
        // Deficit sugar: slightly greener/duller
        baseG += sugarDeficit * 0.05
        baseB += sugarDeficit * 0.05

        // Clamp values
        baseR = min(max(baseR, 0.15), 1.0)
        baseG = min(max(baseG, 0.10), 1.0)
        baseB = min(max(baseB, 0.02), 0.95)

        return SKColor(red: baseR, green: baseG, blue: baseB, alpha: 1.0)
    }

    // MARK: - Scoring

    private func calculateError() -> CGFloat {
        let fish = sliders.isEmpty ? 0.5 : sliders[0].value
        let salt = sliders.isEmpty ? 0.5 : sliders[1].value
        let sugar = sliders.isEmpty ? 0.5 : sliders[2].value

        return abs(fish - targetFishSauce) + abs(salt - targetSalt) + abs(sugar - targetSugar)
    }

    private func scoreForError(_ error: CGFloat) -> Int {
        if error < 0.15 {
            return 100
        } else if error < 0.3 {
            return 75
        } else if error < 0.5 {
            return 50
        } else {
            return 25
        }
    }

    private func starsForScore(_ score: Int) -> Int {
        if score >= 100 {
            return 3
        } else if score >= 75 {
            return 2
        } else {
            return 1
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if a thumb was tapped
        for (index, slider) in sliders.enumerated() {
            guard let thumb = slider.thumbNode else { continue }
            let distance = hypot(location.x - thumb.position.x, location.y - thumb.position.y)
            if distance <= thumbRadius + 16 { // generous hit area
                activeSliderIndex = index
                // Visual feedback: enlarge thumb
                thumb.run(SKAction.scale(to: 1.3, duration: 0.1))
                HapticManager.shared.light()
                return
            }
        }

        // Check if taste button was tapped
        if let button = tasteButton, button.contains(location) {
            AudioManager.shared.playSFX("button-tap")
            handleTaste()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, let touch = touches.first, let index = activeSliderIndex else { return }
        let location = touch.location(in: self)

        let trackCenterX = size.width / 2 + 30
        let trackStartX = trackCenterX - trackWidth / 2
        let trackEndX = trackCenterX + trackWidth / 2

        // Clamp the thumb position to the track bounds
        let clampedX = min(max(location.x, trackStartX), trackEndX)

        // Update thumb position
        let y = sliderStartY - CGFloat(index) * sliderSpacing
        sliders[index].thumbNode?.position = CGPoint(x: clampedX, y: y)

        // Calculate new value (0...1)
        let newValue = (clampedX - trackStartX) / trackWidth
        sliders[index].value = min(max(newValue, 0), 1)

        // Update value label
        sliders[index].valueLabel?.text = String(format: "%.0f%%", sliders[index].value * 100)

        // Update visuals in real-time
        updateBrothVisuals()
        updateHarmonyMeter()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseActiveSlider()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseActiveSlider()
    }

    private func releaseActiveSlider() {
        if let index = activeSliderIndex {
            sliders[index].thumbNode?.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
        activeSliderIndex = nil
    }

    // MARK: - Taste (Submit Attempt)

    private func handleTaste() {
        guard !gameEnded else { return }

        currentAttempt += 1

        // Disable interaction during feedback
        let error = calculateError()
        let attemptScore = scoreForError(error)
        let attemptStars = starsForScore(attemptScore)

        // Track best score
        if attemptScore > bestScore {
            bestScore = attemptScore
            bestStars = attemptStars
        }

        // Haptic feedback
        if attemptScore >= 100 {
            HapticManager.shared.success()
            AudioManager.shared.playSFX("success-chime")
        } else if attemptScore >= 75 {
            HapticManager.shared.medium()
        } else {
            HapticManager.shared.light()
        }

        // Animate the button press
        tasteButton.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.06),
            SKAction.scale(to: 1.05, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.06)
        ]))

        // Visual effects based on score
        let bowlPos = brothBowlFill.position
        if attemptScore >= 100 {
            showFeedback(text: "Perfect Harmony!", color: SKColor(red: 0.2, green: 0.9, blue: 0.35, alpha: 1.0), score: attemptScore)
            burstParticles(at: bowlPos, count: 28, radius: 40...110)
            expandingRing(at: bowlPos, color: SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.6), targetScale: 5.0)
            flashOverlay(color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1), alpha: 0.12, duration: 0.3)
        } else if attemptScore >= 75 {
            burstParticles(at: bowlPos, count: 14, radius: 25...60)
        } else {
            shakeCamera(intensity: 4)
            flashOverlay(color: SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1), alpha: 0.08, duration: 0.2)
        }
        floatingScoreText("Score: \(attemptScore)", at: bowlPos)

        // Bowl pulse effect on taste
        brothBowlFill.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        // Glow pulse
        brothGlow.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.15),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        ]))

        // Single attempt — end the game
        gameEnded = true
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.finishGame()
            }
        ]))
    }

    private func showFeedback(text: String, color: SKColor, score: Int) {
        // Show feedback label with animation
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.alpha = 0
        feedbackLabel.setScale(0.5)
        feedbackLabel.run(SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))

        // Show score
        scoreLabel.text = "Score: \(score)"
        scoreLabel.alpha = 0
        scoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        ]))

        // Spawn celebratory particles for good scores
        if score >= 75 {
            spawnTasteParticles(good: score >= 100)
        }
    }

    private func spawnTasteParticles(good: Bool) {
        let bowlPos = brothBowlFill.position
        let particleCount = good ? 20 : 10

        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            if good {
                particle.fillColor = SKColor(
                    red: CGFloat.random(in: 0.9...1.0),
                    green: CGFloat.random(in: 0.7...0.9),
                    blue: CGFloat.random(in: 0.1...0.3),
                    alpha: 1.0
                )
            } else {
                particle.fillColor = SKColor(
                    red: CGFloat.random(in: 0.8...1.0),
                    green: CGFloat.random(in: 0.6...0.8),
                    blue: CGFloat.random(in: 0.2...0.4),
                    alpha: 1.0
                )
            }
            particle.strokeColor = .clear
            particle.position = bowlPos
            particle.zPosition = 40
            particle.glowWidth = 1.5
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...120)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.4...0.8)

            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: lifetime),
                    SKAction.fadeOut(withDuration: lifetime),
                    SKAction.scale(to: 0.1, duration: lifetime)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Reset for Next Attempt

    private func resetForNextAttempt() {
        // Fade out feedback
        feedbackLabel.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        scoreLabel.run(SKAction.fadeAlpha(to: 0, duration: 0.3))

        // Reset slider values to 0.5
        let trackCenterX = size.width / 2 + 30

        for index in 0..<sliders.count {
            sliders[index].value = 0.5

            let y = sliderStartY - CGFloat(index) * sliderSpacing
            let thumbX = trackCenterX

            sliders[index].thumbNode?.run(SKAction.move(to: CGPoint(x: thumbX, y: y), duration: 0.3))
            sliders[index].valueLabel?.text = "50%"
        }

        // Update attempt label
        attemptLabel.text = "Attempt \(currentAttempt + 1)/\(maxAttempts)"

        // Update visuals after a brief delay to let slider animation play
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                self?.updateBrothVisuals()
                self?.updateHarmonyMeter()
            }
        ]))
    }

    // MARK: - Finish Game

    private func finishGame() {
        // Fade out feedback labels
        feedbackLabel.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        scoreLabel.run(SKAction.fadeAlpha(to: 0, duration: 0.3))

        // Hide the taste button
        tasteButton.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        tasteButtonLabel.run(SKAction.fadeAlpha(to: 0, duration: 0.3))

        // Golden glow burst for completion
        let goldenBurst = SKShapeNode(circleOfRadius: 10)
        goldenBurst.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.40, alpha: 0.3)
        goldenBurst.strokeColor = .clear
        goldenBurst.position = CGPoint(x: size.width / 2, y: size.height / 2)
        goldenBurst.zPosition = 150
        addChild(goldenBurst)
        goldenBurst.run(.sequence([
            .scale(to: 30, duration: 0.6),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))

        // Completion sparkles
        for _ in 0..<15 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            sparkle.fillColor = SKColor(
                red: CGFloat.random(in: 0.90...1.0),
                green: CGFloat.random(in: 0.75...0.92),
                blue: CGFloat.random(in: 0.15...0.45),
                alpha: 1.0
            )
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 2
            sparkle.position = CGPoint(x: size.width / 2, y: size.height / 2)
            sparkle.zPosition = 160
            addChild(sparkle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 60...150)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.7),
                    .fadeOut(withDuration: 0.7),
                    .scale(to: 0.1, duration: 0.7)
                ]),
                .removeFromParent()
            ]))
        }

        // Final result display
        let finalLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        finalLabel.text = bestScore >= 100 ? "Master Seasoner!" : "Broth Seasoned!"
        finalLabel.fontSize = 44
        finalLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0)
        finalLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        finalLabel.horizontalAlignmentMode = .center
        finalLabel.verticalAlignmentMode = .center
        finalLabel.zPosition = 200
        finalLabel.alpha = 0
        finalLabel.setScale(0.5)
        addChild(finalLabel)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.scale(to: 1.2, duration: 0.3)
        ])
        appear.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        let hold = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.3)

        finalLabel.run(SKAction.sequence([appear, settle, hold, fadeOut, SKAction.removeFromParent()]))

        HapticManager.shared.success()

        // Report score after animations with exit curtain
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
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
                    .run { [weak self] in
                        guard let self = self else { return }
                        self.onComplete?(self.bestScore, self.bestStars)
                    }
                ]))
            }
        ]))
    }

    // MARK: - Steam Wisps

    private func buildSteamWisps() {
        let bowlPos = CGPoint(x: size.width / 2, y: size.height * 0.62)
        // More steam wisps with varied sizes for depth
        for i in 0..<7 {
            let radius = CGFloat.random(in: 8...20)
            let wisp = SKShapeNode(circleOfRadius: radius)
            wisp.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.04...0.08))
            wisp.strokeColor = .clear
            wisp.position = CGPoint(
                x: bowlPos.x + CGFloat.random(in: -55...55),
                y: bowlPos.y + 60 + CGFloat(i) * 18
            )
            wisp.zPosition = 5
            addChild(wisp)

            let driftDuration = 2.0 + Double(i) * 0.25 + Double.random(in: -0.3...0.3)
            let drift = SKAction.repeatForever(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 40...70), duration: driftDuration),
                    .fadeAlpha(to: 0.0, duration: driftDuration),
                    .scale(to: 1.5, duration: driftDuration)
                ]),
                .run {
                    wisp.position = CGPoint(
                        x: bowlPos.x + CGFloat.random(in: -55...55),
                        y: bowlPos.y + 55 + CGFloat.random(in: 0...15)
                    )
                    wisp.alpha = CGFloat.random(in: 0.04...0.09)
                    wisp.setScale(1.0)
                }
            ]))
            wisp.run(.sequence([
                .wait(forDuration: Double(i) * 0.3),
                drift
            ]))
        }
    }
}
