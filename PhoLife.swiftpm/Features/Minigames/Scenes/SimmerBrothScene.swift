import SpriteKit

class SimmerBrothScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let gameDuration: TimeInterval = 35.0
    private let postGameDelay: TimeInterval = 1.2

    // Player bar physics (Stardew-style: tap to rise, release to fall)
    private let riseAcceleration: CGFloat = 0.9      // upward push per second while touching
    private let gravity: CGFloat = 1.2               // downward pull per second
    private let maxVelocity: CGFloat = 0.5           // clamp velocity
    private let startPosition: CGFloat = 0.3

    // Green zone (the "fish") -- moves on its own
    private let zoneStartSize: CGFloat = 0.22        // 22% of gauge at start
    private let zoneEndSize: CGFloat = 0.15          // shrinks to 15%
    private let zoneBaseSpeed: CGFloat = 0.25        // base movement speed
    private let zoneSpeedIncrease: CGFloat = 0.15    // speed increase over game
    private let zoneDirectionMinTime: TimeInterval = 1.2
    private let zoneDirectionMaxTime: TimeInterval = 3.0

    // MARK: - State

    private var playerPosition: CGFloat = 0.3        // 0...1
    private var playerVelocity: CGFloat = 0
    private var isTouching: Bool = false
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var gameActive: Bool = false
    private var gameEnded: Bool = false

    // Green zone movement
    private var zoneCenter: CGFloat = 0.5
    private var zoneVelocity: CGFloat = 0.2
    private var zoneDirectionTimer: TimeInterval = 2.0

    // Scoring
    private var timeInZone: TimeInterval = 0
    private var wasInSimmerZone: Bool = false

    // MARK: - Layout Constants

    private let gaugeX: CGFloat = 70
    private let gaugeWidth: CGFloat = 40
    private let gaugeHeight: CGFloat = 500
    private var gaugeBottomY: CGFloat { return 140 }

    private var potCenterX: CGFloat { return size.width * 0.52 }
    private var potCenterY: CGFloat { return size.height * 0.38 }
    private let potWidth: CGFloat = 320
    private let potHeight: CGFloat = 180
    private let stoveWidth: CGFloat = 400
    private let stoveHeight: CGFloat = 60

    // MARK: - Nodes

    // Gauge
    private var gaugeBackground: SKShapeNode!
    private var gaugeFillTrack: SKShapeNode!
    private var gaugeZoneBand: SKShapeNode!
    private var gaugeZoneGlow: SKShapeNode!
    private var gaugeIndicator: SKShapeNode!
    private var gaugeIndicatorGlow: SKShapeNode!

    // Pot & stove
    private var stoveNode: SKShapeNode!
    private var potBody: SKShapeNode!
    private var potRim: SKShapeNode!
    private var brothSurface: SKShapeNode!
    private var brothHighlight: SKShapeNode!

    // Flames
    private var flameNodes: [SKShapeNode] = []
    private let flameCount: Int = 5

    // Bubbles (programmatic emitter)
    private var bubbleEmitter: SKEmitterNode!

    // Steam
    private var steamEmitter: SKEmitterNode!

    // Pot glow & lid
    private var potGlow: SKShapeNode!
    private var lidNode: SKShapeNode!

    // Ambient
    private var ambientEmitter: SKEmitterNode!
    private var flameGlow: SKShapeNode!

    // HUD
    private var timerLabel: SKLabelNode!
    private var zonePercentLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1)

        buildBackground()
        buildGauge()
        buildStoveAndPot()
        buildFlames()
        buildBrothSurface()
        buildBubbleEmitter()
        buildSteamEmitter()
        buildAmbientParticles()
        buildHUD()

        playerPosition = startPosition
        zoneCenter = 0.5
        zoneVelocity = zoneBaseSpeed
        zoneDirectionTimer = zoneDirectionMaxTime
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

    private func buildBackground() {
        let floor = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.25))
        floor.position = CGPoint(x: size.width / 2, y: size.height * 0.125)
        floor.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 1)
        floor.strokeColor = .clear
        floor.zPosition = -10
        addChild(floor)

        let wall = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.75))
        wall.position = CGPoint(x: size.width / 2, y: size.height * 0.625)
        wall.fillColor = SKColor(red: 0.13, green: 0.08, blue: 0.04, alpha: 1)
        wall.strokeColor = .clear
        wall.zPosition = -10
        addChild(wall)

        // Warm central glow behind pot
        let glow = SKShapeNode(circleOfRadius: 240)
        glow.position = CGPoint(x: potCenterX, y: potCenterY - 30)
        glow.fillColor = SKColor(red: 0.40, green: 0.18, blue: 0.05, alpha: 0.12)
        glow.strokeColor = .clear
        glow.zPosition = -5
        addChild(glow)

        // Secondary glow under stove
        let stoveGlow = SKShapeNode(circleOfRadius: 180)
        stoveGlow.position = CGPoint(x: potCenterX, y: potCenterY - potHeight / 2 - 20)
        stoveGlow.fillColor = SKColor(red: 0.85, green: 0.30, blue: 0.05, alpha: 0.06)
        stoveGlow.strokeColor = .clear
        stoveGlow.zPosition = -4
        addChild(stoveGlow)

        // Vignette for depth
        let vignetteSize = max(size.width, size.height) * 1.2
        let vignette = SKShapeNode(circleOfRadius: vignetteSize / 2)
        vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor(red: 0.03, green: 0.02, blue: 0.01, alpha: 0.5)
        vignette.lineWidth = vignetteSize * 0.22
        vignette.zPosition = -1
        addChild(vignette)
    }

    // MARK: - Gauge

    private func buildGauge() {
        let gaugeRect = CGRect(x: -gaugeWidth / 2, y: 0, width: gaugeWidth, height: gaugeHeight)

        // Shadow behind gauge
        let gaugeShadow = SKShapeNode(rect: gaugeRect.insetBy(dx: -3, dy: -3), cornerRadius: 10)
        gaugeShadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.35)
        gaugeShadow.strokeColor = .clear
        gaugeShadow.position = CGPoint(x: gaugeX + 2, y: gaugeBottomY - 2)
        gaugeShadow.zPosition = 4.5
        addChild(gaugeShadow)

        // Dark background
        gaugeBackground = SKShapeNode(rect: gaugeRect, cornerRadius: 8)
        gaugeBackground.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        gaugeBackground.strokeColor = SKColor(white: 0.25, alpha: 0.8)
        gaugeBackground.lineWidth = 2
        gaugeBackground.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeBackground.zPosition = 5
        addChild(gaugeBackground)

        // Inner fill track (subtle gradient simulation)
        let innerRect = CGRect(x: -gaugeWidth / 2 + 3, y: 3,
                               width: gaugeWidth - 6, height: gaugeHeight - 6)
        gaugeFillTrack = SKShapeNode(rect: innerRect, cornerRadius: 5)
        gaugeFillTrack.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
        gaugeFillTrack.strokeColor = .clear
        gaugeFillTrack.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeFillTrack.zPosition = 5.2
        addChild(gaugeFillTrack)

        // Tick marks on gauge
        for i in 1..<10 {
            let tickY = gaugeBottomY + CGFloat(i) * (gaugeHeight / 10)
            let tickWidth: CGFloat = i == 5 ? gaugeWidth * 0.6 : gaugeWidth * 0.3
            let tick = SKShapeNode(rectOf: CGSize(width: tickWidth, height: 1))
            tick.fillColor = SKColor(white: 0.25, alpha: 0.3)
            tick.strokeColor = .clear
            tick.position = CGPoint(x: gaugeX, y: tickY)
            tick.zPosition = 5.3
            addChild(tick)
        }

        // Green zone glow (outer soft glow)
        gaugeZoneGlow = SKShapeNode()
        gaugeZoneGlow.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeZoneGlow.zPosition = 6
        addChild(gaugeZoneGlow)

        // Green zone band (moves like the fish)
        gaugeZoneBand = SKShapeNode()
        gaugeZoneBand.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeZoneBand.zPosition = 6.5
        addChild(gaugeZoneBand)

        // Indicator glow (behind indicator)
        gaugeIndicatorGlow = SKShapeNode(rect: CGRect(x: -gaugeWidth / 2 - 10, y: -5,
                                                       width: gaugeWidth + 20, height: 10),
                                          cornerRadius: 5)
        gaugeIndicatorGlow.fillColor = SKColor(white: 1.0, alpha: 0.10)
        gaugeIndicatorGlow.strokeColor = .clear
        gaugeIndicatorGlow.zPosition = 7.5
        gaugeIndicatorGlow.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        addChild(gaugeIndicatorGlow)

        // White player indicator bar
        gaugeIndicator = SKShapeNode(rect: CGRect(x: -gaugeWidth / 2 - 6, y: -2.5,
                                                    width: gaugeWidth + 12, height: 5),
                                     cornerRadius: 2.5)
        gaugeIndicator.fillColor = .white
        gaugeIndicator.strokeColor = .clear
        gaugeIndicator.glowWidth = 4
        gaugeIndicator.zPosition = 8
        gaugeIndicator.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        addChild(gaugeIndicator)

        updateGaugeZoneBand()
    }

    private func currentZoneSize() -> CGFloat {
        let progress = CGFloat(min(elapsedTime / gameDuration, 1.0))
        return zoneStartSize + (zoneEndSize - zoneStartSize) * progress
    }

    private func updateGaugeZoneBand() {
        let halfZone = currentZoneSize() / 2
        let zoneLow = max(0, zoneCenter - halfZone)
        let zoneHigh = min(1, zoneCenter + halfZone)

        let bandY = zoneLow * gaugeHeight
        let bandH = (zoneHigh - zoneLow) * gaugeHeight

        let rect = CGRect(x: -gaugeWidth / 2 - 2, y: bandY,
                          width: gaugeWidth + 4, height: bandH)

        // Glow layer
        gaugeZoneGlow.path = CGPath(roundedRect: rect.insetBy(dx: -5, dy: -5),
                                     cornerWidth: 7, cornerHeight: 7, transform: nil)
        gaugeZoneGlow.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.08)
        gaugeZoneGlow.strokeColor = .clear
        gaugeZoneGlow.glowWidth = 8

        // Sharp band with improved gradient feel
        gaugeZoneBand.path = CGPath(roundedRect: rect, cornerWidth: 4,
                                     cornerHeight: 4, transform: nil)

        let inZone = isInSimmerZone()
        if inZone {
            gaugeZoneBand.fillColor = SKColor(red: 0.2, green: 0.88, blue: 0.35, alpha: 0.30)
            gaugeZoneBand.strokeColor = SKColor(red: 0.25, green: 0.95, blue: 0.35, alpha: 0.8)
        } else {
            gaugeZoneBand.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 0.22)
            gaugeZoneBand.strokeColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.6)
        }
        gaugeZoneBand.lineWidth = 1.5
        gaugeZoneBand.glowWidth = inZone ? 4 : 2.5
    }

    private func updateGaugeIndicator() {
        let yPos = gaugeBottomY + playerPosition * gaugeHeight
        gaugeIndicator.position = CGPoint(x: gaugeX, y: yPos)
        gaugeIndicatorGlow.position = CGPoint(x: gaugeX, y: yPos)

        let inZone = isInSimmerZone()
        if inZone {
            gaugeIndicator.fillColor = SKColor(red: 0.7, green: 1.0, blue: 0.75, alpha: 1)
            gaugeIndicator.glowWidth = 5
            gaugeIndicatorGlow.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.15)
        } else {
            gaugeIndicator.fillColor = .white
            gaugeIndicator.glowWidth = 3
            gaugeIndicatorGlow.fillColor = SKColor(white: 1.0, alpha: 0.08)
        }
    }

    // MARK: - Stove & Pot

    private func buildStoveAndPot() {
        let stoveY = potCenterY - potHeight / 2 - stoveHeight / 2 + 10

        // Stove shadow
        let stoveShadow = SKShapeNode(rectOf: CGSize(width: stoveWidth + 10, height: stoveHeight + 6),
                                       cornerRadius: 8)
        stoveShadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        stoveShadow.strokeColor = .clear
        stoveShadow.position = CGPoint(x: potCenterX + 3, y: stoveY - 3)
        stoveShadow.zPosition = 0.5
        addChild(stoveShadow)

        stoveNode = SKShapeNode(rectOf: CGSize(width: stoveWidth, height: stoveHeight),
                                cornerRadius: 6)
        stoveNode.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        stoveNode.strokeColor = SKColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        stoveNode.lineWidth = 2
        stoveNode.position = CGPoint(x: potCenterX, y: stoveY)
        stoveNode.zPosition = 1
        addChild(stoveNode)

        // Stove top highlight
        let stoveHighlight = SKShapeNode(rectOf: CGSize(width: stoveWidth - 20, height: 2))
        stoveHighlight.fillColor = SKColor(white: 0.2, alpha: 0.15)
        stoveHighlight.strokeColor = .clear
        stoveHighlight.position = CGPoint(x: potCenterX, y: stoveY + stoveHeight / 2 - 2)
        stoveHighlight.zPosition = 1.2
        addChild(stoveHighlight)

        // Burner ring
        let ring = SKShapeNode(circleOfRadius: 80)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.15, alpha: 0.5)
        ring.lineWidth = 3
        ring.position = CGPoint(x: potCenterX, y: stoveY + stoveHeight / 2 + 5)
        ring.zPosition = 1.5
        addChild(ring)

        // Inner burner ring
        let innerRing = SKShapeNode(circleOfRadius: 55)
        innerRing.fillColor = .clear
        innerRing.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 0.3)
        innerRing.lineWidth = 2
        innerRing.position = CGPoint(x: potCenterX, y: stoveY + stoveHeight / 2 + 5)
        innerRing.zPosition = 1.5
        addChild(innerRing)

        // Flame glow disc on stove
        flameGlow = SKShapeNode(circleOfRadius: 90)
        flameGlow.fillColor = SKColor(red: 0.90, green: 0.40, blue: 0.05, alpha: 0.0)
        flameGlow.strokeColor = .clear
        flameGlow.position = CGPoint(x: potCenterX, y: stoveY + stoveHeight / 2 + 5)
        flameGlow.zPosition = 2
        addChild(flameGlow)

        // Pot shadow
        let potShadow = SKShapeNode(rect: CGRect(x: -potWidth / 2 + 5, y: -potHeight / 2 + 5,
                                                   width: potWidth, height: potHeight),
                                     cornerRadius: 30)
        potShadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)
        potShadow.strokeColor = .clear
        potShadow.position = CGPoint(x: potCenterX + 3, y: potCenterY - 3)
        potShadow.zPosition = 9.5
        addChild(potShadow)

        let potRect = CGRect(x: -potWidth / 2, y: -potHeight / 2,
                              width: potWidth, height: potHeight)
        potBody = SKShapeNode(rect: potRect, cornerRadius: 30)
        potBody.fillColor = SKColor(red: 0.18, green: 0.16, blue: 0.14, alpha: 1)
        potBody.strokeColor = SKColor(red: 0.28, green: 0.25, blue: 0.22, alpha: 1)
        potBody.lineWidth = 3
        potBody.position = CGPoint(x: potCenterX, y: potCenterY)
        potBody.zPosition = 10
        addChild(potBody)

        // Pot body highlight
        let bodyHighlight = SKShapeNode(rect: CGRect(x: -potWidth / 2 + 15, y: 0,
                                                       width: potWidth - 30, height: potHeight / 2 - 10),
                                         cornerRadius: 20)
        bodyHighlight.fillColor = SKColor(white: 1.0, alpha: 0.02)
        bodyHighlight.strokeColor = .clear
        bodyHighlight.zPosition = 0.1
        potBody.addChild(bodyHighlight)

        let rimPath = CGPath(ellipseIn: CGRect(x: -potWidth / 2 - 5, y: -18,
                                                width: potWidth + 10, height: 36),
                              transform: nil)
        potRim = SKShapeNode(path: rimPath)
        potRim.fillColor = SKColor(red: 0.26, green: 0.23, blue: 0.20, alpha: 1)
        potRim.strokeColor = SKColor(red: 0.36, green: 0.32, blue: 0.28, alpha: 1)
        potRim.lineWidth = 2.5
        potRim.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 - 5)
        potRim.zPosition = 15
        addChild(potRim)

        // Rim highlight
        let rimHighlightPath = CGPath(ellipseIn: CGRect(x: -potWidth / 2 + 10, y: -10,
                                                          width: potWidth - 20, height: 20),
                                        transform: nil)
        let rimHighlight = SKShapeNode(path: rimHighlightPath)
        rimHighlight.fillColor = .clear
        rimHighlight.strokeColor = SKColor(white: 1.0, alpha: 0.04)
        rimHighlight.lineWidth = 1
        rimHighlight.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 - 3)
        rimHighlight.zPosition = 15.1
        addChild(rimHighlight)

        for side in [-1.0, 1.0] as [CGFloat] {
            let handle = SKShapeNode(rectOf: CGSize(width: 30, height: 14), cornerRadius: 5)
            handle.fillColor = SKColor(red: 0.23, green: 0.20, blue: 0.16, alpha: 1)
            handle.strokeColor = SKColor(red: 0.33, green: 0.28, blue: 0.23, alpha: 1)
            handle.lineWidth = 1.5
            handle.position = CGPoint(x: potCenterX + side * (potWidth / 2 + 18),
                                      y: potCenterY + potHeight * 0.2)
            handle.zPosition = 11
            addChild(handle)
        }

        potGlow = SKShapeNode(ellipseOf: CGSize(width: potWidth + 60, height: potHeight + 60))
        potGlow.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.2, alpha: 0.0)
        potGlow.strokeColor = .clear
        potGlow.position = CGPoint(x: potCenterX, y: potCenterY)
        potGlow.zPosition = potBody.zPosition - 0.5
        addChild(potGlow)

        lidNode = SKShapeNode(ellipseOf: CGSize(width: potWidth * 0.85, height: 25))
        lidNode.fillColor = SKColor(red: 0.28, green: 0.25, blue: 0.22, alpha: 1)
        lidNode.strokeColor = SKColor(red: 0.33, green: 0.30, blue: 0.26, alpha: 1)
        lidNode.lineWidth = 1
        lidNode.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 + 5)
        lidNode.zPosition = potBody.zPosition + 1
        addChild(lidNode)

        // Lid highlight
        let lidHighlight = SKShapeNode(ellipseOf: CGSize(width: potWidth * 0.5, height: 10))
        lidHighlight.fillColor = SKColor(white: 1.0, alpha: 0.04)
        lidHighlight.strokeColor = .clear
        lidHighlight.position = CGPoint(x: -20, y: 2)
        lidNode.addChild(lidHighlight)

        let knob = SKShapeNode(circleOfRadius: 8)
        knob.fillColor = SKColor(red: 0.23, green: 0.20, blue: 0.16, alpha: 1)
        knob.strokeColor = SKColor(white: 0.35, alpha: 0.4)
        knob.lineWidth = 1
        knob.position = CGPoint(x: 0, y: 5)
        lidNode.addChild(knob)
    }

    // MARK: - Broth Surface

    private func buildBrothSurface() {
        let surfaceRect = CGRect(x: -potWidth / 2 + 12, y: -25,
                                  width: potWidth - 24, height: 50)
        brothSurface = SKShapeNode(rect: surfaceRect, cornerRadius: 20)
        brothSurface.position = CGPoint(x: potCenterX,
                                         y: potCenterY + potHeight / 2 - 35)
        brothSurface.zPosition = 12
        brothSurface.fillColor = SKColor(red: 0.72, green: 0.58, blue: 0.22, alpha: 1)
        brothSurface.strokeColor = .clear
        addChild(brothSurface)

        // Broth surface highlight shimmer
        let highlightRect = CGRect(x: -potWidth / 2 + 30, y: -8,
                                    width: potWidth * 0.4, height: 16)
        brothHighlight = SKShapeNode(rect: highlightRect, cornerRadius: 8)
        brothHighlight.fillColor = SKColor(white: 1.0, alpha: 0.04)
        brothHighlight.strokeColor = .clear
        brothHighlight.position = CGPoint(x: potCenterX - 20,
                                           y: potCenterY + potHeight / 2 - 32)
        brothHighlight.zPosition = 12.1
        addChild(brothHighlight)

        // Animate highlight shimmer
        brothHighlight.run(.repeatForever(.sequence([
            .moveBy(x: 15, y: 0, duration: 2.0),
            .moveBy(x: -15, y: 0, duration: 2.0)
        ])))
    }

    private func updateBrothSurface() {
        if isInSimmerZone() {
            brothSurface.fillColor = SKColor(red: 0.80, green: 0.64, blue: 0.24, alpha: 1)
            brothHighlight.alpha = 0.06
        } else {
            brothSurface.fillColor = SKColor(red: 0.72, green: 0.55, blue: 0.22, alpha: 1)
            brothHighlight.alpha = 0.03
        }
    }

    // MARK: - Flames

    private func buildFlames() {
        let flameBaseY = potCenterY - potHeight / 2 - 5
        let spacing = potWidth * 0.6 / CGFloat(flameCount - 1)
        let startX = potCenterX - potWidth * 0.3

        for i in 0..<flameCount {
            let flame = SKShapeNode()
            flame.zPosition = 3
            flame.position = CGPoint(x: startX + CGFloat(i) * spacing, y: flameBaseY)
            addChild(flame)
            flameNodes.append(flame)
        }
    }

    private func updateFlames() {
        // Flame height scales with player position (higher = more heat)
        let heatLevel = playerPosition
        let baseHeight: CGFloat = 10 + heatLevel * 80
        let flameBaseY = potCenterY - potHeight / 2 - 5

        // Update flame glow intensity
        let targetFlameGlowAlpha: CGFloat = heatLevel * 0.08
        flameGlow.alpha += (targetFlameGlowAlpha - flameGlow.alpha) * 0.1

        for (i, flame) in flameNodes.enumerated() {
            let heightVariation = CGFloat.random(in: 0.7...1.3)
            let flameH = baseHeight * heightVariation
            let wobbleX = CGFloat.random(in: -3...3)
            let baseSpacing = potWidth * 0.6 / CGFloat(flameCount - 1)
            let startX = potCenterX - potWidth * 0.3
            flame.position = CGPoint(x: startX + CGFloat(i) * baseSpacing + wobbleX, y: flameBaseY)

            let path = CGMutablePath()
            let halfW: CGFloat = 8 + heatLevel * 10 + CGFloat.random(in: -2...2)
            // Use curved flame shape via quad curve
            path.move(to: CGPoint(x: -halfW, y: 0))
            path.addQuadCurve(to: CGPoint(x: CGFloat.random(in: -3...3), y: flameH),
                              control: CGPoint(x: -halfW * 0.6 + CGFloat.random(in: -2...2),
                                               y: flameH * 0.6))
            path.addQuadCurve(to: CGPoint(x: halfW, y: 0),
                              control: CGPoint(x: halfW * 0.6 + CGFloat.random(in: -2...2),
                                               y: flameH * 0.6))
            path.closeSubpath()
            flame.path = path

            if heatLevel < 0.3 {
                flame.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.7)
                flame.strokeColor = SKColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 0.4)
            } else if heatLevel < 0.6 {
                let f = (heatLevel - 0.3) / 0.3
                flame.fillColor = SKColor(red: 0.9 + 0.1 * f, green: 0.5 + 0.2 * (1 - f),
                                           blue: 0.1, alpha: 0.85)
                flame.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.4)
            } else {
                let f = min((heatLevel - 0.6) / 0.4, 1.0)
                flame.fillColor = SKColor(red: 1.0, green: 0.5 - 0.3 * f, blue: 0.1, alpha: 0.9)
                flame.strokeColor = SKColor(red: 1.0, green: 0.3 - 0.2 * f, blue: 0.05, alpha: 0.5)
            }
            flame.lineWidth = 1
            flame.glowWidth = heatLevel * 4

            flame.removeAllChildren()
            if flameH > 25 {
                // Inner bright core
                let innerPath = CGMutablePath()
                let innerHalfW = halfW * 0.35
                let innerH = flameH * 0.55
                innerPath.move(to: CGPoint(x: -innerHalfW, y: 2))
                innerPath.addQuadCurve(to: CGPoint(x: CGFloat.random(in: -1...1), y: innerH),
                                       control: CGPoint(x: -innerHalfW * 0.5, y: innerH * 0.5))
                innerPath.addQuadCurve(to: CGPoint(x: innerHalfW, y: 2),
                                       control: CGPoint(x: innerHalfW * 0.5, y: innerH * 0.5))
                innerPath.closeSubpath()
                let innerFlame = SKShapeNode(path: innerPath)
                innerFlame.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.7)
                innerFlame.strokeColor = .clear
                innerFlame.zPosition = 0.1
                flame.addChild(innerFlame)

                // Tiny white-hot core for intense flames
                if flameH > 50 {
                    let coreH = flameH * 0.25
                    let coreHalfW = halfW * 0.15
                    let corePath = CGMutablePath()
                    corePath.move(to: CGPoint(x: -coreHalfW, y: 3))
                    corePath.addLine(to: CGPoint(x: 0, y: coreH))
                    corePath.addLine(to: CGPoint(x: coreHalfW, y: 3))
                    corePath.closeSubpath()
                    let core = SKShapeNode(path: corePath)
                    core.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 0.5)
                    core.strokeColor = .clear
                    core.zPosition = 0.2
                    flame.addChild(core)
                }
            }
        }
    }

    // MARK: - Bubble Emitter

    private func buildBubbleEmitter() {
        bubbleEmitter = SKEmitterNode()
        bubbleEmitter.particleTexture = createCircleTexture(radius: 6)
        bubbleEmitter.particleBirthRate = 0
        bubbleEmitter.particleLifetime = 1.5
        bubbleEmitter.particleLifetimeRange = 0.5
        bubbleEmitter.particleSpeed = 20
        bubbleEmitter.particleSpeedRange = 10
        bubbleEmitter.emissionAngle = .pi / 2
        bubbleEmitter.emissionAngleRange = .pi / 4
        bubbleEmitter.particleScale = 0.3
        bubbleEmitter.particleScaleRange = 0.15
        bubbleEmitter.particleScaleSpeed = -0.1
        bubbleEmitter.particleAlpha = 0.6
        bubbleEmitter.particleAlphaSpeed = -0.3
        bubbleEmitter.particleColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        bubbleEmitter.particleColorBlendFactor = 1.0
        bubbleEmitter.particlePositionRange = CGVector(dx: potWidth * 0.6, dy: 10)
        bubbleEmitter.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 - 30)
        bubbleEmitter.zPosition = 13
        addChild(bubbleEmitter)
    }

    private func updateBubbleEmitter() {
        let inZone = isInSimmerZone()
        if inZone {
            bubbleEmitter.particleBirthRate = 10
            bubbleEmitter.particleScale = 0.28
            bubbleEmitter.particleSpeed = 20
        } else {
            bubbleEmitter.particleBirthRate = 3
            bubbleEmitter.particleScale = 0.18
            bubbleEmitter.particleSpeed = 12
        }
    }

    // MARK: - Steam Emitter

    private func buildSteamEmitter() {
        steamEmitter = SKEmitterNode()
        steamEmitter.particleTexture = createCircleTexture(radius: 16)
        steamEmitter.particleBirthRate = 0
        steamEmitter.particleLifetime = 3.5
        steamEmitter.particleLifetimeRange = 1.0
        steamEmitter.particleSpeed = 25
        steamEmitter.particleSpeedRange = 10
        steamEmitter.emissionAngle = .pi / 2
        steamEmitter.emissionAngleRange = .pi / 5
        steamEmitter.particleScale = 0.18
        steamEmitter.particleScaleSpeed = 0.15
        steamEmitter.particleScaleRange = 0.1
        steamEmitter.particleAlpha = 0.12
        steamEmitter.particleAlphaSpeed = -0.035
        steamEmitter.particleColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1)
        steamEmitter.particleColorBlendFactor = 1.0
        steamEmitter.particlePositionRange = CGVector(dx: potWidth * 0.5, dy: 5)
        steamEmitter.xAcceleration = 5
        steamEmitter.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 + 20)
        steamEmitter.zPosition = 20
        addChild(steamEmitter)
    }

    private func updateSteamEmitter() {
        if isInSimmerZone() {
            steamEmitter.particleBirthRate = 5
            steamEmitter.particleAlpha = 0.14
            steamEmitter.particleSpeed = 24
        } else {
            steamEmitter.particleBirthRate = 2
            steamEmitter.particleAlpha = 0.07
            steamEmitter.particleSpeed = 15
        }
    }

    // MARK: - Ambient Particles

    private func buildAmbientParticles() {
        ambientEmitter = SKEmitterNode()
        ambientEmitter.particleTexture = createCircleTexture(radius: 4)
        ambientEmitter.particleBirthRate = 1.0
        ambientEmitter.particleLifetime = 5.0
        ambientEmitter.particleLifetimeRange = 2.0
        ambientEmitter.particleSpeed = 5
        ambientEmitter.particleSpeedRange = 3
        ambientEmitter.emissionAngle = .pi / 2
        ambientEmitter.emissionAngleRange = .pi
        ambientEmitter.particleScale = 0.06
        ambientEmitter.particleScaleSpeed = 0.01
        ambientEmitter.particleAlpha = 0.05
        ambientEmitter.particleAlphaSpeed = -0.01
        ambientEmitter.particleColor = SKColor(red: 1.0, green: 0.80, blue: 0.4, alpha: 1)
        ambientEmitter.particleColorBlendFactor = 1.0
        ambientEmitter.particlePositionRange = CGVector(dx: size.width * 0.6, dy: size.height * 0.3)
        ambientEmitter.position = CGPoint(x: potCenterX, y: potCenterY + 50)
        ambientEmitter.zPosition = 0.5
        addChild(ambientEmitter)
    }

    // MARK: - HUD

    private func buildHUD() {
        // HUD backdrop
        let hudBG = SKShapeNode(rectOf: CGSize(width: size.width - 160, height: 40), cornerRadius: 10)
        hudBG.position = CGPoint(x: size.width / 2, y: size.height - 100)
        hudBG.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)
        hudBG.strokeColor = SKColor(white: 0.2, alpha: 0.2)
        hudBG.lineWidth = 1
        hudBG.zPosition = 99
        addChild(hudBG)

        timerLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timerLabel.text = "Time: 35"
        timerLabel.fontSize = 28
        timerLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

        // Zone percentage label
        zonePercentLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        zonePercentLabel.text = "0%"
        zonePercentLabel.fontSize = 22
        zonePercentLabel.fontColor = SKColor(red: 0.5, green: 0.9, blue: 0.5, alpha: 0.8)
        zonePercentLabel.position = CGPoint(x: size.width - 120, y: size.height - 100)
        zonePercentLabel.horizontalAlignmentMode = .center
        zonePercentLabel.verticalAlignmentMode = .center
        zonePercentLabel.zPosition = 100
        addChild(zonePercentLabel)

        instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Tap to rise, release to fall -- keep in the green!"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height - 130)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        instructionLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.fadeOut(withDuration: 1.0)
        ]))
    }

    private func updateHUD() {
        let remaining = max(0, gameDuration - elapsedTime)
        timerLabel.text = "Time: \(Int(ceil(remaining)))"

        if remaining <= 5 {
            timerLabel.fontColor = SKColor(red: 1.0,
                                            green: CGFloat(remaining / 5.0),
                                            blue: CGFloat(remaining / 5.0), alpha: 1.0)
        } else {
            timerLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        }

        // Update zone percentage
        let percentage = elapsedTime > 0 ? Int((timeInZone / elapsedTime) * 100) : 0
        zonePercentLabel.text = "\(percentage)%"
    }

    // MARK: - Texture Helpers

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

    // MARK: - Simmer Zone Check

    private func isInSimmerZone() -> Bool {
        let halfZone = currentZoneSize() / 2
        let zoneLow = zoneCenter - halfZone
        let zoneHigh = zoneCenter + halfZone
        return playerPosition >= zoneLow && playerPosition <= zoneHigh
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive else { return }
        isTouching = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameActive else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = min(deltaTime, 0.1)

        elapsedTime += dt

        if elapsedTime >= gameDuration {
            endGame()
            return
        }

        // --- Player bar physics (Stardew-style) ---
        if isTouching {
            playerVelocity += riseAcceleration * CGFloat(dt)
        } else {
            playerVelocity -= gravity * CGFloat(dt)
        }

        // Clamp velocity
        playerVelocity = max(-maxVelocity, min(maxVelocity, playerVelocity))

        // Apply velocity
        playerPosition += playerVelocity * CGFloat(dt)

        // Bounce off edges with dampening
        if playerPosition <= 0 {
            playerPosition = 0
            playerVelocity = abs(playerVelocity) * 0.3
        } else if playerPosition >= 1 {
            playerPosition = 1
            playerVelocity = -abs(playerVelocity) * 0.3
        }

        // --- Green zone movement (the "fish") ---
        let progress = CGFloat(min(elapsedTime / gameDuration, 1.0))
        let currentSpeed = zoneBaseSpeed + zoneSpeedIncrease * progress

        zoneCenter += zoneVelocity * CGFloat(dt)

        // Bounce zone off edges
        let halfZone = currentZoneSize() / 2
        if zoneCenter - halfZone <= 0 {
            zoneCenter = halfZone
            zoneVelocity = abs(zoneVelocity)
        } else if zoneCenter + halfZone >= 1 {
            zoneCenter = 1 - halfZone
            zoneVelocity = -abs(zoneVelocity)
        }

        // Randomly change zone direction
        zoneDirectionTimer -= dt
        if zoneDirectionTimer <= 0 {
            zoneDirectionTimer = TimeInterval.random(in: zoneDirectionMinTime...zoneDirectionMaxTime)
            // Random new velocity with current speed magnitude
            let newSpeed = currentSpeed * CGFloat.random(in: 0.6...1.4)
            zoneVelocity = (Bool.random() ? 1 : -1) * newSpeed
        }

        // --- Scoring ---
        let currentlyInZone = isInSimmerZone()
        if currentlyInZone {
            timeInZone += dt
            if !wasInSimmerZone {
                AudioManager.shared.playSFX("success-chime")

                let simmerLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
                simmerLabel.text = "Simmering!"
                simmerLabel.fontSize = 24
                simmerLabel.fontColor = SKColor(red: 0.35, green: 0.90, blue: 0.40, alpha: 1.0)
                simmerLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
                simmerLabel.zPosition = 100
                simmerLabel.setScale(0.5)
                simmerLabel.alpha = 0
                addChild(simmerLabel)
                simmerLabel.run(.sequence([
                    .group([
                        .scale(to: 1.0, duration: 0.15),
                        .fadeAlpha(to: 1.0, duration: 0.15)
                    ]),
                    .group([.moveBy(x: 0, y: 40, duration: 0.8), .fadeOut(withDuration: 0.8)]),
                    .removeFromParent()
                ]))
            }
        }
        wasInSimmerZone = currentlyInZone

        // --- Pot glow ---
        let targetGlowAlpha: CGFloat = currentlyInZone ? 0.15 : 0.0
        potGlow.alpha += (targetGlowAlpha - potGlow.alpha) * 0.05

        // --- Lid rattle when bar is very high ---
        if playerPosition > 0.85 {
            if lidNode.action(forKey: "rattle") == nil {
                let rattle = SKAction.repeatForever(.sequence([
                    .rotate(byAngle: 0.03, duration: 0.05),
                    .rotate(byAngle: -0.06, duration: 0.1),
                    .rotate(byAngle: 0.03, duration: 0.05)
                ]))
                lidNode.run(rattle, withKey: "rattle")
            }
        } else {
            lidNode.removeAction(forKey: "rattle")
            lidNode.zRotation = 0
        }

        // --- Update visuals ---
        updateGaugeIndicator()
        updateGaugeZoneBand()
        updateFlames()
        updateBrothSurface()
        updateBubbleEmitter()
        updateSteamEmitter()
        updateHUD()
    }

    // MARK: - End Game

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        gameActive = false
        isTouching = false

        timerLabel.text = "Time: 0"

        let percentage = elapsedTime > 0 ? timeInZone / gameDuration : 0
        let score = Int(percentage * 100)

        let stars: Int
        if percentage >= 0.40 {
            stars = 3
        } else if percentage >= 0.20 {
            stars = 2
        } else {
            stars = 1
        }

        let timesUpLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        timesUpLabel.text = "Time's Up!"
        timesUpLabel.fontSize = 46
        timesUpLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
        timesUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        timesUpLabel.horizontalAlignmentMode = .center
        timesUpLabel.verticalAlignmentMode = .center
        timesUpLabel.zPosition = 200
        timesUpLabel.setScale(0.3)
        timesUpLabel.alpha = 0
        addChild(timesUpLabel)

        let scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        scoreLabel.text = "In Zone: \(score)%"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = stars >= 3
            ? SKColor(red: 0.35, green: 1.0, blue: 0.45, alpha: 1.0)
            : stars >= 2
            ? SKColor(red: 0.95, green: 0.88, blue: 0.35, alpha: 1.0)
            : SKColor(red: 1.0, green: 0.5, blue: 0.4, alpha: 1.0)
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 15)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 200
        scoreLabel.alpha = 0
        addChild(scoreLabel)

        let showLabel = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.1, duration: 0.25),
                SKAction.fadeIn(withDuration: 0.25)
            ]),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])

        timesUpLabel.run(showLabel)
        scoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        steamEmitter.particleBirthRate = 1
        bubbleEmitter.particleBirthRate = 1

        HapticManager.shared.success()

        run(SKAction.sequence([
            SKAction.wait(forDuration: postGameDelay),
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
                    .run { [weak self] in self?.onComplete?(score, stars) }
                ]))
            }
        ]))
    }
}
