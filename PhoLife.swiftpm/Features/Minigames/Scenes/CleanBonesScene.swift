import SpriteKit

class CleanBonesScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let gameDuration: TimeInterval = 35.0
    private let postGameDelay: TimeInterval = 1.0
    private let bubbleMinRadius: CGFloat = 15.0
    private let bubbleMaxRadius: CGFloat = 35.0
    private let bubbleRiseDurationMin: TimeInterval = 2.5
    private let bubbleRiseDurationMax: TimeInterval = 4.0
    private let startSpawnInterval: TimeInterval = 1.0
    private let endSpawnInterval: TimeInterval = 0.333

    // MARK: - State

    private var totalBubbles: Int = 0
    private var tappedCount: Int = 0
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var gameActive: Bool = false
    private var gameEnded: Bool = false
    private var spawnTimer: TimeInterval = 0
    private var currentSpawnInterval: TimeInterval = 1.0
    private var sparkle50Triggered = false
    private var sparkle75Triggered = false

    // MARK: - Nodes

    private var potNode: SKShapeNode!
    private var waterOverlay: SKShapeNode!
    private var waterShimmer: SKShapeNode!
    private var timerLabel: SKLabelNode!
    private var potRect: CGRect = .zero

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1)
        view.isMultipleTouchEnabled = true

        setupBackground()
        setupPot()
        setupWaterOverlay()
        setupWaterShimmer()
        setupTimerLabel()
        setupDecorations()
        setupAmbientGlow()
        addAmbientParticles(color: SKColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1), birthRate: 1.0)

        gameActive = true

        // Entrance curtain
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
        // Warm kitchen gradient floor
        let floorGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.35))
        floorGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.175)
        floorGlow.fillColor = SKColor(red: 0.16, green: 0.09, blue: 0.04, alpha: 0.6)
        floorGlow.strokeColor = .clear
        floorGlow.zPosition = -10
        addChild(floorGlow)

        // Subtle upper wall color
        let wallGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.2))
        wallGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.1)
        wallGlow.fillColor = SKColor(red: 0.14, green: 0.09, blue: 0.05, alpha: 0.3)
        wallGlow.strokeColor = .clear
        wallGlow.zPosition = -10
        addChild(wallGlow)

        // Vignette for depth
        let vignetteSize = max(size.width, size.height) * 1.2
        let vignette = SKShapeNode(circleOfRadius: vignetteSize / 2)
        vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor(red: 0.03, green: 0.02, blue: 0.01, alpha: 0.5)
        vignette.lineWidth = vignetteSize * 0.23
        vignette.zPosition = -1
        addChild(vignette)
    }

    // MARK: - Setup

    private func setupPot() {
        let potWidth = size.width * 0.55
        let potHeight = size.height * 0.65
        let centerX = size.width / 2
        let centerY = size.height / 2 - 20

        potRect = CGRect(
            x: centerX - potWidth / 2,
            y: centerY - potHeight / 2,
            width: potWidth,
            height: potHeight
        )

        // Pot shadow
        let shadowPath = CGPath(
            ellipseIn: potRect.insetBy(dx: -12, dy: -12).offsetBy(dx: 4, dy: -6),
            transform: nil
        )
        let shadowNode = SKShapeNode(path: shadowPath)
        shadowNode.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)
        shadowNode.strokeColor = .clear
        shadowNode.zPosition = -0.5
        addChild(shadowNode)

        // Warm glow under pot
        let potGlow = SKShapeNode(ellipseOf: CGSize(width: potWidth + 80, height: potHeight * 0.5))
        potGlow.position = CGPoint(x: centerX, y: centerY - potHeight * 0.35)
        potGlow.fillColor = SKColor(red: 0.60, green: 0.25, blue: 0.05, alpha: 0.06)
        potGlow.strokeColor = .clear
        potGlow.zPosition = -0.3
        addChild(potGlow)
        potGlow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.09, duration: 1.5),
            .fadeAlpha(to: 0.04, duration: 1.5)
        ])))

        // Pot rim -- outer ellipse for a subtle 3D rim effect
        let rimPath = CGPath(
            ellipseIn: potRect.insetBy(dx: -10, dy: -10),
            transform: nil
        )
        let rimNode = SKShapeNode(path: rimPath)
        rimNode.fillColor = SKColor(red: 0.20, green: 0.14, blue: 0.07, alpha: 1)
        rimNode.strokeColor = SKColor(red: 0.30, green: 0.22, blue: 0.12, alpha: 1)
        rimNode.lineWidth = 4
        rimNode.zPosition = 0
        addChild(rimNode)

        // Rim highlight arc
        let rimHighlightPath = CGPath(
            ellipseIn: potRect.insetBy(dx: -6, dy: -6),
            transform: nil
        )
        let rimHighlight = SKShapeNode(path: rimHighlightPath)
        rimHighlight.fillColor = .clear
        rimHighlight.strokeColor = SKColor(white: 1.0, alpha: 0.04)
        rimHighlight.lineWidth = 2
        rimHighlight.zPosition = 0.1
        addChild(rimHighlight)

        // Main pot body
        let potPath = CGPath(ellipseIn: potRect, transform: nil)
        potNode = SKShapeNode(path: potPath)
        potNode.fillColor = SKColor(red: 0.07, green: 0.04, blue: 0.02, alpha: 1)
        potNode.strokeColor = SKColor(red: 0.20, green: 0.14, blue: 0.07, alpha: 0.8)
        potNode.lineWidth = 3
        potNode.zPosition = 1
        addChild(potNode)

        // Inner water base -- slightly lighter dark color under the murky overlay
        let innerInset: CGFloat = 12
        let innerRect = potRect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(ellipseIn: innerRect, transform: nil)
        let innerNode = SKShapeNode(path: innerPath)
        innerNode.fillColor = SKColor(red: 0.22, green: 0.16, blue: 0.08, alpha: 1)
        innerNode.strokeColor = .clear
        innerNode.lineWidth = 0
        innerNode.zPosition = 2
        addChild(innerNode)

        // Handles on each side
        for side in [-1.0, 1.0] as [CGFloat] {
            let handle = SKShapeNode(rectOf: CGSize(width: 30, height: 12), cornerRadius: 4)
            handle.fillColor = SKColor(red: 0.22, green: 0.16, blue: 0.10, alpha: 1)
            handle.strokeColor = SKColor(red: 0.32, green: 0.24, blue: 0.14, alpha: 0.8)
            handle.lineWidth = 1.5
            handle.position = CGPoint(x: centerX + side * (potWidth / 2 + 18),
                                      y: centerY + potHeight * 0.15)
            handle.zPosition = 0.5
            addChild(handle)
        }
    }

    private func setupWaterOverlay() {
        let innerInset: CGFloat = 12
        let innerRect = potRect.insetBy(dx: innerInset, dy: innerInset)
        let overlayPath = CGPath(ellipseIn: innerRect, transform: nil)
        waterOverlay = SKShapeNode(path: overlayPath)
        waterOverlay.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.12, alpha: 1)
        waterOverlay.strokeColor = .clear
        waterOverlay.lineWidth = 0
        waterOverlay.alpha = 0.6
        waterOverlay.zPosition = 50
        addChild(waterOverlay)
    }

    private func setupWaterShimmer() {
        // Subtle animated shimmer on water surface
        let innerInset: CGFloat = 20
        let shimmerRect = potRect.insetBy(dx: innerInset, dy: potRect.height * 0.35)
        let shimmerPath = CGPath(ellipseIn: shimmerRect.offsetBy(dx: 0, dy: potRect.height * 0.18),
                                  transform: nil)
        waterShimmer = SKShapeNode(path: shimmerPath)
        waterShimmer.fillColor = SKColor(white: 1.0, alpha: 0.03)
        waterShimmer.strokeColor = .clear
        waterShimmer.zPosition = 51
        addChild(waterShimmer)

        // Gentle shimmer animation
        waterShimmer.run(.repeatForever(.sequence([
            .group([
                .fadeAlpha(to: 0.06, duration: 1.8),
                .moveBy(x: 8, y: 0, duration: 1.8)
            ]),
            .group([
                .fadeAlpha(to: 0.02, duration: 1.8),
                .moveBy(x: -8, y: 0, duration: 1.8)
            ])
        ])))
    }

    private func setupTimerLabel() {
        // HUD backdrop
        let hudBG = SKShapeNode(rectOf: CGSize(width: size.width - 120, height: 40), cornerRadius: 10)
        hudBG.position = CGPoint(x: size.width / 2, y: size.height - 160)
        hudBG.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)
        hudBG.strokeColor = SKColor(white: 0.2, alpha: 0.2)
        hudBG.lineWidth = 1
        hudBG.zPosition = 99
        addChild(hudBG)

        timerLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        timerLabel.text = "Time: 35"
        timerLabel.fontSize = 28
        timerLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

        // Score counter at top-right
        let scoreLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        scoreLabel.name = "scoreLabel"
        scoreLabel.text = "Popped: 0"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.5, alpha: 0.85)
        scoreLabel.position = CGPoint(x: size.width - 120, y: size.height - 160)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        // Instruction label that fades out
        let instructionLabel = SKLabelNode(fontNamed: "SFCompactRounded-Medium")
        instructionLabel.text = "Tap the scum bubbles!"
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height - 195)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])
        instructionLabel.run(fadeAction)
    }

    private func setupDecorations() {
        // Steam wisps above the pot for ambiance
        let steamCount = 7
        for i in 0..<steamCount {
            let radius = CGFloat.random(in: 8...18)
            let steamNode = SKShapeNode(circleOfRadius: radius)
            steamNode.fillColor = SKColor(white: 0.9, alpha: 0.06)
            steamNode.strokeColor = .clear
            steamNode.lineWidth = 0
            steamNode.zPosition = 60

            let startX = potRect.midX + CGFloat.random(in: -potRect.width * 0.3...potRect.width * 0.3)
            let startY = potRect.maxY + CGFloat.random(in: 10...30)
            steamNode.position = CGPoint(x: startX, y: startY)

            addChild(steamNode)

            let delay = TimeInterval(i) * 0.5
            let drift = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -25...25), y: 70, duration: 2.8),
                        SKAction.fadeOut(withDuration: 2.8),
                        SKAction.scale(to: 1.4, duration: 2.8)
                    ]),
                    SKAction.run { [weak steamNode, weak self] in
                        guard let steam = steamNode, let self = self else { return }
                        let newX = self.potRect.midX + CGFloat.random(in: -self.potRect.width * 0.3...self.potRect.width * 0.3)
                        steam.position = CGPoint(x: newX, y: self.potRect.maxY + CGFloat.random(in: 10...30))
                        steam.alpha = 0.06
                        steam.setScale(1.0)
                    }
                ]))
            ])
            steamNode.run(drift)
        }
    }

    private func setupAmbientGlow() {
        // Central warm radial glow behind pot
        let centralGlow = SKShapeNode(circleOfRadius: 200)
        centralGlow.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        centralGlow.fillColor = SKColor(red: 0.35, green: 0.18, blue: 0.06, alpha: 0.08)
        centralGlow.strokeColor = .clear
        centralGlow.zPosition = -5
        addChild(centralGlow)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameActive else { return }

        // Initialize lastUpdateTime on first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Clamp deltaTime to avoid huge jumps (e.g. returning from background)
        let dt = min(deltaTime, 0.1)

        elapsedTime += dt

        // Update timer display
        let remaining = max(0, gameDuration - elapsedTime)
        timerLabel.text = "Time: \(Int(ceil(remaining)))"

        // Pulse timer red when low
        if remaining <= 5 {
            timerLabel.fontColor = SKColor(
                red: 1.0,
                green: CGFloat(remaining / 5.0),
                blue: CGFloat(remaining / 5.0),
                alpha: 1.0
            )
        }

        // Update water overlay clarity
        updateWaterClarity()

        // Check if game time is up
        if elapsedTime >= gameDuration {
            endGame()
            return
        }

        // Spawn bubbles
        let progress = elapsedTime / gameDuration  // 0 -> 1
        currentSpawnInterval = startSpawnInterval + (endSpawnInterval - startSpawnInterval) * progress
        spawnTimer += dt

        if spawnTimer >= currentSpawnInterval {
            spawnTimer -= currentSpawnInterval
            spawnBubble()
        }
    }

    // MARK: - Water Clarity

    private func updateWaterClarity() {
        guard totalBubbles > 0 else { return }
        let ratio = CGFloat(tappedCount) / CGFloat(totalBubbles)
        // Lerp from 0.6 (fully murky) to 0.0 (crystal clear)
        let targetAlpha = max(0.0, 0.6 * (1.0 - ratio))
        // Smooth the transition slightly
        waterOverlay.alpha += (targetAlpha - waterOverlay.alpha) * 0.1

        // Shimmer becomes more visible as water gets clearer
        let shimmerTarget = max(0.01, 0.06 * ratio)
        waterShimmer.alpha += (shimmerTarget - waterShimmer.alpha) * 0.05
    }

    // MARK: - Bubble Spawning

    private func spawnBubble() {
        totalBubbles += 1

        let radius = CGFloat.random(in: bubbleMinRadius...bubbleMaxRadius)
        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.name = "bubble"

        // Scum bubble color: semi-transparent yellowish-brown
        let r = CGFloat.random(in: 0.55...0.70)
        let g = CGFloat.random(in: 0.40...0.55)
        let b = CGFloat.random(in: 0.15...0.25)
        bubble.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.65)
        bubble.strokeColor = SKColor(red: r + 0.12, green: g + 0.12, blue: b + 0.06, alpha: 0.35)
        bubble.lineWidth = 1.5

        // Glow effect -- a larger, more transparent circle behind the bubble
        let glow = SKShapeNode(circleOfRadius: radius * 1.5)
        glow.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.12)
        glow.strokeColor = .clear
        glow.lineWidth = 0
        glow.zPosition = -1
        bubble.addChild(glow)

        // Specular highlight -- bright spot for a "wet" look
        let highlightRadius = radius * 0.28
        let highlight = SKShapeNode(circleOfRadius: highlightRadius)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.30)
        highlight.strokeColor = .clear
        highlight.lineWidth = 0
        highlight.position = CGPoint(x: -radius * 0.22, y: radius * 0.28)
        highlight.zPosition = 1
        bubble.addChild(highlight)

        // Secondary smaller highlight for extra realism
        let highlight2 = SKShapeNode(circleOfRadius: highlightRadius * 0.4)
        highlight2.fillColor = SKColor(white: 1.0, alpha: 0.18)
        highlight2.strokeColor = .clear
        highlight2.position = CGPoint(x: radius * 0.15, y: -radius * 0.15)
        highlight2.zPosition = 1
        bubble.addChild(highlight2)

        // Thin rim edge for refraction feel
        let rimEdge = SKShapeNode(circleOfRadius: radius - 1)
        rimEdge.fillColor = .clear
        rimEdge.strokeColor = SKColor(white: 1.0, alpha: 0.06)
        rimEdge.lineWidth = 1
        rimEdge.zPosition = 2
        bubble.addChild(rimEdge)

        // Position: random x within the pot ellipse at the bottom
        let innerInset: CGFloat = 25.0
        let spawnMinX = potRect.minX + innerInset + radius
        let spawnMaxX = potRect.maxX - innerInset - radius
        let spawnX = CGFloat.random(in: spawnMinX...spawnMaxX)
        let spawnY = potRect.minY + innerInset

        bubble.position = CGPoint(x: spawnX, y: spawnY)
        bubble.zPosition = 30
        bubble.setScale(0.0)

        addChild(bubble)

        // Rise duration
        let riseDuration = TimeInterval.random(in: bubbleRiseDurationMin...bubbleRiseDurationMax)

        // Target Y: near the top of the pot
        let targetY = potRect.maxY - innerInset

        // Slight horizontal wobble during rise
        let wobbleAmplitude = CGFloat.random(in: 8...20)
        let wobblePeriod = TimeInterval.random(in: 0.8...1.5)

        // Appear animation
        let appear = SKAction.scale(to: 1.0, duration: 0.2)
        appear.timingMode = .easeOut

        // Rise
        let rise = SKAction.moveTo(y: targetY, duration: riseDuration)
        rise.timingMode = .easeIn

        // Wobble and pulse run independently
        let wobble = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveBy(x: wobbleAmplitude, y: 0, duration: wobblePeriod / 2),
                SKAction.moveBy(x: -wobbleAmplitude, y: 0, duration: wobblePeriod / 2)
            ])
        )
        bubble.run(wobble, withKey: "wobble")

        let pulse = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.4),
                SKAction.scale(to: 0.95, duration: 0.4)
            ])
        )
        bubble.run(pulse, withKey: "pulse")

        // Main lifecycle: appear -> rise -> auto-pop at top
        let lifetime = SKAction.sequence([
            appear,
            rise,
            SKAction.run { [weak self, weak bubble] in
                guard let self = self, let bubble = bubble, bubble.name == "bubble" else { return }
                self.autoPopBubble(bubble)
            }
        ])

        bubble.run(lifetime, withKey: "lifetime")
    }

    // MARK: - Auto Pop (bubble reached top)

    private func autoPopBubble(_ bubble: SKShapeNode) {
        bubble.name = nil
        bubble.removeAllActions()

        let bubblePosition = bubble.position

        // Screen shake for missed bubble
        shakeCamera(intensity: 4)

        // Small splatter particles
        spawnPopParticles(at: bubblePosition, color: bubble.fillColor, count: 4)

        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: bubble.frame.width / 4)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(white: 1.0, alpha: 0.20)
        ring.lineWidth = 1.5
        ring.position = bubblePosition
        ring.zPosition = 10
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.5, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent()
        ]))

        // Pop animation
        bubble.run(.sequence([
            .group([
                .scale(to: 1.4, duration: 0.12),
                .fadeOut(withDuration: 0.12)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive else { return }

        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)

            for node in touchedNodes {
                if node.name == "bubble" {
                    popBubble(node as! SKShapeNode, at: location)
                    break  // Only pop one bubble per touch point
                }
            }
        }
    }

    private func popBubble(_ bubble: SKShapeNode, at position: CGPoint) {
        // Prevent double-tap
        bubble.name = nil
        bubble.removeAllActions()

        tappedCount += 1

        // Update score label
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel.text = "Popped: \(tappedCount)"
            // Brief pop animation on the score label
            scoreLabel.run(.sequence([
                .scale(to: 1.15, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
        }

        // Haptic feedback
        HapticManager.shared.light()
        AudioManager.shared.playSFX("pop")

        // Capture bubble position and radius before removal
        let bubblePosition = bubble.position
        let bubbleRadius = bubble.frame.width / 2

        // Pop animation: scale up + fade out
        let pop = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.15),
            SKAction.fadeOut(withDuration: 0.15)
        ])
        pop.timingMode = .easeOut

        // Spawn improved splatter particles on pop
        spawnPopParticles(at: bubblePosition, color: bubble.fillColor, count: 6)

        // Water ripple effect
        spawnRipple(at: bubblePosition, radius: bubbleRadius)

        // Expanding ring on pop
        let ring = SKShapeNode(circleOfRadius: bubbleRadius * 0.5)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(white: 1.0, alpha: 0.45)
        ring.lineWidth = 2
        ring.position = bubblePosition
        ring.zPosition = 10
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 3.0, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))

        // Floating "+1" text with improved styling
        let pointLabel = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        pointLabel.text = "+1"
        pointLabel.fontSize = 20
        pointLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.6, alpha: 0.9)
        pointLabel.position = bubblePosition
        pointLabel.zPosition = 15
        pointLabel.setScale(0.6)
        addChild(pointLabel)
        pointLabel.run(.sequence([
            .scale(to: 1.1, duration: 0.08),
            .group([.moveBy(x: 0, y: 45, duration: 0.55), .fadeOut(withDuration: 0.55)]),
            .removeFromParent()
        ]))

        // Check clarity sparkle thresholds
        checkClaritySparkles()

        bubble.run(SKAction.sequence([pop, SKAction.removeFromParent()]))
    }

    private func spawnPopParticles(at position: CGPoint, color: SKColor, count: Int) {
        let particleCount = count + Int.random(in: 0...3)
        for _ in 0..<particleCount {
            let particleRadius = CGFloat.random(in: 2...5)
            let particle = SKShapeNode(circleOfRadius: particleRadius)
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.lineWidth = 0
            particle.position = position
            particle.zPosition = 35
            particle.glowWidth = 1
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...45)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let scatter = SKAction.group([
                SKAction.moveBy(x: dx, y: dy, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 0.1, duration: 0.35)
            ])
            particle.run(SKAction.sequence([scatter, SKAction.removeFromParent()]))
        }
    }

    private func spawnRipple(at position: CGPoint, radius: CGFloat) {
        // Double ripple for more satisfying pop
        for i in 0..<2 {
            let ripple = SKShapeNode(circleOfRadius: radius * 0.3)
            ripple.fillColor = .clear
            ripple.strokeColor = SKColor(white: 1.0, alpha: CGFloat(0.2 - Double(i) * 0.08))
            ripple.lineWidth = 1.5
            ripple.position = position
            ripple.zPosition = 8
            addChild(ripple)
            ripple.run(.sequence([
                .wait(forDuration: Double(i) * 0.08),
                .group([
                    .scale(to: CGFloat(3.5 + Double(i) * 1.5), duration: 0.35),
                    .fadeOut(withDuration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - End Game

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        gameActive = false

        // Stop spawning, let remaining bubbles live for a moment
        timerLabel.text = "Time: 0"

        // Flash "Time's Up!" label
        let timesUpLabel = SKLabelNode(fontNamed: "SFCompactRounded-Heavy")
        timesUpLabel.text = "Time's Up!"
        timesUpLabel.fontSize = 46
        timesUpLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
        timesUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        timesUpLabel.horizontalAlignmentMode = .center
        timesUpLabel.verticalAlignmentMode = .center
        timesUpLabel.zPosition = 200
        timesUpLabel.setScale(0.3)
        timesUpLabel.alpha = 0
        addChild(timesUpLabel)

        let showLabel = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.1, duration: 0.25),
                SKAction.fadeIn(withDuration: 0.25)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        let hideLabel = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])

        timesUpLabel.run(SKAction.sequence([showLabel, hideLabel]))

        // Wait for remaining bubbles, then report score
        let waitAndReport = SKAction.sequence([
            SKAction.wait(forDuration: postGameDelay),
            SKAction.run { [weak self] in
                self?.reportScore()
            }
        ])
        run(waitAndReport)
    }

    private func reportScore() {
        // Calculate percentage
        guard totalBubbles > 0 else {
            let exitCurtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
            exitCurtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
            exitCurtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0)
            exitCurtain.strokeColor = .clear
            exitCurtain.zPosition = 500
            addChild(exitCurtain)
            exitCurtain.run(.sequence([
                .fadeAlpha(to: 1.0, duration: 0.4),
                .run { [weak self] in self?.onComplete?(0, 1) }
            ]))
            return
        }

        let percentage = Double(tappedCount) / Double(totalBubbles)
        let score = Int(percentage * 100)

        let stars: Int
        if percentage >= 0.90 {
            stars = 3
        } else if percentage >= 0.70 {
            stars = 2
        } else {
            stars = 1
        }

        HapticManager.shared.success()

        let exitCurtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        exitCurtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        exitCurtain.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0)
        exitCurtain.strokeColor = .clear
        exitCurtain.zPosition = 500
        addChild(exitCurtain)
        exitCurtain.run(.sequence([
            .fadeAlpha(to: 1.0, duration: 0.4),
            .run { [weak self] in self?.onComplete?(score, stars) }
        ]))
    }

    // MARK: - Clarity Sparkles

    private func checkClaritySparkles() {
        let ratio = Double(tappedCount) / Double(max(totalBubbles, 1))
        if ratio >= 0.5 && !sparkle50Triggered {
            sparkle50Triggered = true
            spawnClaritySparkles()
        }
        if ratio >= 0.75 && !sparkle75Triggered {
            sparkle75Triggered = true
            spawnClaritySparkles()
        }
    }

    private func spawnClaritySparkles() {
        for _ in 0..<12 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            sparkle.fillColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9)
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 4
            sparkle.position = CGPoint(
                x: size.width / 2 + CGFloat.random(in: -130...130),
                y: potRect.midY + CGFloat.random(in: -70...70)
            )
            sparkle.zPosition = 52
            sparkle.setScale(0.1)
            sparkle.alpha = 0
            addChild(sparkle)
            sparkle.run(.sequence([
                .group([
                    .scale(to: 1.0, duration: 0.25),
                    .fadeAlpha(to: 1.0, duration: 0.25)
                ]),
                .wait(forDuration: 0.4),
                .group([
                    .scale(to: 0.1, duration: 0.4),
                    .fadeOut(withDuration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }

        // Brief water flash to show clarity improvement
        let clarityFlash = SKShapeNode(path: waterOverlay.path!)
        clarityFlash.fillColor = SKColor(white: 1.0, alpha: 0.08)
        clarityFlash.strokeColor = .clear
        clarityFlash.zPosition = 51.5
        addChild(clarityFlash)
        clarityFlash.run(.sequence([
            .fadeOut(withDuration: 0.6),
            .removeFromParent()
        ]))

        HapticManager.shared.medium()
        AudioManager.shared.playSFX("sparkle")
    }
}
