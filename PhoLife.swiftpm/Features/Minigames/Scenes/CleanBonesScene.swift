import SpriteKit
import UIKit

class CleanBonesScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let gameDuration: TimeInterval = 25.0
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

    // MARK: - Nodes

    private var potNode: SKShapeNode!
    private var waterOverlay: SKShapeNode!
    private var timerLabel: SKLabelNode!
    private var potRect: CGRect = .zero

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 1)
        view.isMultipleTouchEnabled = true

        setupPot()
        setupWaterOverlay()
        setupTimerLabel()
        setupDecorations()

        gameActive = true
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

        // Pot rim — outer ellipse for a subtle 3D rim effect
        let rimPath = CGPath(
            ellipseIn: potRect.insetBy(dx: -8, dy: -8),
            transform: nil
        )
        let rimNode = SKShapeNode(path: rimPath)
        rimNode.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 1)
        rimNode.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.10, alpha: 1)
        rimNode.lineWidth = 4
        rimNode.zPosition = 0
        addChild(rimNode)

        // Main pot body
        let potPath = CGPath(ellipseIn: potRect, transform: nil)
        potNode = SKShapeNode(path: potPath)
        potNode.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 1)
        potNode.strokeColor = SKColor(red: 0.22, green: 0.16, blue: 0.08, alpha: 0.8)
        potNode.lineWidth = 3
        potNode.zPosition = 1
        addChild(potNode)

        // Inner water base — slightly lighter dark color under the murky overlay
        let innerInset: CGFloat = 12
        let innerRect = potRect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(ellipseIn: innerRect, transform: nil)
        let innerNode = SKShapeNode(path: innerPath)
        innerNode.fillColor = SKColor(red: 0.20, green: 0.15, blue: 0.08, alpha: 1)
        innerNode.strokeColor = .clear
        innerNode.lineWidth = 0
        innerNode.zPosition = 2
        addChild(innerNode)
    }

    private func setupWaterOverlay() {
        let innerInset: CGFloat = 12
        let innerRect = potRect.insetBy(dx: innerInset, dy: innerInset)
        let overlayPath = CGPath(ellipseIn: innerRect, transform: nil)
        waterOverlay = SKShapeNode(path: overlayPath)
        waterOverlay.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1)
        waterOverlay.strokeColor = .clear
        waterOverlay.lineWidth = 0
        waterOverlay.alpha = 0.6
        waterOverlay.zPosition = 50
        addChild(waterOverlay)
    }

    private func setupTimerLabel() {
        timerLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timerLabel.text = "Time: 25"
        timerLabel.fontSize = 28
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

        // Score counter at top-right
        let scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        scoreLabel.name = "scoreLabel"
        scoreLabel.text = "Popped: 0"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        scoreLabel.position = CGPoint(x: size.width - 120, y: size.height - 80)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        // Instruction label that fades out
        let instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Tap the scum bubbles!"
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.8)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height - 115)
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
        let steamCount = 5
        for i in 0..<steamCount {
            let steamNode = SKShapeNode(circleOfRadius: CGFloat.random(in: 6...14))
            steamNode.fillColor = SKColor(white: 0.9, alpha: 0.08)
            steamNode.strokeColor = .clear
            steamNode.lineWidth = 0
            steamNode.zPosition = 60

            let startX = potRect.midX + CGFloat.random(in: -potRect.width * 0.3...potRect.width * 0.3)
            let startY = potRect.maxY + CGFloat.random(in: 10...30)
            steamNode.position = CGPoint(x: startX, y: startY)

            addChild(steamNode)

            let delay = TimeInterval(i) * 0.6
            let drift = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 60, duration: 2.5),
                        SKAction.fadeOut(withDuration: 2.5)
                    ]),
                    SKAction.run { [weak steamNode] in
                        guard let steam = steamNode else { return }
                        let newX = self.potRect.midX + CGFloat.random(in: -self.potRect.width * 0.3...self.potRect.width * 0.3)
                        steam.position = CGPoint(x: newX, y: self.potRect.maxY + CGFloat.random(in: 10...30))
                        steam.alpha = 0.08
                    }
                ]))
            ])
            steamNode.run(drift)
        }
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
        bubble.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.7)
        bubble.strokeColor = SKColor(red: r + 0.1, green: g + 0.1, blue: b + 0.05, alpha: 0.4)
        bubble.lineWidth = 1.5

        // Glow effect — a larger, more transparent circle behind the bubble
        let glow = SKShapeNode(circleOfRadius: radius * 1.4)
        glow.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.15)
        glow.strokeColor = .clear
        glow.lineWidth = 0
        glow.zPosition = -1
        bubble.addChild(glow)

        // Specular highlight — small bright spot for a "wet" look
        let highlightRadius = radius * 0.3
        let highlight = SKShapeNode(circleOfRadius: highlightRadius)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.25)
        highlight.strokeColor = .clear
        highlight.lineWidth = 0
        highlight.position = CGPoint(x: -radius * 0.25, y: radius * 0.25)
        highlight.zPosition = 1
        bubble.addChild(highlight)

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

        // Rise with gentle wobble
        let rise = SKAction.moveTo(y: targetY, duration: riseDuration)
        rise.timingMode = .easeIn

        let wobble = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveBy(x: wobbleAmplitude, y: 0, duration: wobblePeriod / 2),
                SKAction.moveBy(x: -wobbleAmplitude, y: 0, duration: wobblePeriod / 2)
            ])
        )

        // Slight pulsing for organic feel
        let pulse = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.4),
                SKAction.scale(to: 0.95, duration: 0.4)
            ])
        )

        // Fade out at the top if not tapped
        let lifetime = SKAction.sequence([
            appear,
            SKAction.group([rise, wobble, pulse]),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])

        bubble.run(lifetime, withKey: "lifetime")
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
        }

        // Haptic feedback
        HapticManager.shared.light()
        AudioManager.shared.playSFX("pop")

        // Pop animation: scale up + fade out
        let pop = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.15),
            SKAction.fadeOut(withDuration: 0.15)
        ])
        pop.timingMode = .easeOut

        // Spawn small splatter particles on pop
        spawnPopParticles(at: bubble.position, color: bubble.fillColor)

        bubble.run(SKAction.sequence([pop, SKAction.removeFromParent()]))
    }

    private func spawnPopParticles(at position: CGPoint, color: SKColor) {
        let particleCount = Int.random(in: 4...7)
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.lineWidth = 0
            particle.position = position
            particle.zPosition = 35
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...40)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let scatter = SKAction.group([
                SKAction.moveBy(x: dx, y: dy, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.1, duration: 0.3)
            ])
            particle.run(SKAction.sequence([scatter, SKAction.removeFromParent()]))
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
        let timesUpLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timesUpLabel.text = "Time's Up!"
        timesUpLabel.fontSize = 44
        timesUpLabel.fontColor = .white
        timesUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        timesUpLabel.horizontalAlignmentMode = .center
        timesUpLabel.verticalAlignmentMode = .center
        timesUpLabel.zPosition = 200
        timesUpLabel.setScale(0.5)
        timesUpLabel.alpha = 0
        addChild(timesUpLabel)

        let showLabel = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ])
        showLabel.timingMode = .easeOut

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
            onComplete?(0, 1)
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
        onComplete?(score, stars)
    }
}
