import SpriteKit
import UIKit

extension SKScene {

    // MARK: - Screen Shake

    /// Shakes the camera for impact feedback. Creates an SKCameraNode if one doesn't exist.
    func shakeCamera(intensity: CGFloat = 6, stepDuration: TimeInterval = 0.05) {
        let cam = ensureCamera()
        let amp = intensity
        cam.run(SKAction.sequence([
            SKAction.moveBy(x: amp, y: 0, duration: stepDuration),
            SKAction.moveBy(x: -amp * 2, y: 0, duration: stepDuration),
            SKAction.moveBy(x: amp * 2, y: 0, duration: stepDuration),
            SKAction.moveBy(x: -amp, y: 0, duration: stepDuration),
        ]))
    }

    // MARK: - Flash Overlay

    /// Full-screen color flash that fades out. zPosition 90.
    func flashOverlay(color: SKColor, alpha: CGFloat = 0.12, duration: TimeInterval = 0.3) {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = color.withAlphaComponent(alpha)
        overlay.strokeColor = .clear
        overlay.zPosition = 90
        addChild(overlay)
        overlay.run(.sequence([.fadeAlpha(to: 0, duration: duration), .removeFromParent()]))
    }

    // MARK: - Particle Burst

    /// Radial burst of golden circle-shaped particles.
    func burstParticles(
        at position: CGPoint,
        count: Int = 22,
        colors: [SKColor]? = nil,
        radius: ClosedRange<CGFloat> = 35...90,
        particleSize: ClosedRange<CGFloat> = 2...5,
        glowWidth: CGFloat = 2,
        zPosition: CGFloat = 85
    ) {
        let defaultColors = colors ?? (0..<count).map { _ in
            SKColor(
                red: CGFloat.random(in: 0.90...1.0),
                green: CGFloat.random(in: 0.72...0.92),
                blue: CGFloat.random(in: 0.10...0.35),
                alpha: 1.0
            )
        }

        for i in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: particleSize))
            particle.fillColor = defaultColors[i % defaultColors.count]
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = zPosition
            particle.glowWidth = glowWidth
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: radius)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let lifetime = Double.random(in: 0.3...0.55)

            particle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: lifetime),
                    .fadeOut(withDuration: lifetime),
                    .scale(to: 0.1, duration: lifetime)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Expanding Ring

    /// Circle outline that scales up and fades out.
    func expandingRing(
        at position: CGPoint,
        color: SKColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.7),
        startRadius: CGFloat = 12,
        targetScale: CGFloat = 4.0,
        lineWidth: CGFloat = 2.5,
        duration: TimeInterval = 0.35,
        zPosition: CGFloat = 84
    ) {
        let ring = SKShapeNode(circleOfRadius: startRadius)
        ring.fillColor = .clear
        ring.strokeColor = color
        ring.lineWidth = lineWidth
        ring.position = position
        ring.zPosition = zPosition
        addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: targetScale, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Floating Score Text

    /// "+N" label that scales in, floats up, and fades out.
    func floatingScoreText(
        _ text: String,
        at position: CGPoint,
        color: SKColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0),
        fontSize: CGFloat = 26
    ) {
        let label = SKLabelNode(fontNamed: "SFCompactRounded-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 25)
        label.zPosition = 95
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.setScale(0.6)
        addChild(label)

        label.run(.sequence([
            .scale(to: 1.1, duration: 0.1),
            .group([
                .moveBy(x: 0, y: 50, duration: 0.55),
                .scale(to: 0.9, duration: 0.55),
                .sequence([
                    .wait(forDuration: 0.25),
                    .fadeOut(withDuration: 0.30)
                ])
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Ambient Particles

    /// Persistent low-rate warm dust emitter for atmospheric background.
    @discardableResult
    func addAmbientParticles(
        color: SKColor = SKColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1),
        birthRate: CGFloat = 1.5,
        zPosition: CGFloat = 0.5
    ) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = createCircleParticleTexture()
        emitter.particleBirthRate = birthRate
        emitter.particleLifetime = 5.0
        emitter.particleLifetimeRange = 2.0
        emitter.particleSpeed = 8
        emitter.particleSpeedRange = 5
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.15
        emitter.particleScaleSpeed = 0.03
        emitter.particleAlpha = 0.06
        emitter.particleAlphaSpeed = -0.012
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: size.height * 0.4)
        emitter.position = CGPoint(x: size.width * 0.45, y: size.height * 0.45)
        emitter.zPosition = zPosition
        addChild(emitter)
        return emitter
    }

    // MARK: - Vignette

    /// Edge-darkening circle overlay for depth.
    @discardableResult
    func addVignette(
        alpha: CGFloat = 0.5,
        lineWidthFraction: CGFloat = 0.25,
        zPosition: CGFloat = -1
    ) -> SKShapeNode {
        let vignetteSize = max(size.width, size.height) * 1.2
        let node = SKShapeNode(circleOfRadius: vignetteSize / 2)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.fillColor = .clear
        node.strokeColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: alpha)
        node.lineWidth = vignetteSize * lineWidthFraction
        node.zPosition = zPosition
        addChild(node)
        return node
    }

    // MARK: - Entrance / Exit Curtains

    /// Dark overlay that fades out when scene starts.
    func addEntranceCurtain(
        color: SKColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 1.0),
        delay: TimeInterval = 0.2,
        fadeDuration: TimeInterval = 0.6
    ) {
        let curtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        curtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        curtain.fillColor = color
        curtain.strokeColor = .clear
        curtain.zPosition = 500
        addChild(curtain)
        curtain.run(.sequence([
            .wait(forDuration: delay),
            .fadeAlpha(to: 0, duration: fadeDuration),
            .removeFromParent()
        ]))
    }

    /// Overlay that fades in before onComplete fires.
    func addExitCurtain(
        color: SKColor = SKColor(red: 0.08, green: 0.05, blue: 0.02, alpha: 0.0),
        delay: TimeInterval = 0.6,
        fadeDuration: TimeInterval = 0.4,
        completion: @escaping () -> Void
    ) {
        let curtain = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        curtain.position = CGPoint(x: size.width / 2, y: size.height / 2)
        curtain.fillColor = color.withAlphaComponent(0.0)
        curtain.strokeColor = .clear
        curtain.zPosition = 500
        addChild(curtain)
        curtain.run(.sequence([
            .wait(forDuration: delay),
            .fadeAlpha(to: 1.0, duration: fadeDuration),
            .run(completion)
        ]))
    }

    // MARK: - Texture Helper

    /// Shared white circle texture for particle emitters.
    func createCircleParticleTexture(radius: CGFloat = 4) -> SKTexture {
        let diameter = radius * 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        }
        return SKTexture(image: image)
    }

    // MARK: - Private Helpers

    /// Lazily creates and attaches an SKCameraNode at scene center.
    private func ensureCamera() -> SKCameraNode {
        if let existing = self.camera { return existing }
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
        self.camera = cam
        return cam
    }
}
