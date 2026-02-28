import SpriteKit

class ToastSpicesScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Spice Data

    struct SpiceData {
        let name: String
        let symbol: String
        let isCorrect: Bool
    }

    static let allSpices: [SpiceData] = [
        SpiceData(name: "Star Anise", symbol: "★", isCorrect: true),
        SpiceData(name: "Cinnamon", symbol: "C", isCorrect: true),
        SpiceData(name: "Cardamom", symbol: "K", isCorrect: true),
        SpiceData(name: "Cloves", symbol: "L", isCorrect: true),
        SpiceData(name: "Coriander", symbol: "●", isCorrect: true),
        SpiceData(name: "Paprika", symbol: "P", isCorrect: false),
        SpiceData(name: "Cumin", symbol: "U", isCorrect: false),
        SpiceData(name: "Turmeric", symbol: "T", isCorrect: false),
        SpiceData(name: "Oregano", symbol: "G", isCorrect: false),
        SpiceData(name: "Black Pepper", symbol: "B", isCorrect: false),
    ]

    static let correctSpices: [SpiceData] = allSpices.filter { $0.isCorrect }
    static let decoySpices: [SpiceData] = allSpices.filter { !$0.isCorrect }

    // MARK: - Constants

    private let gameDuration: TimeInterval = 40.0
    // Wrong catches deduct points but don't end the game

    private let spiceRadius: CGFloat = 20.0
    private let spiceDiameter: CGFloat = 40.0
    private let swipeHitRadius: CGFloat = 30.0
    private let spiceNodeName = "spice"

    // MARK: - Game State

    private var comboCount = 0
    private var score: Int = 0
    private var correctCatches: Int = 0
    private var wrongCatches: Int = 0
    private var totalCorrectSpawned: Int = 0
    private var timeRemaining: TimeInterval = 40.0
    private var gameActive: Bool = false
    private var elapsedTime: TimeInterval = 0.0
    private var lastSpawnTime: TimeInterval = 0.0
    private var lastUpdateTime: TimeInterval = 0.0

    // MARK: - HUD Nodes

    private var scoreLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!

    // MARK: - Swipe Tracking

    private var swipePath: CGMutablePath?
    private var swipeTrailNode: SKShapeNode?
    private var swipeParticleTrail: SKEmitterNode?
    private var caughtSpiceIDs: Set<ObjectIdentifier> = []

    // MARK: - Ambient

    private var ambientDustEmitter: SKEmitterNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 1.0)

        setupBackground()
        setupPan()
        setupAmbientParticles()
        setupHUD()

        startGame()

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
        // Deep warm background gradient layers
        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.45))
        bottomGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.225)
        bottomGlow.fillColor = SKColor(red: 0.22, green: 0.12, blue: 0.05, alpha: 0.5)
        bottomGlow.strokeColor = .clear
        bottomGlow.zPosition = -10
        addChild(bottomGlow)

        // Subtle counter / surface at bottom
        let counter = SKShapeNode(rectOf: CGSize(width: size.width, height: 70))
        counter.position = CGPoint(x: size.width / 2, y: 35)
        counter.fillColor = SKColor(red: 0.18, green: 0.11, blue: 0.05, alpha: 1.0)
        counter.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.08, alpha: 0.6)
        counter.lineWidth = 1.5
        counter.zPosition = -5
        addChild(counter)

        // Counter edge highlight
        let counterHighlight = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        counterHighlight.position = CGPoint(x: size.width / 2, y: 70)
        counterHighlight.fillColor = SKColor(red: 0.40, green: 0.25, blue: 0.12, alpha: 0.3)
        counterHighlight.strokeColor = .clear
        counterHighlight.zPosition = -4
        addChild(counterHighlight)

        // Warm ambient glow at top
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.18))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.09)
        topGlow.fillColor = SKColor(red: 0.35, green: 0.20, blue: 0.08, alpha: 0.12)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        addChild(topGlow)

        // Central warm radial glow
        let centerGlow = SKShapeNode(circleOfRadius: 300)
        centerGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        centerGlow.fillColor = SKColor(red: 0.40, green: 0.18, blue: 0.05, alpha: 0.08)
        centerGlow.strokeColor = .clear
        centerGlow.zPosition = -9
        addChild(centerGlow)

        // Vignette ring for edge darkening
        let vignetteSize = max(size.width, size.height) * 1.2
        let vignette = SKShapeNode(circleOfRadius: vignetteSize / 2)
        vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.45)
        vignette.lineWidth = vignetteSize * 0.22
        vignette.zPosition = -1
        addChild(vignette)
    }

    // MARK: - Pan

    private func setupPan() {
        // Pan shadow
        let panShadow = SKShapeNode(ellipseOf: CGSize(width: 310, height: 90))
        panShadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        panShadow.strokeColor = .clear
        panShadow.position = CGPoint(x: size.width / 2 + 3, y: 25)
        panShadow.zPosition = 0.5
        addChild(panShadow)

        // Toasting pan at bottom
        let pan = SKShapeNode(ellipseOf: CGSize(width: 300, height: 100))
        pan.fillColor = SKColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        pan.strokeColor = SKColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1)
        pan.lineWidth = 3
        pan.position = CGPoint(x: size.width / 2, y: 30)
        pan.zPosition = 1
        addChild(pan)

        // Pan inner surface
        let panInner = SKShapeNode(ellipseOf: CGSize(width: 260, height: 80))
        panInner.fillColor = SKColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 0.7)
        panInner.strokeColor = .clear
        panInner.position = CGPoint(x: 0, y: 0)
        panInner.zPosition = 0.1
        pan.addChild(panInner)

        // Pan highlight
        let panHighlight = SKShapeNode(ellipseOf: CGSize(width: 200, height: 40))
        panHighlight.fillColor = SKColor(white: 1.0, alpha: 0.03)
        panHighlight.strokeColor = .clear
        panHighlight.position = CGPoint(x: -20, y: 15)
        panHighlight.zPosition = 0.2
        pan.addChild(panHighlight)

        // Pan heat glow
        let heatGlow = SKShapeNode(ellipseOf: CGSize(width: 280, height: 70))
        heatGlow.fillColor = SKColor(red: 0.85, green: 0.35, blue: 0.05, alpha: 0.06)
        heatGlow.strokeColor = .clear
        heatGlow.position = CGPoint(x: size.width / 2, y: 20)
        heatGlow.zPosition = 0.8
        addChild(heatGlow)
        heatGlow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.10, duration: 1.0),
            .fadeAlpha(to: 0.04, duration: 1.0)
        ])))

        // Add pan handle with rivet detail
        let handle = SKShapeNode(rectOf: CGSize(width: 110, height: 18), cornerRadius: 9)
        handle.fillColor = SKColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1)
        handle.strokeColor = SKColor(red: 0.30, green: 0.25, blue: 0.18, alpha: 0.8)
        handle.lineWidth = 1.5
        handle.position = CGPoint(x: size.width / 2 + 200, y: 30)
        handle.zPosition = 1
        addChild(handle)

        // Rivet on handle
        let rivet = SKShapeNode(circleOfRadius: 3.5)
        rivet.fillColor = SKColor(red: 0.30, green: 0.27, blue: 0.22, alpha: 1)
        rivet.strokeColor = SKColor(white: 0.4, alpha: 0.3)
        rivet.lineWidth = 0.5
        rivet.position = CGPoint(x: size.width / 2 + 155, y: 30)
        rivet.zPosition = 1.1
        addChild(rivet)
    }

    // MARK: - Ambient Particles

    private func setupAmbientParticles() {
        // Floating spice dust particles
        ambientDustEmitter = SKEmitterNode()
        ambientDustEmitter.particleTexture = createCircleTexture(radius: 4)
        ambientDustEmitter.particleBirthRate = 2.5
        ambientDustEmitter.particleLifetime = 6.0
        ambientDustEmitter.particleLifetimeRange = 3.0
        ambientDustEmitter.particleSpeed = 6
        ambientDustEmitter.particleSpeedRange = 4
        ambientDustEmitter.emissionAngle = .pi / 2
        ambientDustEmitter.emissionAngleRange = .pi
        ambientDustEmitter.particleScale = 0.08
        ambientDustEmitter.particleScaleRange = 0.05
        ambientDustEmitter.particleAlpha = 0.08
        ambientDustEmitter.particleAlphaSpeed = -0.012
        ambientDustEmitter.particleColor = SKColor(red: 1.0, green: 0.80, blue: 0.45, alpha: 1)
        ambientDustEmitter.particleColorBlendFactor = 1.0
        ambientDustEmitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: size.height * 0.5)
        ambientDustEmitter.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        ambientDustEmitter.zPosition = 0.5
        addChild(ambientDustEmitter)

        // Subtle smoke wisps rising from pan
        let smokeEmitter = SKEmitterNode()
        smokeEmitter.particleTexture = createCircleTexture(radius: 12)
        smokeEmitter.particleBirthRate = 1.5
        smokeEmitter.particleLifetime = 3.0
        smokeEmitter.particleLifetimeRange = 1.0
        smokeEmitter.particleSpeed = 15
        smokeEmitter.particleSpeedRange = 8
        smokeEmitter.emissionAngle = .pi / 2
        smokeEmitter.emissionAngleRange = .pi / 6
        smokeEmitter.particleScale = 0.12
        smokeEmitter.particleScaleSpeed = 0.08
        smokeEmitter.particleAlpha = 0.05
        smokeEmitter.particleAlphaSpeed = -0.018
        smokeEmitter.particleColor = SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1)
        smokeEmitter.particleColorBlendFactor = 1.0
        smokeEmitter.particlePositionRange = CGVector(dx: 150, dy: 10)
        smokeEmitter.position = CGPoint(x: size.width / 2, y: 60)
        smokeEmitter.zPosition = 2
        addChild(smokeEmitter)
    }

    private func createCircleTexture(radius: CGFloat) -> SKTexture {
        let diameter = radius * 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
        return SKTexture(image: image)
    }

    // MARK: - HUD

    private func setupHUD() {
        let hudY = size.height - 160

        // HUD backdrop strip
        let hudBG = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 44), cornerRadius: 12)
        hudBG.position = CGPoint(x: size.width / 2, y: hudY)
        hudBG.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)
        hudBG.strokeColor = SKColor(white: 0.25, alpha: 0.2)
        hudBG.lineWidth = 1
        hudBG.zPosition = 99
        addChild(hudBG)

        // Score label -- top-left
        scoreLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 80, y: hudY)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        // Timer label -- top-center
        timerLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        timerLabel.text = "0:40"
        timerLabel.fontSize = 30
        timerLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        timerLabel.position = CGPoint(x: size.width / 2, y: hudY)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

    }

    private func updateHUD() {
        scoreLabel.text = "Score: \(score)"

        let seconds = Int(ceil(timeRemaining))
        let mins = seconds / 60
        let secs = seconds % 60
        timerLabel.text = String(format: "%d:%02d", mins, secs)

        // Flash timer red when low
        if timeRemaining <= 5.0 {
            let pulse = CGFloat(abs(sin(timeRemaining * 3)))
            timerLabel.fontColor = SKColor(red: 1.0, green: 0.2 + 0.15 * pulse,
                                            blue: 0.2 + 0.15 * pulse, alpha: 1.0)
        } else {
            timerLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        }

    }

    // MARK: - Game Control

    private func startGame() {
        score = 0
        correctCatches = 0
        wrongCatches = 0
        totalCorrectSpawned = 0
        timeRemaining = gameDuration
        elapsedTime = 0.0
        lastSpawnTime = 0.0
        lastUpdateTime = 0.0
        gameActive = true
        caughtSpiceIDs.removeAll()
        updateHUD()
    }

    private func endGame() {
        guard gameActive else { return }
        gameActive = false
        HapticManager.shared.success()

        // Remove all remaining spice nodes
        enumerateChildNodes(withName: spiceNodeName) { node, _ in
            node.removeAllActions()
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }

        // Calculate final score using the formal formula
        let stars = calculateStars()
        let finalScore = max(0, correctCatches * 20 - wrongCatches * 10)

        // Scene exit curtain
        let exitCurtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        exitCurtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        exitCurtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0)
        exitCurtain.strokeColor = .clear
        exitCurtain.zPosition = 500
        addChild(exitCurtain)
        exitCurtain.run(.sequence([
            .wait(forDuration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.4),
            .run { [weak self] in self?.onComplete?(finalScore, stars) }
        ]))
    }

    private func calculateStars() -> Int {
        // 3 stars: caught 5+ correct spices
        // 2 stars: caught 4+ correct spices
        // 1 star: everything else
        if correctCatches >= 5 {
            return 3
        } else if correctCatches >= 4 {
            return 2
        } else {
            return 1
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameActive else { return }

        // Handle first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            lastSpawnTime = currentTime
            return
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        elapsedTime += dt
        timeRemaining -= dt

        // Check time-up
        if timeRemaining <= 0 {
            timeRemaining = 0
            updateHUD()
            endGame()
            return
        }

        updateHUD()

        // Spawn spices
        let spawnInterval = currentSpawnInterval()
        if currentTime - lastSpawnTime >= spawnInterval {
            spawnSpice()
            lastSpawnTime = currentTime
        }
    }

    /// Spawn interval decreases over time: starts at ~1.5s, drops to ~0.8s
    private func currentSpawnInterval() -> TimeInterval {
        let progress = min(elapsedTime / gameDuration, 1.0)
        return 1.5 - (0.7 * progress)
    }

    /// Correct-spice probability: starts at ~60%, drops to ~50%
    private func correctProbability() -> Double {
        let progress = min(elapsedTime / gameDuration, 1.0)
        return 0.60 - (0.10 * progress)
    }

    // MARK: - Spice Spawning

    private func spawnSpice() {
        let isCorrect = Double.random(in: 0...1) < correctProbability()
        let spiceData: SpiceData

        if isCorrect {
            spiceData = Self.correctSpices.randomElement()!
            totalCorrectSpawned += 1
        } else {
            spiceData = Self.decoySpices.randomElement()!
        }

        let node = createSpiceNode(data: spiceData)
        let startX = CGFloat.random(in: size.width * 0.15...size.width * 0.85)
        let startY: CGFloat = -40
        node.position = CGPoint(x: startX, y: startY)
        node.zPosition = 50
        node.name = spiceNodeName
        addChild(node)

        // Arc motion
        let peakY = CGFloat.random(in: size.height * 0.5...size.height * 0.8)
        let duration = Double.random(in: 2.0...3.0)

        // Slight horizontal drift for a more natural arc
        let driftX = CGFloat.random(in: -80...80)

        let moveUp = SKAction.moveTo(y: peakY, duration: duration * 0.5)
        moveUp.timingMode = .easeOut

        let moveDown = SKAction.moveTo(y: -40, duration: duration * 0.5)
        moveDown.timingMode = .easeIn

        let horizontalDrift = SKAction.moveBy(x: driftX, y: 0, duration: duration)
        horizontalDrift.timingMode = .linear

        let verticalArc = SKAction.sequence([moveUp, moveDown])
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: duration)

        let arcGroup = SKAction.group([verticalArc, horizontalDrift, rotate])
        let fullSequence = SKAction.sequence([arcGroup, SKAction.removeFromParent()])

        node.run(fullSequence)
    }

    private func createSpiceNode(data: SpiceData) -> SKNode {
        let container = SKNode()

        // Store spice data via userData
        container.userData = NSMutableDictionary()
        container.userData?["isCorrect"] = data.isCorrect
        container.userData?["spiceName"] = data.name

        // Outer glow ring for correct spices
        if data.isCorrect {
            let outerGlow = SKShapeNode(circleOfRadius: spiceRadius + 5)
            outerGlow.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 0.10)
            outerGlow.strokeColor = .clear
            outerGlow.zPosition = -1
            container.addChild(outerGlow)
        }

        // Circle background with improved colors
        let circle = SKShapeNode(circleOfRadius: spiceRadius)
        if data.isCorrect {
            circle.fillColor = correctCircleColor(for: data)
            circle.strokeColor = SKColor(red: 0.90, green: 0.70, blue: 0.30, alpha: 0.9)
        } else {
            circle.fillColor = SKColor(red: 0.50, green: 0.15, blue: 0.12, alpha: 0.95)
            circle.strokeColor = SKColor(red: 0.70, green: 0.28, blue: 0.22, alpha: 0.9)
        }
        circle.lineWidth = 2.5
        circle.glowWidth = data.isCorrect ? 2.0 : 0.5
        container.addChild(circle)

        // Inner highlight for depth
        let innerHighlight = SKShapeNode(circleOfRadius: spiceRadius * 0.7)
        innerHighlight.fillColor = SKColor(white: 1.0, alpha: 0.05)
        innerHighlight.strokeColor = .clear
        innerHighlight.position = CGPoint(x: -2, y: 3)
        innerHighlight.zPosition = 0.1
        circle.addChild(innerHighlight)

        // Symbol label with shadow
        let shadowLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        shadowLabel.text = data.symbol
        shadowLabel.fontSize = 22
        shadowLabel.fontColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        shadowLabel.verticalAlignmentMode = .center
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.position = CGPoint(x: 1, y: -1)
        container.addChild(shadowLabel)

        let label = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        label.text = data.symbol
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        container.addChild(label)

        // Name label below for identification
        let nameLabel = SKLabelNode(fontNamed: "SFCompactRounded-Medium")
        nameLabel.text = data.name
        nameLabel.fontSize = 10
        nameLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        nameLabel.verticalAlignmentMode = .top
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -spiceRadius - 4)
        container.addChild(nameLabel)

        // Subtle pulsing glow for correct spices
        if data.isCorrect {
            let pulseOut = SKAction.scale(to: 1.08, duration: 0.4)
            pulseOut.timingMode = .easeInEaseOut
            let pulseIn = SKAction.scale(to: 1.0, duration: 0.4)
            pulseIn.timingMode = .easeInEaseOut
            circle.run(SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn])))
        }

        return container
    }

    private func correctCircleColor(for data: SpiceData) -> SKColor {
        switch data.name {
        case "Star Anise":
            return SKColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 0.95)
        case "Cinnamon":
            return SKColor(red: 0.55, green: 0.25, blue: 0.12, alpha: 0.95)
        case "Cardamom":
            return SKColor(red: 0.25, green: 0.42, blue: 0.22, alpha: 0.95)
        case "Cloves":
            return SKColor(red: 0.35, green: 0.20, blue: 0.10, alpha: 0.95)
        case "Coriander":
            return SKColor(red: 0.55, green: 0.48, blue: 0.25, alpha: 0.95)
        default:
            return SKColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 0.95)
        }
    }

    // MARK: - Touch Handling (Swipe Detection)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Start a new swipe path
        swipePath = CGMutablePath()
        swipePath?.move(to: location)

        // Create the trail shape node with warm golden color
        let trail = SKShapeNode()
        trail.strokeColor = SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.85)
        trail.lineWidth = 4.0
        trail.lineCap = .round
        trail.lineJoin = .round
        trail.zPosition = 90
        trail.glowWidth = 3.0
        addChild(trail)
        swipeTrailNode = trail

        // Add particle trail following touch
        let particleTrail = SKEmitterNode()
        particleTrail.particleTexture = createCircleTexture(radius: 4)
        particleTrail.particleBirthRate = 40
        particleTrail.particleLifetime = 0.4
        particleTrail.particleLifetimeRange = 0.15
        particleTrail.particleSpeed = 0
        particleTrail.particleScale = 0.1
        particleTrail.particleScaleSpeed = -0.2
        particleTrail.particleAlpha = 0.5
        particleTrail.particleAlphaSpeed = -1.2
        particleTrail.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        particleTrail.particleColorBlendFactor = 1.0
        particleTrail.position = location
        particleTrail.zPosition = 89
        particleTrail.targetNode = self
        addChild(particleTrail)
        swipeParticleTrail = particleTrail

        // Also check if touch started directly on a spice
        checkSwipeHit(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Extend the path
        swipePath?.addLine(to: location)

        // Update the trail visual
        if let path = swipePath {
            swipeTrailNode?.path = path
        }

        // Move particle emitter
        swipeParticleTrail?.position = location

        // Check for spice hits along the swipe
        checkSwipeHit(at: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fadeOutSwipeTrail()
        swipePath = nil
        caughtSpiceIDs.removeAll()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        fadeOutSwipeTrail()
        swipePath = nil
        caughtSpiceIDs.removeAll()
    }

    private func fadeOutSwipeTrail() {
        if let trail = swipeTrailNode {
            swipeTrailNode = nil
            trail.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ]))
        }
        if let particleTrail = swipeParticleTrail {
            swipeParticleTrail = nil
            particleTrail.particleBirthRate = 0
            particleTrail.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Swipe Hit Detection

    private func checkSwipeHit(at point: CGPoint) {
        enumerateChildNodes(withName: spiceNodeName) { [weak self] node, stop in
            guard let self = self, self.gameActive else {
                stop.pointee = true
                return
            }

            // Skip already-caught spices in this swipe
            let nodeID = ObjectIdentifier(node)
            if self.caughtSpiceIDs.contains(nodeID) { return }

            let distance = hypot(node.position.x - point.x, node.position.y - point.y)
            if distance <= self.swipeHitRadius + self.spiceRadius {
                self.caughtSpiceIDs.insert(nodeID)
                AudioManager.shared.playSFX("swipe")
                self.processSpiceCatch(node: node)
            }
        }
    }

    // MARK: - Catch Processing

    private func processSpiceCatch(node: SKNode) {
        let isCorrect = node.userData?["isCorrect"] as? Bool ?? false

        // Stop the node's motion so it doesn't keep flying
        node.removeAllActions()
        node.name = nil // Prevent double-processing

        if isCorrect {
            correctCatches += 1
            score += 2
            comboCount += 1
            HapticManager.shared.medium()
            showGoldenBurst(at: node.position)
            showFloatingText("+2", color: SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0), at: node.position)
            AudioManager.shared.playSFX("success-chime")

            // Show combo counter when combo >= 2
            if comboCount >= 2 {
                let comboLabel = SKLabelNode(fontNamed: "SFCompactRounded-Heavy")
                comboLabel.text = "Combo x\(comboCount)!"
                comboLabel.fontSize = 34
                comboLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0)
                comboLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
                comboLabel.horizontalAlignmentMode = .center
                comboLabel.verticalAlignmentMode = .center
                comboLabel.zPosition = 110
                comboLabel.setScale(0.3)
                comboLabel.alpha = 0
                addChild(comboLabel)
                comboLabel.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.2, duration: 0.12),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.08)
                    ]),
                    SKAction.scale(to: 1.0, duration: 0.08),
                    SKAction.wait(forDuration: 0.4),
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.moveBy(x: 0, y: 20, duration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        } else {
            wrongCatches += 1
            score -= 1
            comboCount = 0
            HapticManager.shared.error()
            showRedFlash(at: node.position)
            showFloatingText("-1", color: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), at: node.position)
            AudioManager.shared.playSFX("error-buzz")

            // Screen shake on wrong catch
            shakeScreen()
        }

        // Shrink and remove the caught spice with pop feel
        node.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.06),
            ]),
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.removeFromParent()
        ]))

        updateHUD()

    }

    // MARK: - Visual Effects

    private func showGoldenBurst(at position: CGPoint) {
        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: 12)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.7)
        ring.lineWidth = 2.5
        ring.position = position
        ring.zPosition = 80
        addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 4.0, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.removeFromParent()
        ]))

        // Particles
        let particleCount = 22
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(
                red: CGFloat.random(in: 0.90...1.0),
                green: CGFloat.random(in: 0.72...0.92),
                blue: CGFloat.random(in: 0.10...0.35),
                alpha: 1.0
            )
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 80
            particle.glowWidth = 2.0
            addChild(particle)

            // Radial outward motion
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 35...90)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.3...0.55)

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

    private func showRedFlash(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 35)
        flash.fillColor = SKColor(red: 1.0, green: 0.08, blue: 0.08, alpha: 0.5)
        flash.strokeColor = SKColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 0.8)
        flash.lineWidth = 3
        flash.position = position
        flash.zPosition = 80
        flash.glowWidth = 5
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.2, duration: 0.22),
                SKAction.fadeOut(withDuration: 0.22)
            ]),
            SKAction.removeFromParent()
        ]))

        // X-mark for wrong catch
        let xMark = SKLabelNode(fontNamed: "SFCompactRounded-Heavy")
        xMark.text = "X"
        xMark.fontSize = 38
        xMark.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        xMark.position = position
        xMark.zPosition = 85
        xMark.verticalAlignmentMode = .center
        xMark.horizontalAlignmentMode = .center
        xMark.setScale(0.5)
        addChild(xMark)

        xMark.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 35, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 0.8, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Red scatter particles
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 0.9)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 82
            addChild(particle)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20...50)
            particle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.3),
                    .fadeOut(withDuration: 0.3)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showFloatingText(_ text: String, color: SKColor, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        label.text = text
        label.fontSize = 26
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 25)
        label.zPosition = 95
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.setScale(0.6)
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.1, duration: 0.1),
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.55),
                SKAction.scale(to: 0.9, duration: 0.55),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.fadeOut(withDuration: 0.30)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func shakeScreen() {
        if let cam = self.camera {
            let amp: CGFloat = 6
            let dur: TimeInterval = 0.05
            cam.run(SKAction.sequence([
                SKAction.moveBy(x: amp, y: 0, duration: dur),
                SKAction.moveBy(x: -amp * 2, y: 0, duration: dur),
                SKAction.moveBy(x: amp * 2, y: 0, duration: dur),
                SKAction.moveBy(x: -amp, y: 0, duration: dur),
            ]))
        } else {
            // No camera -- show a brief red overlay flash
            let overlay = SKShapeNode(rectOf: size)
            overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
            overlay.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.12)
            overlay.strokeColor = .clear
            overlay.zPosition = 200
            addChild(overlay)
            overlay.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        }
    }
}
