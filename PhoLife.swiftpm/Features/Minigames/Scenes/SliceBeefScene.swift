import SpriteKit

class SliceBeefScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let beefWidth: CGFloat = 200
    private let beefHeight: CGFloat = 320
    private let minRemainingHeight: CGFloat = 25

    // Scissors movement
    private let scissorsBaseSpeed: CGFloat = 200   // points per second at start
    private let scissorsSpeedIncrease: CGFloat = 40 // additional speed per cut

    // MARK: - State

    private var slicesMade: Int = 0
    private var gameEnded: Bool = false
    private var gameActive: Bool = false
    private var scissorsY: CGFloat = 0             // current Y in scene coordinates
    private var scissorsDirection: CGFloat = -1     // -1 = moving down, 1 = moving up
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Nodes

    private var cuttingBoard: SKShapeNode!
    private var beefBlock: SKShapeNode!
    private var beefShadow: SKShapeNode!
    private var sliceCountLabel: SKLabelNode!
    private var scissorsNode: SKNode!
    private var scissorsLine: SKShapeNode!          // dashed guide line across the beef

    /// Tracks the current top of the beef block (in scene coordinates).
    private var beefTopY: CGFloat = 0
    /// The bottom of the beef block (constant, in scene coordinates).
    private var beefBottomY: CGFloat = 0
    /// The leftmost and rightmost X of the beef block (scene coordinates).
    private var beefLeftX: CGFloat = 0
    private var beefRightX: CGFloat = 0

    /// Running collection of sliced pieces for fan layout.
    private var slicedPieceCount: Int = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.07, blue: 0.03, alpha: 1.0)

        setupBackground()
        setupCuttingBoard()
        setupBeefBlock()
        setupScissors()
        setupHUD()
        setupInstruction()
        setupAmbientSteam()
        addVignette()
        addAmbientParticles(color: SKColor(red: 1.0, green: 0.80, blue: 0.50, alpha: 1), birthRate: 1.0)

        scissorsY = beefTopY - 20
        scissorsDirection = -1
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
        // Warm dark gradient base
        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height * 0.5))
        bottomGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottomGlow.fillColor = SKColor(red: 0.16, green: 0.10, blue: 0.05, alpha: 1.0)
        bottomGlow.strokeColor = .clear
        bottomGlow.zPosition = -10
        addChild(bottomGlow)

        // Warm overhead kitchen light glow
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.15))
        topGlow.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.075)
        topGlow.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 0.12)
        topGlow.strokeColor = .clear
        topGlow.zPosition = -10
        addChild(topGlow)

        // Radial warm spotlight centered on cutting board
        let spotlightGlow = SKShapeNode(circleOfRadius: size.width * 0.35)
        spotlightGlow.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        spotlightGlow.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 0.15)
        spotlightGlow.strokeColor = .clear
        spotlightGlow.zPosition = -9
        addChild(spotlightGlow)

        // Counter surface at bottom
        let counter = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: 90))
        counter.position = CGPoint(x: size.width / 2, y: 45)
        counter.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 1.0)
        counter.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.10, alpha: 0.5)
        counter.lineWidth = 1
        counter.zPosition = -5
        addChild(counter)
    }

    // MARK: - Ambient Steam

    private func setupAmbientSteam() {
        for i in 0..<5 {
            let wisp = SKShapeNode(circleOfRadius: CGFloat.random(in: 10...22))
            wisp.fillColor = SKColor(white: 1.0, alpha: 0.03)
            wisp.strokeColor = .clear
            wisp.position = CGPoint(
                x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                y: size.height * 0.7 + CGFloat(i) * 25
            )
            wisp.zPosition = -2
            addChild(wisp)

            let drift = SKAction.repeatForever(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -25...25), y: 50, duration: 2.5 + Double(i) * 0.4),
                    .fadeAlpha(to: 0.0, duration: 2.5 + Double(i) * 0.4)
                ]),
                .run { [weak self] in
                    guard let self = self else { return }
                    wisp.position = CGPoint(
                        x: CGFloat.random(in: self.size.width * 0.2...self.size.width * 0.8),
                        y: self.size.height * 0.65
                    )
                    wisp.alpha = CGFloat.random(in: 0.02...0.05)
                }
            ]))
            wisp.run(drift)
        }
    }

    // MARK: - Setup

    private func setupCuttingBoard() {
        let boardWidth = size.width * 0.60
        let boardHeight = size.height * 0.72
        let boardX = size.width / 2
        let boardY = size.height / 2 - 20

        // Shadow under the cutting board
        let shadowRect = CGRect(x: -boardWidth / 2 - 6, y: -boardHeight / 2 - 6,
                                 width: boardWidth + 12, height: boardHeight + 12)
        let shadow = SKShapeNode(rect: shadowRect, cornerRadius: 28)
        shadow.fillColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 0.45)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: boardX + 4, y: boardY - 4)
        shadow.zPosition = 0.5
        addChild(shadow)

        let boardRect = CGRect(x: -boardWidth / 2, y: -boardHeight / 2,
                                width: boardWidth, height: boardHeight)
        cuttingBoard = SKShapeNode(rect: boardRect, cornerRadius: 24)
        cuttingBoard.fillColor = SKColor(red: 0.76, green: 0.62, blue: 0.44, alpha: 1.0)
        cuttingBoard.strokeColor = SKColor(red: 0.58, green: 0.44, blue: 0.28, alpha: 1.0)
        cuttingBoard.lineWidth = 3
        cuttingBoard.position = CGPoint(x: boardX, y: boardY)
        cuttingBoard.zPosition = 1
        addChild(cuttingBoard)

        // Top edge highlight for 3D depth
        let highlightRect = CGRect(x: -boardWidth / 2 + 4, y: boardHeight / 2 - 10,
                                    width: boardWidth - 8, height: 6)
        let highlight = SKShapeNode(rect: highlightRect, cornerRadius: 3)
        highlight.fillColor = SKColor(red: 0.88, green: 0.76, blue: 0.58, alpha: 0.4)
        highlight.strokeColor = .clear
        highlight.zPosition = 0.2
        cuttingBoard.addChild(highlight)

        // Subtle grain lines
        let grainCount = 10
        for i in 0..<grainCount {
            let xOffset = -boardWidth / 2 + CGFloat(i + 1) * (boardWidth / CGFloat(grainCount + 1))
            let grainPath = CGMutablePath()
            grainPath.move(to: CGPoint(x: xOffset, y: -boardHeight / 2 + 20))
            grainPath.addCurve(
                to: CGPoint(x: xOffset + CGFloat.random(in: -10...10), y: boardHeight / 2 - 20),
                control1: CGPoint(x: xOffset + CGFloat.random(in: -6...6), y: -boardHeight / 6),
                control2: CGPoint(x: xOffset + CGFloat.random(in: -6...6), y: boardHeight / 6)
            )
            let grain = SKShapeNode(path: grainPath)
            grain.strokeColor = SKColor(red: 0.68, green: 0.54, blue: 0.36, alpha: 0.25)
            grain.lineWidth = 1.2
            grain.zPosition = 0.1
            cuttingBoard.addChild(grain)
        }
    }

    private func setupBeefBlock() {
        let centerX = size.width / 2
        let centerY = size.height / 2 - 20

        beefBottomY = centerY - beefHeight / 2
        beefTopY = centerY + beefHeight / 2
        beefLeftX = centerX - beefWidth / 2
        beefRightX = centerX + beefWidth / 2

        // Beef shadow
        let shadowRect = CGRect(x: -beefWidth / 2 - 3, y: -beefHeight / 2 - 3,
                                 width: beefWidth + 6, height: beefHeight + 6)
        beefShadow = SKShapeNode(rect: shadowRect, cornerRadius: 12)
        beefShadow.fillColor = SKColor(red: 0.06, green: 0.03, blue: 0.01, alpha: 0.35)
        beefShadow.strokeColor = .clear
        beefShadow.position = CGPoint(x: centerX + 3, y: centerY - 3)
        beefShadow.zPosition = 9
        addChild(beefShadow)

        let beefRect = CGRect(x: -beefWidth / 2, y: -beefHeight / 2,
                               width: beefWidth, height: beefHeight)
        beefBlock = SKShapeNode(rect: beefRect, cornerRadius: 10)
        beefBlock.fillColor = SKColor(red: 0.72, green: 0.18, blue: 0.22, alpha: 1.0)
        beefBlock.strokeColor = SKColor(red: 0.55, green: 0.12, blue: 0.15, alpha: 1.0)
        beefBlock.lineWidth = 2
        beefBlock.position = CGPoint(x: centerX, y: centerY)
        beefBlock.zPosition = 10
        addChild(beefBlock)

        // Specular highlight on beef top edge
        let beefHighlight = SKShapeNode(rect: CGRect(x: -beefWidth / 2 + 8, y: beefHeight / 2 - 12,
                                                       width: beefWidth - 16, height: 8),
                                         cornerRadius: 4)
        beefHighlight.fillColor = SKColor(red: 0.85, green: 0.30, blue: 0.32, alpha: 0.35)
        beefHighlight.strokeColor = .clear
        beefHighlight.zPosition = 0.2
        beefBlock.addChild(beefHighlight)

        // Marbling detail -- more lines, varied opacity
        for _ in 0..<8 {
            let marbleWidth = CGFloat.random(in: 30...100)
            let marbleHeight = CGFloat.random(in: 2...5)
            let mx = CGFloat.random(in: (-beefWidth / 2 + 15)...(beefWidth / 2 - 15))
            let my = CGFloat.random(in: (-beefHeight / 2 + 15)...(beefHeight / 2 - 15))
            let marblePath = CGMutablePath()
            marblePath.move(to: CGPoint(x: mx - marbleWidth / 2, y: my))
            marblePath.addCurve(
                to: CGPoint(x: mx + marbleWidth / 2, y: my + CGFloat.random(in: -3...3)),
                control1: CGPoint(x: mx - marbleWidth / 4, y: my + marbleHeight),
                control2: CGPoint(x: mx + marbleWidth / 4, y: my - marbleHeight)
            )
            let marble = SKShapeNode(path: marblePath)
            marble.strokeColor = SKColor(red: 0.92, green: 0.78, blue: 0.72, alpha: CGFloat.random(in: 0.25...0.45))
            marble.lineWidth = CGFloat.random(in: 1.5...3.0)
            marble.fillColor = .clear
            marble.lineCap = .round
            marble.zPosition = 0.1
            beefBlock.addChild(marble)
        }
    }

    // MARK: - Scissors

    private func setupScissors() {
        let centerX = size.width / 2
        scissorsNode = SKNode()
        scissorsNode.zPosition = 30
        addChild(scissorsNode)

        // Scissors emoji on the left side of the beef
        let scissorsEmoji = SKLabelNode(text: "\u{2702}\u{FE0F}")
        scissorsEmoji.fontSize = 40
        scissorsEmoji.horizontalAlignmentMode = .center
        scissorsEmoji.verticalAlignmentMode = .center
        scissorsEmoji.position = CGPoint(x: beefLeftX - 40, y: 0)
        scissorsEmoji.zRotation = .pi / 2  // point toward the beef
        scissorsNode.addChild(scissorsEmoji)

        // Subtle glow behind scissors
        let scissorsGlow = SKShapeNode(circleOfRadius: 22)
        scissorsGlow.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 0.12)
        scissorsGlow.strokeColor = .clear
        scissorsGlow.position = CGPoint(x: beefLeftX - 40, y: 0)
        scissorsGlow.zPosition = -0.1
        scissorsNode.addChild(scissorsGlow)

        // Dashed guide line across the beef
        scissorsLine = SKShapeNode()
        scissorsLine.strokeColor = SKColor(white: 1.0, alpha: 0.5)
        scissorsLine.lineWidth = 2
        scissorsLine.glowWidth = 3
        scissorsLine.zPosition = 25
        addChild(scissorsLine)

        updateScissorsPosition(centerX: centerX)
    }

    private func updateScissorsPosition(centerX: CGFloat) {
        scissorsNode.position = CGPoint(x: centerX, y: scissorsY)

        // Update the guide line
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: beefLeftX, y: scissorsY))
        linePath.addLine(to: CGPoint(x: beefRightX, y: scissorsY))
        scissorsLine.path = linePath

        // Color the line based on proximity to edges (red near top/bottom)
        let distFromTop = beefTopY - scissorsY
        let distFromBottom = scissorsY - beefBottomY
        let minDist = min(distFromTop, distFromBottom)
        let remaining = beefTopY - beefBottomY

        if minDist < 20 || remaining < 30 {
            scissorsLine.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 0.7)
            scissorsLine.glowWidth = 5
        } else {
            // Golden-white line for a warm feel
            scissorsLine.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 0.5)
            scissorsLine.glowWidth = 3
        }
    }

    // MARK: - HUD

    private func setupHUD() {
        // HUD background pill
        let hudBG = SKShapeNode(rectOf: CGSize(width: 180, height: 44), cornerRadius: 22)
        hudBG.position = CGPoint(x: size.width / 2, y: size.height - 160)
        hudBG.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 0.75)
        hudBG.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.20, alpha: 0.5)
        hudBG.lineWidth = 1.5
        hudBG.zPosition = 99
        addChild(hudBG)

        sliceCountLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .bold))
        sliceCountLabel.text = "Cuts: 0"
        sliceCountLabel.fontSize = 28
        sliceCountLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        sliceCountLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        sliceCountLabel.horizontalAlignmentMode = .center
        sliceCountLabel.verticalAlignmentMode = .center
        sliceCountLabel.zPosition = 100
        addChild(sliceCountLabel)
    }

    private func setupInstruction() {
        let instructionLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .medium))
        instructionLabel.text = "Tap to cut \u{2014} time it near the top for the thinnest slices!"
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 0.65)
        instructionLabel.position = CGPoint(x: size.width / 2, y: 60)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        instructionLabel.run(.sequence([
            .wait(forDuration: 4.0),
            .fadeOut(withDuration: 1.0),
            .removeFromParent()
        ]))
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameActive else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = min(currentTime - lastUpdateTime, 0.1)
        lastUpdateTime = currentTime

        // Auto-end if remaining beef is too small
        if beefTopY - beefBottomY <= minRemainingHeight {
            gameActive = false
            scissorsNode.run(.fadeOut(withDuration: 0.3))
            scissorsLine.run(.fadeOut(withDuration: 0.3))
            run(.sequence([
                .wait(forDuration: 1.2),
                .run { [weak self] in self?.endGame() }
            ]))
            return
        }

        // Move scissors
        let currentSpeed = scissorsBaseSpeed + scissorsSpeedIncrease * CGFloat(slicesMade)
        scissorsY += scissorsDirection * currentSpeed * CGFloat(dt)

        // Bounce off the current beef top and bottom
        let topBound = beefTopY - 5
        let bottomBound = beefBottomY + 5

        // Guard against inverted bounds
        guard topBound > bottomBound else {
            gameActive = false
            scissorsNode.run(.fadeOut(withDuration: 0.3))
            scissorsLine.run(.fadeOut(withDuration: 0.3))
            run(.sequence([
                .wait(forDuration: 1.2),
                .run { [weak self] in self?.endGame() }
            ]))
            return
        }

        if scissorsY <= bottomBound {
            scissorsY = bottomBound
            scissorsDirection = 1
        } else if scissorsY >= topBound {
            scissorsY = topBound
            scissorsDirection = -1
        }

        updateScissorsPosition(centerX: size.width / 2)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, !gameEnded else { return }
        processSlice(at: scissorsY)
    }

    // MARK: - Slice Processing

    private func processSlice(at yPosition: CGFloat) {
        let remainingHeight = beefTopY - beefBottomY
        guard remainingHeight > minRemainingHeight else { return }

        // Must be within beef bounds
        guard yPosition > beefBottomY + 5 && yPosition < beefTopY - 5 else { return }

        // The cut splits the beef at this y-position
        // The piece above the cut slides away, the remaining beef is below
        let pieceHeight = beefTopY - yPosition
        guard pieceHeight > 5 else { return }

        slicesMade += 1

        // Glowing knife line along the cut -- golden-white with strong glow
        let knifePath = CGMutablePath()
        knifePath.move(to: CGPoint(x: beefLeftX - 40, y: yPosition))
        knifePath.addLine(to: CGPoint(x: beefRightX + 40, y: yPosition))
        let knifeLine = SKShapeNode(path: knifePath)
        knifeLine.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 0.95)
        knifeLine.lineWidth = 2.5
        knifeLine.glowWidth = 8
        knifeLine.zPosition = 50
        addChild(knifeLine)
        knifeLine.run(.sequence([
            .wait(forDuration: 0.08),
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ]))

        // Secondary warm glow trail
        let glowPath = CGMutablePath()
        glowPath.move(to: CGPoint(x: beefLeftX - 20, y: yPosition))
        glowPath.addLine(to: CGPoint(x: beefRightX + 20, y: yPosition))
        let glowLine = SKShapeNode(path: glowPath)
        glowLine.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.40, alpha: 0.5)
        glowLine.lineWidth = 6
        glowLine.glowWidth = 12
        glowLine.zPosition = 49
        addChild(glowLine)
        glowLine.run(.sequence([
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))

        AudioManager.shared.playSFX("slice")
        shakeCamera(intensity: 3, stepDuration: 0.03)
        expandingRing(at: CGPoint(x: size.width / 2, y: yPosition),
                      color: SKColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 0.6),
                      targetScale: 3.0)
        spawnSliceParticles(at: yPosition, beefCenterX: size.width / 2)

        sliceCountLabel.text = "Cuts: \(slicesMade)"
        // Pulse the label on each cut
        sliceCountLabel.run(.sequence([
            .scale(to: 1.15, duration: 0.08),
            .scale(to: 1.0, duration: 0.1)
        ]))

        HapticManager.shared.medium()

        showCutFlash(at: yPosition)
        animateSlicedPiece(from: yPosition, to: beefTopY, spacing: pieceHeight)
        updateBeefBlock(newTopY: yPosition)

        // Show floating combo text
        showFloatingSliceText(at: yPosition)

        // Clamp scissors to new beef bounds
        let clampBottom = beefBottomY + 5
        let clampTop = beefTopY - 5
        if clampTop > clampBottom {
            scissorsY = min(max(scissorsY, clampBottom), clampTop)
        }

        // Check if remaining beef is too small to continue
        let newRemainingHeight = yPosition - beefBottomY
        if newRemainingHeight <= minRemainingHeight {
            gameActive = false
            scissorsNode.run(.fadeOut(withDuration: 0.3))
            scissorsLine.run(.fadeOut(withDuration: 0.3))
            run(.sequence([
                .wait(forDuration: 1.2),
                .run { [weak self] in self?.endGame() }
            ]))
        }
    }

    // MARK: - Floating Slice Text

    private func showFloatingSliceText(at yPosition: CGFloat) {
        let label = SKLabelNode(fontNamed: Font.roundedName(weight: .heavy))
        label.text = "+\(slicesMade)"
        label.fontSize = 26
        label.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.40, alpha: 1.0)
        label.position = CGPoint(x: beefRightX + 50, y: yPosition)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 95
        label.alpha = 0
        label.setScale(0.6)
        addChild(label)

        label.run(.sequence([
            .group([
                .fadeAlpha(to: 1.0, duration: 0.1),
                .scale(to: 1.0, duration: 0.15),
                .moveBy(x: 20, y: 30, duration: 0.7),
                .sequence([
                    .wait(forDuration: 0.35),
                    .fadeOut(withDuration: 0.35)
                ])
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Cut Flash

    private func showCutFlash(at yPosition: CGFloat) {
        let flashWidth = beefWidth + 60
        let flash = SKShapeNode(rect: CGRect(x: -flashWidth / 2, y: -2,
                                              width: flashWidth, height: 4),
                                cornerRadius: 2)
        flash.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1.0)
        flash.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.50, alpha: 0.6)
        flash.lineWidth = 1
        flash.glowWidth = 8
        flash.position = CGPoint(x: size.width / 2, y: yPosition)
        flash.zPosition = 50
        flash.alpha = 0
        addChild(flash)

        let flashIn = SKAction.fadeAlpha(to: 1.0, duration: 0.04)
        let flashOut = SKAction.fadeAlpha(to: 0.0, duration: 0.20)
        flash.run(.sequence([flashIn, flashOut, .removeFromParent()]))

        // Brief screen-wide warm flash for extra impact
        let screenFlash = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        screenFlash.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 0.0)
        screenFlash.strokeColor = .clear
        screenFlash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        screenFlash.zPosition = 85
        addChild(screenFlash)
        screenFlash.run(.sequence([
            .customAction(withDuration: 0.06) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let t = elapsed / 0.06
                shape.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 0.08 * t)
            },
            .customAction(withDuration: 0.15) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let t = elapsed / 0.15
                shape.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 0.08 * (1 - t))
            },
            .removeFromParent()
        ]))
    }

    // MARK: - Slice Animation

    private func animateSlicedPiece(from cutY: CGFloat, to previousY: CGFloat, spacing: CGFloat) {
        let pieceIndex = slicedPieceCount
        slicedPieceCount += 1

        let pieceHeight = spacing
        let pieceWidth = beefWidth

        let pieceRect = CGRect(x: -pieceWidth / 2, y: -pieceHeight / 2,
                                width: pieceWidth, height: pieceHeight)
        let piece = SKShapeNode(rect: pieceRect, cornerRadius: 4)

        let redVariation = CGFloat.random(in: -0.05...0.05)
        piece.fillColor = SKColor(red: 0.72 + redVariation,
                                   green: 0.18 + redVariation * 0.5,
                                   blue: 0.22 + redVariation * 0.3,
                                   alpha: 1.0)
        piece.strokeColor = SKColor(red: 0.55 + redVariation,
                                     green: 0.12,
                                     blue: 0.15,
                                     alpha: 0.8)
        piece.lineWidth = 1.5

        // Subtle marbling lines on the piece
        let marbleCount = max(1, Int(pieceHeight / 15))
        for _ in 0..<marbleCount {
            let mWidth = CGFloat.random(in: pieceWidth * 0.3...pieceWidth * 0.8)
            let mPath = CGMutablePath()
            let mY = CGFloat.random(in: -pieceHeight / 2 + 3...pieceHeight / 2 - 3)
            mPath.move(to: CGPoint(x: -mWidth / 2, y: mY))
            mPath.addCurve(
                to: CGPoint(x: mWidth / 2, y: mY + CGFloat.random(in: -2...2)),
                control1: CGPoint(x: -mWidth / 4, y: mY + 2),
                control2: CGPoint(x: mWidth / 4, y: mY - 2)
            )
            let marble = SKShapeNode(path: mPath)
            marble.strokeColor = SKColor(red: 0.92, green: 0.78, blue: 0.72, alpha: 0.30)
            marble.lineWidth = 1.5
            marble.fillColor = .clear
            marble.lineCap = .round
            marble.zPosition = 0.1
            piece.addChild(marble)
        }

        let pieceCenterY = cutY + pieceHeight / 2
        piece.position = CGPoint(x: size.width / 2, y: pieceCenterY)
        piece.zPosition = 8
        addChild(piece)

        // Fan target: right side of the cutting board
        let fanBaseX = size.width * 0.82
        let fanBaseY = size.height * 0.25
        let fanSpacing: CGFloat = 22
        let targetY = fanBaseY + CGFloat(pieceIndex) * fanSpacing
        let targetX = fanBaseX + CGFloat.random(in: -10...10)
        let targetRotation = CGFloat.random(in: -0.12...0.12)

        let slideAction = SKAction.group([
            .move(to: CGPoint(x: targetX, y: targetY), duration: 0.5),
            .rotate(toAngle: targetRotation, duration: 0.5),
            .scale(to: 0.85, duration: 0.5)
        ])
        slideAction.timingMode = .easeInEaseOut
        piece.run(slideAction)
    }

    // MARK: - Beef Block Update

    private func updateBeefBlock(newTopY: CGFloat) {
        beefTopY = newTopY

        let remainingHeight = beefTopY - beefBottomY
        let centerY = beefBottomY + remainingHeight / 2

        let beefRect = CGRect(x: -beefWidth / 2, y: -remainingHeight / 2,
                               width: beefWidth, height: remainingHeight)

        let shrinkAction = SKAction.group([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.beefBlock.path = CGPath(roundedRect: beefRect,
                                              cornerWidth: 10,
                                              cornerHeight: 10,
                                              transform: nil)
                // Update shadow too
                let shadowRect = CGRect(x: -self.beefWidth / 2 - 3, y: -remainingHeight / 2 - 3,
                                         width: self.beefWidth + 6, height: remainingHeight + 6)
                self.beefShadow.path = CGPath(roundedRect: shadowRect,
                                               cornerWidth: 12,
                                               cornerHeight: 12,
                                               transform: nil)
            },
            SKAction.moveTo(y: centerY, duration: 0.15)
        ])
        shrinkAction.timingMode = .easeOut
        beefBlock.run(shrinkAction)
        beefShadow.run(.moveTo(y: centerY - 3, duration: 0.15))

        // Refresh marbling -- skip if too small to avoid invalid random range
        beefBlock.children.forEach { $0.removeFromParent() }
        if remainingHeight >= 25 {
            for _ in 0..<max(1, Int(remainingHeight / 45)) {
                let marbleWidth = CGFloat.random(in: 30...90)
                let marbleH = CGFloat.random(in: 2...4)
                let mx = CGFloat.random(in: (-beefWidth / 2 + 15)...(beefWidth / 2 - 15))
                let my = CGFloat.random(in: (-remainingHeight / 2 + 10)...(remainingHeight / 2 - 10))
                let mPath = CGMutablePath()
                mPath.move(to: CGPoint(x: mx - marbleWidth / 2, y: my))
                mPath.addCurve(
                    to: CGPoint(x: mx + marbleWidth / 2, y: my + CGFloat.random(in: -2...2)),
                    control1: CGPoint(x: mx - marbleWidth / 4, y: my + marbleH),
                    control2: CGPoint(x: mx + marbleWidth / 4, y: my - marbleH)
                )
                let marble = SKShapeNode(path: mPath)
                marble.strokeColor = SKColor(red: 0.92, green: 0.78, blue: 0.72, alpha: CGFloat.random(in: 0.25...0.40))
                marble.lineWidth = CGFloat.random(in: 1.5...2.5)
                marble.fillColor = .clear
                marble.lineCap = .round
                marble.zPosition = 0.1
                beefBlock.addChild(marble)
            }
        }
    }

    // MARK: - End Game

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true

        let stars: Int
        if slicesMade > 2 {
            stars = 3
        } else if slicesMade > 1 {
            stars = 2
        } else {
            stars = 1
        }

        let score = min(100, slicesMade * 10)

        // Golden burst particles for completion
        spawnCompletionBurst()

        let doneLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .heavy))
        doneLabel.text = "Slicing Complete!"
        doneLabel.fontSize = 44
        doneLabel.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.60, alpha: 1.0)
        doneLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        doneLabel.horizontalAlignmentMode = .center
        doneLabel.verticalAlignmentMode = .center
        doneLabel.zPosition = 200
        doneLabel.setScale(0.5)
        doneLabel.alpha = 0
        addChild(doneLabel)

        // Score subtitle
        let scoreLabel = SKLabelNode(fontNamed: Font.roundedName(weight: .bold))
        scoreLabel.text = "\(slicesMade) slices"
        scoreLabel.fontSize = 26
        scoreLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 200
        scoreLabel.alpha = 0
        addChild(scoreLabel)

        let appear = SKAction.group([
            .fadeAlpha(to: 1.0, duration: 0.3),
            .scale(to: 1.1, duration: 0.3)
        ])
        appear.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)

        doneLabel.run(.sequence([appear, settle, .wait(forDuration: 0.8), .fadeAlpha(to: 0, duration: 0.3), .removeFromParent()]))
        scoreLabel.run(.sequence([.wait(forDuration: 0.15), .fadeAlpha(to: 1.0, duration: 0.25), .wait(forDuration: 0.85), .fadeAlpha(to: 0, duration: 0.3), .removeFromParent()]))

        HapticManager.shared.success()

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
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

    // MARK: - Completion Burst

    private func spawnCompletionBurst() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for _ in 0..<18 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            sparkle.fillColor = SKColor(
                red: CGFloat.random(in: 0.90...1.0),
                green: CGFloat.random(in: 0.75...0.92),
                blue: CGFloat.random(in: 0.20...0.50),
                alpha: 1.0
            )
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 2
            sparkle.position = center
            sparkle.zPosition = 90
            addChild(sparkle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...160)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.5...1.0)

            sparkle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: lifetime),
                    .fadeOut(withDuration: lifetime),
                    .scale(to: 0.1, duration: lifetime)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Slice Particles

    private func spawnSliceParticles(at y: CGFloat, beefCenterX: CGFloat) {
        // More particles, varied sizes, warm colors mixed with red
        for _ in 0..<12 {
            let radius = CGFloat.random(in: 1.5...4.5)
            let p = SKShapeNode(circleOfRadius: radius)
            let isWarmSpark = Bool.random()
            if isWarmSpark {
                p.fillColor = SKColor(
                    red: CGFloat.random(in: 0.90...1.0),
                    green: CGFloat.random(in: 0.70...0.90),
                    blue: CGFloat.random(in: 0.30...0.50),
                    alpha: 0.85
                )
            } else {
                p.fillColor = SKColor(
                    red: CGFloat.random(in: 0.70...0.92),
                    green: CGFloat.random(in: 0.08...0.20),
                    blue: CGFloat.random(in: 0.08...0.18),
                    alpha: 0.80
                )
            }
            p.strokeColor = .clear
            p.glowWidth = isWarmSpark ? 2 : 0
            p.position = CGPoint(x: beefCenterX + CGFloat.random(in: -80...80), y: y)
            p.zPosition = 40
            addChild(p)
            let dx = CGFloat.random(in: -50...50)
            let dy = CGFloat.random(in: -10...60)
            let duration = Double.random(in: 0.3...0.6)
            p.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: duration),
                    .fadeOut(withDuration: duration),
                    .scale(to: 0.2, duration: duration)
                ]),
                .removeFromParent()
            ]))
        }
    }
}
