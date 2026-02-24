import SpriteKit

class SliceBeefScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let totalSlices: Int = 8
    private let beefWidth: CGFloat = 200
    private let beefHeight: CGFloat = 320
    private let idealSpacingFraction: CGFloat = 0.12   // ~12% of original height per slice
    private let perfectThreshold: CGFloat = 0.15       // within ±15% of ideal
    private let goodThreshold: CGFloat = 0.30          // within ±30% of ideal

    // MARK: - State

    private var slicesMade: Int = 0
    private var totalPoints: Int = 0
    private var gameEnded: Bool = false

    /// Y-positions of previous cuts in the beef block's local coordinate system (0 = bottom, beefHeight = top).
    /// The first cut is measured from the top of the beef.
    private var cutPositionsLocal: [CGFloat] = []

    /// The ideal spacing in points, based on original beef height.
    private var idealSpacing: CGFloat { beefHeight * idealSpacingFraction }

    // MARK: - Touch Tracking

    private var touchStartPoint: CGPoint?

    // MARK: - Nodes

    private var cuttingBoard: SKShapeNode!
    private var beefBlock: SKShapeNode!
    private var sliceCountLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var qualityLabel: SKLabelNode!

    /// Tracks the current top of the beef block (in scene coordinates).
    /// Starts at the top edge of the original beef position.
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
        backgroundColor = SKColor(red: 0.72, green: 0.56, blue: 0.40, alpha: 1.0) // warm wood

        setupCuttingBoard()
        setupBeefBlock()
        setupHUD()
        setupInstruction()
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
        beefBlock.fillColor = SKColor(red: 0.72, green: 0.18, blue: 0.22, alpha: 1.0) // deep red
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

    private func setupHUD() {
        // Slice counter — top-left area
        sliceCountLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        sliceCountLabel.text = "Slice 0/\(totalSlices)"
        sliceCountLabel.fontSize = 28
        sliceCountLabel.fontColor = .white
        sliceCountLabel.position = CGPoint(x: size.width / 2, y: size.height - 70)
        sliceCountLabel.horizontalAlignmentMode = .center
        sliceCountLabel.verticalAlignmentMode = .center
        sliceCountLabel.zPosition = 100
        addChild(sliceCountLabel)

        // Score — top-right
        scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 70)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        // Quality indicator — appears after each cut, below the slice counter
        qualityLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        qualityLabel.text = ""
        qualityLabel.fontSize = 36
        qualityLabel.fontColor = .white
        qualityLabel.position = CGPoint(x: size.width / 2, y: size.height - 115)
        qualityLabel.horizontalAlignmentMode = .center
        qualityLabel.verticalAlignmentMode = .center
        qualityLabel.zPosition = 100
        qualityLabel.alpha = 0
        addChild(qualityLabel)
    }

    private func setupInstruction() {
        let instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Swipe horizontally across the beef to slice!"
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        instructionLabel.position = CGPoint(x: size.width / 2, y: 60)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])
        instructionLabel.run(fadeAction)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, let touch = touches.first else { return }
        touchStartPoint = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, let touch = touches.first, let startPoint = touchStartPoint else { return }
        let endPoint = touch.location(in: self)
        touchStartPoint = nil

        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y

        // Check if swipe is roughly horizontal: |dx| > 100, |dy| < 80
        guard abs(dx) > 100, abs(dy) < 80 else { return }

        // Check if swipe crosses the beef's x-range
        let swipeMinX = min(startPoint.x, endPoint.x)
        let swipeMaxX = max(startPoint.x, endPoint.x)
        guard swipeMinX <= beefLeftX && swipeMaxX >= beefRightX else { return }

        // The cut y-position is the average y of the swipe at the beef center
        let swipeY = (startPoint.y + endPoint.y) / 2

        // Must be within the current beef block bounds
        guard swipeY > beefBottomY && swipeY < beefTopY else { return }

        processSlice(at: swipeY)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = nil
    }

    // MARK: - Slice Processing

    private func processSlice(at yPosition: CGFloat) {
        guard slicesMade < totalSlices else { return }

        // Calculate spacing from the previous cut (or from the top of the beef)
        let previousCutY: CGFloat
        if cutPositionsLocal.isEmpty {
            previousCutY = beefTopY
        } else {
            previousCutY = cutPositionsLocal.last!
        }

        let spacing = previousCutY - yPosition
        // Reject cuts that go upward (above the previous cut) or are tiny
        guard spacing > 5 else { return }

        cutPositionsLocal.append(yPosition)
        slicesMade += 1

        // Score the slice based on spacing vs ideal
        let deviation = abs(spacing - idealSpacing) / idealSpacing
        let points: Int
        let qualityText: String
        let qualityColor: SKColor

        AudioManager.shared.playSFX("slice")

        if deviation <= perfectThreshold {
            points = 3
            qualityText = "Perfect!"
            qualityColor = SKColor(red: 0.2, green: 0.9, blue: 0.35, alpha: 1)
            AudioManager.shared.playSFX("success-chime")
        } else if deviation <= goodThreshold {
            points = 2
            qualityText = "Good"
            qualityColor = SKColor(red: 0.95, green: 0.85, blue: 0.25, alpha: 1)
        } else {
            points = 1
            qualityText = "Uneven"
            qualityColor = SKColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1)
        }

        totalPoints += points

        // Update HUD
        sliceCountLabel.text = "Slice \(slicesMade)/\(totalSlices)"
        scoreLabel.text = "Score: \(totalPoints)"

        // Haptic feedback
        if points == 3 {
            HapticManager.shared.medium()
        } else {
            HapticManager.shared.light()
        }

        // Show quality indicator
        showQualityFeedback(qualityText, color: qualityColor, points: points)

        // Show cut flash
        showCutFlash(at: yPosition)

        // Animate the sliced piece
        animateSlicedPiece(from: yPosition, to: previousCutY, spacing: spacing)

        // Update the beef block (shrink from top)
        updateBeefBlock(newTopY: yPosition)

        // Check completion
        if slicesMade >= totalSlices {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.2),
                SKAction.run { [weak self] in
                    self?.endGame()
                }
            ]))
        }
    }

    // MARK: - Quality Feedback

    private func showQualityFeedback(_ text: String, color: SKColor, points: Int) {
        qualityLabel.removeAllActions()
        qualityLabel.text = text
        qualityLabel.fontColor = color
        qualityLabel.alpha = 0
        qualityLabel.setScale(0.6)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.12),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        appear.timingMode = .easeOut

        let hold = SKAction.wait(forDuration: 0.6)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.3)

        qualityLabel.run(SKAction.sequence([appear, hold, fadeOut]))

        // Floating points label near the cut
        let pointsLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        pointsLabel.text = "+\(points)"
        pointsLabel.fontSize = 28
        pointsLabel.fontColor = color
        pointsLabel.position = CGPoint(x: size.width / 2 + 130, y: qualityLabel.position.y)
        pointsLabel.horizontalAlignmentMode = .center
        pointsLabel.verticalAlignmentMode = .center
        pointsLabel.zPosition = 100
        pointsLabel.alpha = 0
        addChild(pointsLabel)

        pointsLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.12),
                SKAction.moveBy(x: 0, y: 25, duration: 0.8)
            ]),
            SKAction.fadeAlpha(to: 0.0, duration: 0.3),
            SKAction.removeFromParent()
        ]))
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
        flash.run(SKAction.sequence([flashIn, flashOut, SKAction.removeFromParent()]))
    }

    // MARK: - Slice Animation

    private func animateSlicedPiece(from cutY: CGFloat, to previousY: CGFloat, spacing: CGFloat) {
        let pieceIndex = slicedPieceCount
        slicedPieceCount += 1

        let pieceHeight = spacing
        let pieceWidth = beefWidth

        // Create the slice piece node
        let pieceRect = CGRect(x: -pieceWidth / 2, y: -pieceHeight / 2,
                                width: pieceWidth, height: pieceHeight)
        let piece = SKShapeNode(rect: pieceRect, cornerRadius: 4)

        // Slightly varied red/pink for each slice
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

        // Add a subtle marbling line on the slice
        let marbleLine = SKShapeNode(rect: CGRect(x: -pieceWidth / 2 + 10,
                                                    y: -0.5,
                                                    width: pieceWidth - 20,
                                                    height: 1))
        marbleLine.fillColor = SKColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 0.35)
        marbleLine.strokeColor = .clear
        marbleLine.zPosition = 0.1
        piece.addChild(marbleLine)

        // Start position: at the cut location on the beef
        let pieceCenterY = cutY + pieceHeight / 2
        piece.position = CGPoint(x: size.width / 2, y: pieceCenterY)
        piece.zPosition = 8
        addChild(piece)

        // Fan target: right side of the cutting board, stacked vertically with slight rotation
        let fanBaseX = size.width * 0.82
        let fanBaseY = size.height * 0.25
        let fanSpacing: CGFloat = 22
        let targetY = fanBaseY + CGFloat(pieceIndex) * fanSpacing
        let targetX = fanBaseX + CGFloat.random(in: -10...10)
        let targetRotation = CGFloat.random(in: -0.12...0.12)

        // Slide right and rotate
        let slideAction = SKAction.group([
            SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.5),
            SKAction.rotate(toAngle: targetRotation, duration: 0.5),
            SKAction.scale(to: 0.85, duration: 0.5)
        ])
        slideAction.timingMode = .easeInEaseOut

        piece.run(slideAction)
    }

    // MARK: - Beef Block Update

    private func updateBeefBlock(newTopY: CGFloat) {
        beefTopY = newTopY

        let remainingHeight = beefTopY - beefBottomY
        let centerY = beefBottomY + remainingHeight / 2

        // Rebuild the beef block path
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

        // Remove old marbling and re-add for the new size
        beefBlock.children.forEach { $0.removeFromParent() }
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

    // MARK: - End Game

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true

        // Calculate stars: 20+ out of 24 = 3 stars, 14+ = 2 stars, else 1
        let stars: Int
        if totalPoints >= 20 {
            stars = 3
        } else if totalPoints >= 14 {
            stars = 2
        } else {
            stars = 1
        }

        // Score = (totalPoints / 24) * 100
        let score = Int((Double(totalPoints) / 24.0) * 100.0)

        // Show completion label
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
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        appear.timingMode = .easeOut

        let hold = SKAction.wait(forDuration: 0.8)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.3)

        doneLabel.run(SKAction.sequence([appear, hold, fadeOut, SKAction.removeFromParent()]))

        HapticManager.shared.success()

        // Report score after delay
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.onComplete?(score, stars)
            }
        ]))
    }
}
