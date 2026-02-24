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

    private let gameDuration: TimeInterval = 30.0
    private let maxWrongCatches: Int = 3
    private let spiceRadius: CGFloat = 20.0
    private let spiceDiameter: CGFloat = 40.0
    private let swipeHitRadius: CGFloat = 30.0
    private let spiceNodeName = "spice"

    // MARK: - Game State

    private var score: Int = 0
    private var correctCatches: Int = 0
    private var wrongCatches: Int = 0
    private var totalCorrectSpawned: Int = 0
    private var timeRemaining: TimeInterval = 30.0
    private var gameActive: Bool = false
    private var elapsedTime: TimeInterval = 0.0
    private var lastSpawnTime: TimeInterval = 0.0
    private var lastUpdateTime: TimeInterval = 0.0

    // MARK: - HUD Nodes

    private var scoreLabel: SKLabelNode!
    private var wrongLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!

    // MARK: - Swipe Tracking

    private var swipePath: CGMutablePath?
    private var swipeTrailNode: SKShapeNode?
    private var caughtSpiceIDs: Set<ObjectIdentifier> = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1.0)

        setupBackground()
        setupHUD()
        startGame()
    }

    // MARK: - Background

    private func setupBackground() {
        // Warm kitchen gradient effect using layered shapes
        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.4))
        bottomGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        bottomGlow.fillColor = SKColor(red: 0.35, green: 0.20, blue: 0.08, alpha: 0.4)
        bottomGlow.strokeColor = .clear
        bottomGlow.zPosition = -10
        addChild(bottomGlow)

        // Subtle counter / surface at bottom
        let counter = SKShapeNode(rectOf: CGSize(width: size.width, height: 60))
        counter.position = CGPoint(x: size.width / 2, y: 30)
        counter.fillColor = SKColor(red: 0.22, green: 0.14, blue: 0.07, alpha: 1.0)
        counter.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        counter.lineWidth = 2
        counter.zPosition = -5
        addChild(counter)

        // Warm ambient glow at top
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.15))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.075)
        topGlow.fillColor = SKColor(red: 0.40, green: 0.25, blue: 0.10, alpha: 0.15)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        addChild(topGlow)
    }

    // MARK: - HUD

    private func setupHUD() {
        let hudY = size.height - 50

        // Score label — top-left
        scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 30, y: hudY)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        // Timer label — top-center
        timerLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timerLabel.text = "0:30"
        timerLabel.fontSize = 30
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width / 2, y: hudY)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

        // Wrong label — top-right
        wrongLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        wrongLabel.text = "Wrong: 0/3"
        wrongLabel.fontSize = 26
        wrongLabel.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 1.0)
        wrongLabel.position = CGPoint(x: size.width - 30, y: hudY)
        wrongLabel.horizontalAlignmentMode = .right
        wrongLabel.verticalAlignmentMode = .center
        wrongLabel.zPosition = 100
        addChild(wrongLabel)
    }

    private func updateHUD() {
        scoreLabel.text = "Score: \(score)"

        let seconds = Int(ceil(timeRemaining))
        let mins = seconds / 60
        let secs = seconds % 60
        timerLabel.text = String(format: "%d:%02d", mins, secs)

        // Flash timer red when low
        if timeRemaining <= 5.0 {
            timerLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        } else {
            timerLabel.fontColor = .white
        }

        wrongLabel.text = "Wrong: \(wrongCatches)/\(maxWrongCatches)"
        if wrongCatches >= 2 {
            wrongLabel.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        } else {
            wrongLabel.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 1.0)
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

        // Brief delay then report
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                self?.onComplete?(finalScore, stars)
            }
        ]))
    }

    private func calculateStars() -> Int {
        // 3 stars: caught all 5 distinct correct types with 0 wrong
        // 2 stars: 4+ correct catches with 1 or fewer wrong
        // 1 star: everything else
        if correctCatches >= 5 && wrongCatches == 0 {
            return 3
        } else if correctCatches >= 4 && wrongCatches <= 1 {
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

        // Circle background
        let circle = SKShapeNode(circleOfRadius: spiceRadius)
        if data.isCorrect {
            // Warm brown/amber tint for correct spices
            circle.fillColor = correctCircleColor(for: data)
            circle.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 0.9)
        } else {
            // Reddish tint for decoy spices
            circle.fillColor = SKColor(red: 0.55, green: 0.18, blue: 0.15, alpha: 0.9)
            circle.strokeColor = SKColor(red: 0.75, green: 0.30, blue: 0.25, alpha: 0.9)
        }
        circle.lineWidth = 2.5
        circle.glowWidth = 1.0
        container.addChild(circle)

        // Symbol label
        let label = SKLabelNode(fontNamed: "SFProRounded-Bold")
        label.text = data.symbol
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        container.addChild(label)

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

        // Create the trail shape node
        let trail = SKShapeNode()
        trail.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.8)
        trail.lineWidth = 3.0
        trail.lineCap = .round
        trail.lineJoin = .round
        trail.zPosition = 90
        trail.glowWidth = 2.0
        addChild(trail)
        swipeTrailNode = trail

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
        guard let trail = swipeTrailNode else { return }
        swipeTrailNode = nil
        trail.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
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
            showGoldenBurst(at: node.position)
            showFloatingText("+2", color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0), at: node.position)
            AudioManager.shared.playSFX("success-chime")
        } else {
            wrongCatches += 1
            score -= 1
            showRedFlash(at: node.position)
            showFloatingText("-1", color: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), at: node.position)
            AudioManager.shared.playSFX("error-buzz")

            // Screen shake on wrong catch
            shakeScreen()
        }

        // Shrink and remove the caught spice
        node.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))

        updateHUD()

        // Check for 3 wrong catches
        if wrongCatches >= maxWrongCatches {
            // Brief delay to let the flash play, then end
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.endGame()
                }
            ]))
        }
    }

    // MARK: - Visual Effects

    private func showGoldenBurst(at position: CGPoint) {
        let particleCount = 20
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(
                red: CGFloat.random(in: 0.9...1.0),
                green: CGFloat.random(in: 0.7...0.9),
                blue: CGFloat.random(in: 0.1...0.4),
                alpha: 1.0
            )
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 80
            particle.glowWidth = 1.5
            addChild(particle)

            // Radial outward motion
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...80)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.3...0.6)

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
        flash.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.6)
        flash.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.9)
        flash.lineWidth = 3
        flash.position = position
        flash.zPosition = 80
        flash.glowWidth = 4
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // X-mark for wrong catch
        let xMark = SKLabelNode(fontNamed: "SFProRounded-Bold")
        xMark.text = "✕"
        xMark.fontSize = 36
        xMark.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        xMark.position = position
        xMark.zPosition = 85
        xMark.verticalAlignmentMode = .center
        xMark.horizontalAlignmentMode = .center
        addChild(xMark)

        xMark.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 30, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func showFloatingText(_ text: String, color: SKColor, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "SFProRounded-Bold")
        label.text = text
        label.fontSize = 24
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 25)
        label.zPosition = 95
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.6),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
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
            // No camera — show a brief red overlay flash
            let overlay = SKShapeNode(rectOf: size)
            overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
            overlay.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.15)
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
