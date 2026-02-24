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
        backgroundColor = SKColor(red: 0.72, green: 0.56, blue: 0.40, alpha: 1.0)

        setupCuttingBoard()
        setupBeefBlock()
        setupScissors()
        setupHUD()
        setupInstruction()

        // Start scissors at the top of the beef, moving down
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

    // MARK: - Setup

    private func setupCuttingBoard() {
        let boardWidth = size.width * 0.60
        let boardHeight = size.height * 0.72
        let boardX = size.width / 2
        let boardY = size.height / 2 - 20

        let boardRect = CGRect(x: -boardWidth / 2, y: -boardHeight / 2,
                                width: boardWidth, height: boardHeight)
        cuttingBoard = SKShapeNode(rect: boardRect, cornerRadius: 24)
        cuttingBoard.fillColor = SKColor(red: 0.82, green: 0.68, blue: 0.50, alpha: 1.0)
        cuttingBoard.strokeColor = SKColor(red: 0.65, green: 0.50, blue: 0.35, alpha: 1.0)
        cuttingBoard.lineWidth = 3
        cuttingBoard.position = CGPoint(x: boardX, y: boardY)
        cuttingBoard.zPosition = 1
        addChild(cuttingBoard)

        // Subtle grain lines
        let grainCount = 8
        for i in 0..<grainCount {
            let xOffset = -boardWidth / 2 + CGFloat(i + 1) * (boardWidth / CGFloat(grainCount + 1))
            let grainPath = CGMutablePath()
            grainPath.move(to: CGPoint(x: xOffset, y: -boardHeight / 2 + 20))
            grainPath.addLine(to: CGPoint(x: xOffset + CGFloat.random(in: -8...8),
                                          y: boardHeight / 2 - 20))
            let grain = SKShapeNode(path: grainPath)
            grain.strokeColor = SKColor(red: 0.75, green: 0.60, blue: 0.42, alpha: 0.35)
            grain.lineWidth = 1.5
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

        let beefRect = CGRect(x: -beefWidth / 2, y: -beefHeight / 2,
                               width: beefWidth, height: beefHeight)
        beefBlock = SKShapeNode(rect: beefRect, cornerRadius: 10)
        beefBlock.fillColor = SKColor(red: 0.72, green: 0.18, blue: 0.22, alpha: 1.0)
        beefBlock.strokeColor = SKColor(red: 0.55, green: 0.12, blue: 0.15, alpha: 1.0)
        beefBlock.lineWidth = 2
        beefBlock.position = CGPoint(x: centerX, y: centerY)
        beefBlock.zPosition = 10
        addChild(beefBlock)

        // Marbling detail
        for _ in 0..<6 {
            let marbleWidth = CGFloat.random(in: 30...80)
            let marbleHeight = CGFloat.random(in: 2...5)
            let mx = CGFloat.random(in: (-beefWidth / 2 + 15)...(beefWidth / 2 - 15))
            let my = CGFloat.random(in: (-beefHeight / 2 + 15)...(beefHeight / 2 - 15))
            let marbleRect = CGRect(x: mx - marbleWidth / 2, y: my - marbleHeight / 2,
                                     width: marbleWidth, height: marbleHeight)
            let marble = SKShapeNode(rect: marbleRect, cornerRadius: 2)
            marble.fillColor = SKColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 0.4)
            marble.strokeColor = .clear
            marble.lineWidth = 0
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
        let scissorsEmoji = SKLabelNode(text: "✂️")
        scissorsEmoji.fontSize = 36
        scissorsEmoji.horizontalAlignmentMode = .center
        scissorsEmoji.verticalAlignmentMode = .center
        scissorsEmoji.position = CGPoint(x: beefLeftX - 35, y: 0)
        scissorsEmoji.zRotation = .pi / 2  // point toward the beef
        scissorsNode.addChild(scissorsEmoji)

        // Dashed guide line across the beef
        scissorsLine = SKShapeNode()
        scissorsLine.strokeColor = SKColor(white: 1.0, alpha: 0.5)
        scissorsLine.lineWidth = 2
        scissorsLine.glowWidth = 2
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
            scissorsLine.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 0.6)
        } else {
            scissorsLine.strokeColor = SKColor(white: 1.0, alpha: 0.5)
        }
    }

    // MARK: - HUD

    private func setupHUD() {
        sliceCountLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        sliceCountLabel.text = "Cuts: 0"
        sliceCountLabel.fontSize = 28
        sliceCountLabel.fontColor = .white
        sliceCountLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        sliceCountLabel.horizontalAlignmentMode = .center
        sliceCountLabel.verticalAlignmentMode = .center
        sliceCountLabel.zPosition = 100
        addChild(sliceCountLabel)
    }

    private func setupInstruction() {
        let instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Tap to cut — make as many slices as you can!"
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
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

        // Glowing knife line along the cut
        let knifePath = CGMutablePath()
        knifePath.move(to: CGPoint(x: beefLeftX - 30, y: yPosition))
        knifePath.addLine(to: CGPoint(x: beefRightX + 30, y: yPosition))
        let knifeLine = SKShapeNode(path: knifePath)
        knifeLine.strokeColor = SKColor(white: 0.95, alpha: 0.9)
        knifeLine.lineWidth = 2
        knifeLine.glowWidth = 4
        knifeLine.zPosition = 50
        addChild(knifeLine)
        knifeLine.run(.sequence([
            .wait(forDuration: 0.1),
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))

        AudioManager.shared.playSFX("slice")
        spawnSliceParticles(at: yPosition, beefCenterX: size.width / 2)

        sliceCountLabel.text = "Cuts: \(slicesMade)"
        HapticManager.shared.medium()

        showCutFlash(at: yPosition)
        animateSlicedPiece(from: yPosition, to: beefTopY, spacing: pieceHeight)
        updateBeefBlock(newTopY: yPosition)

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

    // MARK: - Cut Flash

    private func showCutFlash(at yPosition: CGFloat) {
        let flashWidth = beefWidth + 40
        let flash = SKShapeNode(rect: CGRect(x: -flashWidth / 2, y: -1,
                                              width: flashWidth, height: 2),
                                cornerRadius: 1)
        flash.fillColor = .white
        flash.strokeColor = SKColor(white: 1.0, alpha: 0.6)
        flash.lineWidth = 1
        flash.glowWidth = 4
        flash.position = CGPoint(x: size.width / 2, y: yPosition)
        flash.zPosition = 50
        flash.alpha = 0
        addChild(flash)

        let flashIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        let flashOut = SKAction.fadeAlpha(to: 0.0, duration: 0.15)
        flash.run(.sequence([flashIn, flashOut, .removeFromParent()]))
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

        // Subtle marbling line
        let marbleLine = SKShapeNode(rect: CGRect(x: -pieceWidth / 2 + 10,
                                                    y: -0.5,
                                                    width: pieceWidth - 20,
                                                    height: 1))
        marbleLine.fillColor = SKColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 0.35)
        marbleLine.strokeColor = .clear
        marbleLine.zPosition = 0.1
        piece.addChild(marbleLine)

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
            },
            SKAction.moveTo(y: centerY, duration: 0.15)
        ])
        shrinkAction.timingMode = .easeOut
        beefBlock.run(shrinkAction)

        // Refresh marbling — skip if too small to avoid invalid random range
        beefBlock.children.forEach { $0.removeFromParent() }
        if remainingHeight >= 25 {
            for _ in 0..<max(1, Int(remainingHeight / 60)) {
                let marbleWidth = CGFloat.random(in: 30...80)
                let marbleH = CGFloat.random(in: 2...5)
                let mx = CGFloat.random(in: (-beefWidth / 2 + 15)...(beefWidth / 2 - 15))
                let my = CGFloat.random(in: (-remainingHeight / 2 + 10)...(remainingHeight / 2 - 10))
                let mRect = CGRect(x: mx - marbleWidth / 2, y: my - marbleH / 2,
                                    width: marbleWidth, height: marbleH)
                let marble = SKShapeNode(rect: mRect, cornerRadius: 2)
                marble.fillColor = SKColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 0.4)
                marble.strokeColor = .clear
                marble.lineWidth = 0
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
        if slicesMade > 5 {
            stars = 3
        } else if slicesMade > 3 {
            stars = 2
        } else {
            stars = 1
        }

        let score = min(100, slicesMade * 10)

        let doneLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        doneLabel.text = "Slicing Complete!"
        doneLabel.fontSize = 44
        doneLabel.fontColor = .white
        doneLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        doneLabel.horizontalAlignmentMode = .center
        doneLabel.verticalAlignmentMode = .center
        doneLabel.zPosition = 200
        doneLabel.setScale(0.5)
        doneLabel.alpha = 0
        addChild(doneLabel)

        let appear = SKAction.group([
            .fadeAlpha(to: 1.0, duration: 0.3),
            .scale(to: 1.0, duration: 0.3)
        ])
        appear.timingMode = .easeOut

        doneLabel.run(.sequence([appear, .wait(forDuration: 0.8), .fadeAlpha(to: 0, duration: 0.3), .removeFromParent()]))

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

    // MARK: - Slice Particles

    private func spawnSliceParticles(at y: CGFloat, beefCenterX: CGFloat) {
        for _ in 0..<7 {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            p.fillColor = SKColor(red: CGFloat.random(in: 0.7...0.9), green: 0.1, blue: 0.1, alpha: 0.7)
            p.strokeColor = .clear
            p.position = CGPoint(x: beefCenterX + CGFloat.random(in: -60...60), y: y)
            p.zPosition = 40
            addChild(p)
            let dx = CGFloat.random(in: -40...40)
            let dy = CGFloat.random(in: 20...50)
            p.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.4),
                    .fadeOut(withDuration: 0.4),
                    .scale(to: 0.3, duration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }
    }
}
