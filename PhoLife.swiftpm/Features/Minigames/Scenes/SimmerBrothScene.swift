import SpriteKit

class SimmerBrothScene: SKScene {

    // MARK: - Callback

    /// Called when the minigame finishes. Parameters: (score, stars).
    var onComplete: ((Int, Int) -> Void)?

    // MARK: - Game Config

    private let gameDuration: TimeInterval = 25.0
    private let postGameDelay: TimeInterval = 1.2

    // Temperature dynamics
    private let riseRate: CGFloat = 0.4          // per second while touching
    private let fallRate: CGFloat = 0.25         // per second while not touching
    private let startTemp: CGFloat = 0.3

    // Simmer zone (narrows over time)
    private let zoneStartLow: CGFloat = 0.40
    private let zoneStartHigh: CGFloat = 0.65
    private let zoneEndLow: CGFloat = 0.45
    private let zoneEndHigh: CGFloat = 0.60

    // Gust config
    private let gustMinInterval: TimeInterval = 3.0
    private let gustMaxInterval: TimeInterval = 6.0
    private let gustMagnitude: CGFloat = 0.15
    private let gustDecayDuration: TimeInterval = 2.0
    private let gustWarningDuration: TimeInterval = 0.5

    // MARK: - State

    private var temperature: CGFloat = 0.3
    private var isTouching: Bool = false
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var gameActive: Bool = false
    private var gameEnded: Bool = false

    // Scoring
    private var timeInZone: TimeInterval = 0

    // Gust state
    private var gustEffect: CGFloat = 0           // current perturbation
    private var gustInitial: CGFloat = 0           // initial magnitude for decay
    private var gustTimeRemaining: TimeInterval = 0
    private var nextGustCountdown: TimeInterval = 4.0
    private var gustWarningActive: Bool = false
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
    private var gaugeFill: SKShapeNode!
    private var gaugeZoneBand: SKShapeNode!
    private var gaugeZoneGlow: SKShapeNode!
    private var gaugeIndicator: SKShapeNode!

    // Pot & stove
    private var stoveNode: SKShapeNode!
    private var potBody: SKShapeNode!
    private var potRim: SKShapeNode!
    private var brothSurface: SKShapeNode!

    // Flames
    private var flameNodes: [SKShapeNode] = []
    private let flameCount: Int = 5

    // Bubbles (programmatic emitter)
    private var bubbleEmitter: SKEmitterNode!

    // Steam
    private var steamEmitter: SKEmitterNode!

    // Wind indicator
    private var windArrow: SKNode!

    // Pot glow & lid
    private var potGlow: SKShapeNode!
    private var lidNode: SKShapeNode!

    // HUD
    private var timerLabel: SKLabelNode!
    private var zonePercentLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.14, green: 0.09, blue: 0.05, alpha: 1)

        buildBackground()
        buildGauge()
        buildStoveAndPot()
        buildFlames()
        buildBrothSurface()
        buildBubbleEmitter()
        buildSteamEmitter()
        buildWindArrow()
        buildHUD()

        gameActive = true
        nextGustCountdown = TimeInterval.random(in: gustMinInterval...gustMaxInterval)

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
        // Warm kitchen floor
        let floor = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.25))
        floor.position = CGPoint(x: size.width / 2, y: size.height * 0.125)
        floor.fillColor = SKColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1)
        floor.strokeColor = .clear
        floor.zPosition = -10
        addChild(floor)

        // Subtle wall gradient
        let wall = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.75))
        wall.position = CGPoint(x: size.width / 2, y: size.height * 0.625)
        wall.fillColor = SKColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1)
        wall.strokeColor = .clear
        wall.zPosition = -10
        addChild(wall)

        // Warm ambient glow behind pot area
        let glow = SKShapeNode(circleOfRadius: 220)
        glow.position = CGPoint(x: potCenterX, y: potCenterY - 30)
        glow.fillColor = SKColor(red: 0.35, green: 0.15, blue: 0.05, alpha: 0.15)
        glow.strokeColor = .clear
        glow.zPosition = -5
        addChild(glow)
    }

    // MARK: - Temperature Gauge

    private func buildGauge() {
        let gaugeRect = CGRect(x: -gaugeWidth / 2, y: 0, width: gaugeWidth, height: gaugeHeight)

        // Background
        gaugeBackground = SKShapeNode(rect: gaugeRect, cornerRadius: 8)
        gaugeBackground.fillColor = SKColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
        gaugeBackground.strokeColor = SKColor(white: 0.35, alpha: 1)
        gaugeBackground.lineWidth = 2
        gaugeBackground.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeBackground.zPosition = 5
        addChild(gaugeBackground)

        // Draw static color bands on the gauge
        drawGaugeColorBands()

        // Fill bar (grows from bottom)
        gaugeFill = SKShapeNode(rect: CGRect(x: -gaugeWidth / 2 + 3, y: 3,
                                              width: gaugeWidth - 6, height: 0),
                                cornerRadius: 4)
        gaugeFill.fillColor = .gray
        gaugeFill.strokeColor = .clear
        gaugeFill.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeFill.zPosition = 6
        addChild(gaugeFill)

        // Simmer zone band (highlighted with glow)
        gaugeZoneGlow = SKShapeNode()
        gaugeZoneGlow.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeZoneGlow.zPosition = 6.5
        addChild(gaugeZoneGlow)

        gaugeZoneBand = SKShapeNode()
        gaugeZoneBand.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeZoneBand.zPosition = 7
        addChild(gaugeZoneBand)

        // Current temperature indicator (white line)
        gaugeIndicator = SKShapeNode(rect: CGRect(x: -gaugeWidth / 2 - 8, y: -1.5,
                                                    width: gaugeWidth + 16, height: 3),
                                     cornerRadius: 1.5)
        gaugeIndicator.fillColor = .white
        gaugeIndicator.strokeColor = .clear
        gaugeIndicator.position = CGPoint(x: gaugeX, y: gaugeBottomY)
        gaugeIndicator.zPosition = 8
        addChild(gaugeIndicator)

        // Labels on gauge
        let labels = [("Cold", CGFloat(0.15)), ("Simmer", CGFloat(0.525)), ("Hot", CGFloat(0.85))]
        for (text, frac) in labels {
            let lbl = SKLabelNode(fontNamed: "SFProRounded-Medium")
            lbl.text = text
            lbl.fontSize = 11
            lbl.fontColor = SKColor(white: 1.0, alpha: 0.5)
            lbl.position = CGPoint(x: gaugeX + gaugeWidth / 2 + 28,
                                   y: gaugeBottomY + frac * gaugeHeight - 4)
            lbl.horizontalAlignmentMode = .center
            lbl.verticalAlignmentMode = .center
            lbl.zPosition = 8
            addChild(lbl)
        }

        updateGaugeZoneBand()
    }

    private func drawGaugeColorBands() {
        let inset: CGFloat = 3
        let barW = gaugeWidth - inset * 2
        let barH = gaugeHeight - inset * 2

        struct ZoneInfo {
            let start: CGFloat; let end: CGFloat; let color: SKColor
        }

        let zones: [ZoneInfo] = [
            // Cold zone: 0.0-0.3 blue/gray
            ZoneInfo(start: 0.0, end: 0.30,
                     color: SKColor(red: 0.30, green: 0.40, blue: 0.55, alpha: 0.35)),
            // Transition: 0.3-0.4
            ZoneInfo(start: 0.30, end: 0.40,
                     color: SKColor(red: 0.45, green: 0.55, blue: 0.40, alpha: 0.25)),
            // Simmer zone: 0.4-0.65 green
            ZoneInfo(start: 0.40, end: 0.65,
                     color: SKColor(red: 0.20, green: 0.65, blue: 0.30, alpha: 0.35)),
            // Transition: 0.65-0.7
            ZoneInfo(start: 0.65, end: 0.70,
                     color: SKColor(red: 0.70, green: 0.55, blue: 0.20, alpha: 0.25)),
            // Hot zone: 0.7-1.0 red/orange
            ZoneInfo(start: 0.70, end: 1.0,
                     color: SKColor(red: 0.75, green: 0.25, blue: 0.15, alpha: 0.35)),
        ]

        for z in zones {
            let y = inset + z.start * barH
            let h = (z.end - z.start) * barH
            let band = SKShapeNode(rect: CGRect(x: -gaugeWidth / 2 + inset, y: y,
                                                 width: barW, height: h))
            band.fillColor = z.color
            band.strokeColor = .clear
            band.zPosition = 0.1
            gaugeBackground.addChild(band)
        }
    }

    private func updateGaugeZoneBand() {
        let progress = CGFloat(min(elapsedTime / gameDuration, 1.0))
        let zoneLow = zoneStartLow + (zoneEndLow - zoneStartLow) * progress
        let zoneHigh = zoneStartHigh + (zoneEndHigh - zoneStartHigh) * progress

        let bandY = zoneLow * gaugeHeight
        let bandH = (zoneHigh - zoneLow) * gaugeHeight

        let rect = CGRect(x: -gaugeWidth / 2 - 3, y: bandY,
                          width: gaugeWidth + 6, height: bandH)

        // Glow layer (wider, more transparent)
        gaugeZoneGlow.path = CGPath(roundedRect: rect.insetBy(dx: -4, dy: -4),
                                     cornerWidth: 6, cornerHeight: 6, transform: nil)
        gaugeZoneGlow.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.10)
        gaugeZoneGlow.strokeColor = .clear
        gaugeZoneGlow.glowWidth = 6

        // Sharp band
        gaugeZoneBand.path = CGPath(roundedRect: rect, cornerWidth: 4,
                                     cornerHeight: 4, transform: nil)
        gaugeZoneBand.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 0.18)
        gaugeZoneBand.strokeColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.7)
        gaugeZoneBand.lineWidth = 1.5
        gaugeZoneBand.glowWidth = 3
    }

    private func updateGaugeVisuals() {
        let fillHeight = max(0, min(temperature, 1.0)) * (gaugeHeight - 6)
        let fillRect = CGRect(x: -gaugeWidth / 2 + 3, y: 3,
                               width: gaugeWidth - 6, height: fillHeight)
        gaugeFill.path = CGPath(roundedRect: fillRect, cornerWidth: 4,
                                 cornerHeight: 4, transform: nil)
        gaugeFill.fillColor = gaugeColorForTemperature(temperature)

        // Indicator line position
        gaugeIndicator.position = CGPoint(x: gaugeX,
                                           y: gaugeBottomY + temperature * gaugeHeight)
    }

    private func gaugeColorForTemperature(_ t: CGFloat) -> SKColor {
        if t < 0.3 {
            // Blue/gray for cold
            let f = t / 0.3
            return SKColor(red: 0.35 + 0.10 * f,
                           green: 0.45 + 0.10 * f,
                           blue: 0.65 - 0.15 * f,
                           alpha: 0.9)
        } else if t < 0.4 {
            // Transition cold to green
            let f = (t - 0.3) / 0.1
            return SKColor(red: 0.45 - 0.25 * f,
                           green: 0.55 + 0.30 * f,
                           blue: 0.50 - 0.20 * f,
                           alpha: 0.9)
        } else if t <= 0.65 {
            // Green (simmer)
            return SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 0.9)
        } else if t < 0.7 {
            // Transition green to red
            let f = (t - 0.65) / 0.05
            return SKColor(red: 0.20 + 0.70 * f,
                           green: 0.85 - 0.55 * f,
                           blue: 0.30 - 0.15 * f,
                           alpha: 0.9)
        } else {
            // Red/orange for hot
            let f = min((t - 0.7) / 0.3, 1.0)
            return SKColor(red: 0.90 + 0.10 * f,
                           green: 0.30 - 0.15 * f,
                           blue: 0.15 - 0.05 * f,
                           alpha: 0.9)
        }
    }

    // MARK: - Stove & Pot

    private func buildStoveAndPot() {
        let stoveY = potCenterY - potHeight / 2 - stoveHeight / 2 + 10

        // Stove body
        stoveNode = SKShapeNode(rectOf: CGSize(width: stoveWidth, height: stoveHeight),
                                cornerRadius: 6)
        stoveNode.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        stoveNode.strokeColor = SKColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        stoveNode.lineWidth = 2
        stoveNode.position = CGPoint(x: potCenterX, y: stoveY)
        stoveNode.zPosition = 1
        addChild(stoveNode)

        // Stove burner ring
        let ring = SKShapeNode(circleOfRadius: 80)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.15, alpha: 0.6)
        ring.lineWidth = 3
        ring.position = CGPoint(x: potCenterX, y: stoveY + stoveHeight / 2 + 5)
        ring.zPosition = 1.5
        addChild(ring)

        // Pot body (rounded rect / ellipse)
        let potRect = CGRect(x: -potWidth / 2, y: -potHeight / 2,
                              width: potWidth, height: potHeight)
        potBody = SKShapeNode(rect: potRect, cornerRadius: 30)
        potBody.fillColor = SKColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1)
        potBody.strokeColor = SKColor(red: 0.30, green: 0.27, blue: 0.24, alpha: 1)
        potBody.lineWidth = 3
        potBody.position = CGPoint(x: potCenterX, y: potCenterY)
        potBody.zPosition = 10
        addChild(potBody)

        // Pot rim (top ellipse for 3D effect)
        let rimPath = CGPath(ellipseIn: CGRect(x: -potWidth / 2 - 5, y: -18,
                                                width: potWidth + 10, height: 36),
                              transform: nil)
        potRim = SKShapeNode(path: rimPath)
        potRim.fillColor = SKColor(red: 0.28, green: 0.25, blue: 0.22, alpha: 1)
        potRim.strokeColor = SKColor(red: 0.38, green: 0.34, blue: 0.30, alpha: 1)
        potRim.lineWidth = 2.5
        potRim.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 - 5)
        potRim.zPosition = 15
        addChild(potRim)

        // Pot handles
        for side in [-1.0, 1.0] as [CGFloat] {
            let handle = SKShapeNode(rectOf: CGSize(width: 30, height: 14), cornerRadius: 5)
            handle.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
            handle.strokeColor = SKColor(red: 0.35, green: 0.30, blue: 0.25, alpha: 1)
            handle.lineWidth = 1.5
            handle.position = CGPoint(x: potCenterX + side * (potWidth / 2 + 18),
                                      y: potCenterY + potHeight * 0.2)
            handle.zPosition = 11
            addChild(handle)
        }

        // Golden glow behind pot (visible when in simmer zone)
        potGlow = SKShapeNode(ellipseOf: CGSize(width: potWidth + 60, height: potHeight + 60))
        potGlow.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.2, alpha: 0.0)
        potGlow.strokeColor = .clear
        potGlow.position = CGPoint(x: potCenterX, y: potCenterY)
        potGlow.zPosition = potBody.zPosition - 0.5
        addChild(potGlow)

        // Pot lid on the rim
        lidNode = SKShapeNode(ellipseOf: CGSize(width: potWidth * 0.85, height: 25))
        lidNode.fillColor = SKColor(red: 0.30, green: 0.27, blue: 0.24, alpha: 1)
        lidNode.strokeColor = SKColor(red: 0.35, green: 0.32, blue: 0.28, alpha: 1)
        lidNode.lineWidth = 1
        lidNode.position = CGPoint(x: potCenterX, y: potCenterY + potHeight / 2 + 5)
        lidNode.zPosition = potBody.zPosition + 1
        addChild(lidNode)

        // Lid handle knob
        let knob = SKShapeNode(circleOfRadius: 8)
        knob.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
        knob.strokeColor = .clear
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
    }

    private func updateBrothSurface() {
        let inZone = isInSimmerZone()

        if temperature < 0.3 {
            // Cold: gray, still
            let grayFactor = 1.0 - temperature / 0.3
            brothSurface.fillColor = SKColor(
                red: 0.50 + 0.22 * (1 - grayFactor),
                green: 0.45 + 0.13 * (1 - grayFactor),
                blue: 0.35 - 0.13 * grayFactor,
                alpha: 1
            )
        } else if inZone {
            // Simmer zone: gentle golden
            brothSurface.fillColor = SKColor(red: 0.78, green: 0.62, blue: 0.22, alpha: 1)
        } else if temperature > 0.7 {
            // Too hot: angry red
            let hotFactor = min((temperature - 0.7) / 0.3, 1.0)
            brothSurface.fillColor = SKColor(
                red: 0.78 + 0.17 * hotFactor,
                green: 0.62 - 0.35 * hotFactor,
                blue: 0.22 - 0.10 * hotFactor,
                alpha: 1
            )
        } else {
            // Transition zones
            brothSurface.fillColor = SKColor(red: 0.75, green: 0.58, blue: 0.22, alpha: 1)
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
        let baseHeight: CGFloat = 10 + temperature * 80
        let flameBaseY = potCenterY - potHeight / 2 - 5

        for (i, flame) in flameNodes.enumerated() {
            // Vary height per flame for organic feel
            let heightVariation = CGFloat.random(in: 0.7...1.3)
            let flameH = baseHeight * heightVariation

            // Wobble x position for flicker
            let wobbleX = CGFloat.random(in: -3...3)
            let baseSpacing = potWidth * 0.6 / CGFloat(flameCount - 1)
            let startX = potCenterX - potWidth * 0.3
            flame.position = CGPoint(x: startX + CGFloat(i) * baseSpacing + wobbleX,
                                     y: flameBaseY)

            // Build triangular flame path
            let path = CGMutablePath()
            let halfW: CGFloat = 8 + temperature * 10 + CGFloat.random(in: -2...2)
            path.move(to: CGPoint(x: -halfW, y: 0))
            path.addLine(to: CGPoint(x: CGFloat.random(in: -3...3), y: flameH))
            path.addLine(to: CGPoint(x: halfW, y: 0))
            path.closeSubpath()

            flame.path = path

            // Color: orange core, red outer based on temperature
            if temperature < 0.2 {
                // Very low: blue pilot light
                flame.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.7)
                flame.strokeColor = SKColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 0.5)
            } else if temperature < 0.5 {
                // Low-medium: orange
                let f = (temperature - 0.2) / 0.3
                flame.fillColor = SKColor(red: 0.9 + 0.1 * f,
                                           green: 0.5 + 0.2 * (1 - f),
                                           blue: 0.1,
                                           alpha: 0.85)
                flame.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.5)
            } else {
                // High: bright orange to red
                let f = min((temperature - 0.5) / 0.5, 1.0)
                flame.fillColor = SKColor(red: 1.0,
                                           green: 0.5 - 0.3 * f,
                                           blue: 0.1,
                                           alpha: 0.9)
                flame.strokeColor = SKColor(red: 1.0,
                                             green: 0.3 - 0.2 * f,
                                             blue: 0.05,
                                             alpha: 0.6)
            }
            flame.lineWidth = 1
            flame.glowWidth = temperature * 3

            // Inner bright core for larger flames
            flame.removeAllChildren()
            if flameH > 30 {
                let innerPath = CGMutablePath()
                let innerHalfW = halfW * 0.4
                let innerH = flameH * 0.6
                innerPath.move(to: CGPoint(x: -innerHalfW, y: 2))
                innerPath.addLine(to: CGPoint(x: CGFloat.random(in: -1...1), y: innerH))
                innerPath.addLine(to: CGPoint(x: innerHalfW, y: 2))
                innerPath.closeSubpath()

                let innerFlame = SKShapeNode(path: innerPath)
                innerFlame.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.7)
                innerFlame.strokeColor = .clear
                innerFlame.zPosition = 0.1
                flame.addChild(innerFlame)
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

        bubbleEmitter.position = CGPoint(x: potCenterX,
                                          y: potCenterY + potHeight / 2 - 30)
        bubbleEmitter.zPosition = 13
        addChild(bubbleEmitter)
    }

    private func updateBubbleEmitter() {
        let inZone = isInSimmerZone()

        if temperature < 0.25 {
            // Cold: no bubbles
            bubbleEmitter.particleBirthRate = 0
        } else if inZone {
            // Simmer: gentle bubbles
            bubbleEmitter.particleBirthRate = 8
            bubbleEmitter.particleScale = 0.25
            bubbleEmitter.particleSpeed = 18
            bubbleEmitter.particleColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        } else if temperature > 0.7 {
            // Boiling: aggressive bubbles
            let boilFactor = min((temperature - 0.7) / 0.3, 1.0)
            bubbleEmitter.particleBirthRate = 15 + 25 * CGFloat(boilFactor)
            bubbleEmitter.particleScale = 0.35 + 0.25 * boilFactor
            bubbleEmitter.particleSpeed = 30 + 20 * boilFactor
            bubbleEmitter.particleColor = SKColor(red: 1.0, green: 0.85 - 0.2 * boilFactor,
                                                   blue: 0.7 - 0.4 * boilFactor, alpha: 1.0)
        } else {
            // Transition areas
            let factor = max(0, (temperature - 0.25) / 0.4)
            bubbleEmitter.particleBirthRate = 2 + 6 * CGFloat(factor)
            bubbleEmitter.particleScale = 0.2 + 0.1 * CGFloat(factor)
            bubbleEmitter.particleSpeed = 12 + 8 * CGFloat(factor)
            bubbleEmitter.particleColor = SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        }
    }

    // MARK: - Steam Emitter

    private func buildSteamEmitter() {
        steamEmitter = SKEmitterNode()
        steamEmitter.particleTexture = createCircleTexture(radius: 16)
        steamEmitter.particleBirthRate = 0
        steamEmitter.particleLifetime = 3.0
        steamEmitter.particleLifetimeRange = 1.0
        steamEmitter.particleSpeed = 25
        steamEmitter.particleSpeedRange = 10
        steamEmitter.emissionAngle = .pi / 2
        steamEmitter.emissionAngleRange = .pi / 5
        steamEmitter.particleScale = 0.2
        steamEmitter.particleScaleSpeed = 0.15
        steamEmitter.particleScaleRange = 0.1
        steamEmitter.particleAlpha = 0.15
        steamEmitter.particleAlphaSpeed = -0.05
        steamEmitter.particleColor = .white
        steamEmitter.particleColorBlendFactor = 1.0
        steamEmitter.particlePositionRange = CGVector(dx: potWidth * 0.5, dy: 5)
        steamEmitter.xAcceleration = 5     // slight drift

        steamEmitter.position = CGPoint(x: potCenterX,
                                         y: potCenterY + potHeight / 2 + 20)
        steamEmitter.zPosition = 20
        addChild(steamEmitter)
    }

    private func updateSteamEmitter() {
        if temperature < 0.2 {
            steamEmitter.particleBirthRate = 0
        } else if temperature < 0.4 {
            let f = (temperature - 0.2) / 0.2
            steamEmitter.particleBirthRate = 2 * f
            steamEmitter.particleAlpha = 0.06 + 0.04 * f
            steamEmitter.particleSpeed = 15 + 5 * f
        } else if temperature <= 0.65 {
            // Simmer: gentle, pleasing steam
            steamEmitter.particleBirthRate = 4
            steamEmitter.particleAlpha = 0.12
            steamEmitter.particleSpeed = 22
        } else {
            // Hot: lots of steam
            let f = min((temperature - 0.65) / 0.35, 1.0)
            steamEmitter.particleBirthRate = 4 + 14 * f
            steamEmitter.particleAlpha = 0.12 + 0.12 * f
            steamEmitter.particleSpeed = 22 + 25 * f
        }
    }

    // MARK: - Wind Arrow

    private func buildWindArrow() {
        windArrow = SKNode()
        windArrow.position = CGPoint(x: potCenterX + potWidth / 2 + 60,
                                      y: potCenterY + potHeight / 2 + 50)
        windArrow.zPosition = 25
        windArrow.alpha = 0

        // Arrow body
        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 6), cornerRadius: 3)
        body.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.8)
        body.strokeColor = .clear
        windArrow.addChild(body)

        // Arrow head
        let headPath = CGMutablePath()
        headPath.move(to: CGPoint(x: 15, y: -10))
        headPath.addLine(to: CGPoint(x: 28, y: 0))
        headPath.addLine(to: CGPoint(x: 15, y: 10))
        headPath.closeSubpath()

        let head = SKShapeNode(path: headPath)
        head.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.8)
        head.strokeColor = .clear
        windArrow.addChild(head)

        // Label
        let windLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        windLabel.text = "GUST"
        windLabel.fontSize = 14
        windLabel.fontColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9)
        windLabel.position = CGPoint(x: 0, y: 16)
        windLabel.horizontalAlignmentMode = .center
        windLabel.verticalAlignmentMode = .center
        windArrow.addChild(windLabel)

        addChild(windArrow)
    }

    private func showGustWarning(direction: CGFloat) {
        gustWarningActive = true
        windArrow.alpha = 0
        windArrow.xScale = direction < 0 ? -1 : 1

        // Pulse warning
        let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.15)
        let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 0.15)
        let pulse = SKAction.repeat(SKAction.sequence([fadeIn, fadeOut]), count: 2)

        windArrow.run(SKAction.sequence([
            pulse,
            SKAction.run { [weak self] in
                self?.gustWarningActive = false
            }
        ]))
    }

    // MARK: - HUD

    private func buildHUD() {
        // Timer at top-center
        timerLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timerLabel.text = "Time: 25"
        timerLabel.fontSize = 28
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 60)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 100
        addChild(timerLabel)

        // Zone percentage at top-right
        zonePercentLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        zonePercentLabel.text = "In Zone: 0%"
        zonePercentLabel.fontSize = 22
        zonePercentLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0.9)
        zonePercentLabel.position = CGPoint(x: size.width - 100, y: size.height - 60)
        zonePercentLabel.horizontalAlignmentMode = .center
        zonePercentLabel.verticalAlignmentMode = .center
        zonePercentLabel.zPosition = 100
        addChild(zonePercentLabel)

        // Instruction label
        instructionLabel = SKLabelNode(fontNamed: "SFProRounded-Medium")
        instructionLabel.text = "Hold to raise the flame -- keep it in the green!"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.7)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height - 95)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .center
        instructionLabel.zPosition = 100
        addChild(instructionLabel)

        // Fade instruction after a few seconds
        instructionLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.fadeOut(withDuration: 1.0)
        ]))
    }

    private func updateHUD() {
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
        } else {
            timerLabel.fontColor = .white
        }

        // Zone percentage
        let zonePercent: Int
        if elapsedTime > 0 {
            zonePercent = Int((timeInZone / elapsedTime) * 100)
        } else {
            zonePercent = 0
        }
        zonePercentLabel.text = "In Zone: \(zonePercent)%"

        // Color the zone label based on performance
        if zonePercent >= 80 {
            zonePercentLabel.fontColor = SKColor(red: 0.3, green: 1.0, blue: 0.4, alpha: 1.0)
        } else if zonePercent >= 60 {
            zonePercentLabel.fontColor = SKColor(red: 0.9, green: 0.85, blue: 0.3, alpha: 1.0)
        } else {
            zonePercentLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.4, alpha: 1.0)
        }
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
        let progress = CGFloat(min(elapsedTime / gameDuration, 1.0))
        let zoneLow = zoneStartLow + (zoneEndLow - zoneStartLow) * progress
        let zoneHigh = zoneStartHigh + (zoneEndHigh - zoneStartHigh) * progress
        return temperature >= zoneLow && temperature <= zoneHigh
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

        // Initialize lastUpdateTime on first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = min(deltaTime, 0.1) // clamp for background return

        elapsedTime += dt

        // Check game over
        if elapsedTime >= gameDuration {
            endGame()
            return
        }

        // --- Temperature dynamics ---

        // Base rise/fall
        if isTouching {
            temperature += riseRate * CGFloat(dt)
        } else {
            temperature -= fallRate * CGFloat(dt)
        }

        // Apply gust effect
        if gustTimeRemaining > 0 {
            gustTimeRemaining -= dt
            if gustTimeRemaining <= 0 {
                gustEffect = 0
                gustTimeRemaining = 0
            } else {
                // Linear decay
                let fraction = CGFloat(gustTimeRemaining / gustDecayDuration)
                gustEffect = gustInitial * fraction
            }
            temperature += gustEffect * CGFloat(dt)
        }

        // Clamp
        temperature = max(0, min(1.0, temperature))

        // --- Scoring ---
        let currentlyInZone = isInSimmerZone()
        if currentlyInZone {
            timeInZone += dt
            if !wasInSimmerZone {
                AudioManager.shared.playSFX("success-chime")

                // Floating "Simmering!" text on zone entry
                let simmerLabel = SKLabelNode(text: "Simmering!")
                simmerLabel.fontName = "AvenirNext-Bold"
                simmerLabel.fontSize = 22
                simmerLabel.fontColor = SKColor(red: 0.3, green: 0.85, blue: 0.3, alpha: 1.0)
                simmerLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
                simmerLabel.zPosition = 100
                addChild(simmerLabel)
                simmerLabel.run(.sequence([
                    .group([.moveBy(x: 0, y: 40, duration: 1.0), .fadeOut(withDuration: 1.0)]),
                    .removeFromParent()
                ]))
            }
        }
        wasInSimmerZone = currentlyInZone

        // --- Pot glow (golden when in simmer zone) ---
        let targetGlowAlpha: CGFloat = currentlyInZone ? 0.15 : 0.0
        potGlow.alpha += (targetGlowAlpha - potGlow.alpha) * 0.05

        // --- Lid rattle when temperature > 0.7 ---
        if temperature > 0.7 {
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

        // --- Gust scheduling ---
        nextGustCountdown -= dt
        if nextGustCountdown <= 0 {
            triggerGust()
            nextGustCountdown = TimeInterval.random(in: gustMinInterval...gustMaxInterval)
        }

        // --- Update visuals ---
        updateGaugeVisuals()
        updateGaugeZoneBand()
        updateFlames()
        updateBrothSurface()
        updateBubbleEmitter()
        updateSteamEmitter()
        updateHUD()
    }

    // MARK: - Gusts

    private func triggerGust() {
        let direction: CGFloat = Bool.random() ? 1.0 : -1.0
        gustInitial = direction * gustMagnitude
        gustEffect = gustInitial
        gustTimeRemaining = gustDecayDuration

        // Show warning arrow
        showGustWarning(direction: direction)

        // Haptic feedback for gust
        HapticManager.shared.light()
        AudioManager.shared.playSFX("error-buzz")
    }

    // MARK: - End Game

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        gameActive = false
        isTouching = false

        timerLabel.text = "Time: 0"

        // Calculate final score
        let percentage = elapsedTime > 0 ? timeInZone / gameDuration : 0
        let score = Int(percentage * 100)

        let stars: Int
        if percentage >= 0.80 {
            stars = 3
        } else if percentage >= 0.65 {
            stars = 2
        } else {
            stars = 1
        }

        // Flash "Time's Up!" label
        let timesUpLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        timesUpLabel.text = "Time's Up!"
        timesUpLabel.fontSize = 44
        timesUpLabel.fontColor = .white
        timesUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        timesUpLabel.horizontalAlignmentMode = .center
        timesUpLabel.verticalAlignmentMode = .center
        timesUpLabel.zPosition = 200
        timesUpLabel.setScale(0.5)
        timesUpLabel.alpha = 0
        addChild(timesUpLabel)

        // Final score preview
        let scoreLabel = SKLabelNode(fontNamed: "SFProRounded-Bold")
        scoreLabel.text = "In Zone: \(score)%"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = stars >= 3
            ? SKColor(red: 0.3, green: 1.0, blue: 0.4, alpha: 1.0)
            : stars >= 2
            ? SKColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1.0)
            : SKColor(red: 1.0, green: 0.5, blue: 0.4, alpha: 1.0)
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 15)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 200
        scoreLabel.alpha = 0
        addChild(scoreLabel)

        let showLabel = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ])
        showLabel.timingMode = .easeOut

        timesUpLabel.run(showLabel)
        scoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Reduce flame and steam
        let windDown = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.steamEmitter.particleBirthRate = 1
                self?.bubbleEmitter.particleBirthRate = 1
            }
        ])
        run(windDown)

        HapticManager.shared.success()

        // Report after delay with exit curtain
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
