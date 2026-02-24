import SwiftUI

// MARK: - Ingredient Icon Enum

enum PhoIngredientIcon: Int, CaseIterable {
    case onion
    case starAnise
    case bone
    case pot
    case beefSlice
    case fishSauce
    case noodles
    case herbs
}

// MARK: - Ingredient Icon View

struct PhoIngredientIconView: View {

    let icon: PhoIngredientIcon
    var size: CGFloat = 30

    private let warmAmber = Color(red: 212 / 255, green: 165 / 255, blue: 116 / 255)

    var body: some View {
        iconShape
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var iconShape: some View {
        switch icon {
        case .onion:
            onionIcon
        case .starAnise:
            starAniseIcon
        case .bone:
            boneIcon
        case .pot:
            potIcon
        case .beefSlice:
            beefSliceIcon
        case .fishSauce:
            fishSauceIcon
        case .noodles:
            noodlesIcon
        case .herbs:
            herbsIcon
        }
    }

    // MARK: - Onion

    private var onionIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2
            let cy = h * 0.55

            // Outer half-circle
            var outerPath = Path()
            outerPath.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: w * 0.38,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            outerPath.closeSubpath()
            context.fill(outerPath, with: .color(warmAmber))

            // Inner half-circle
            var innerPath = Path()
            innerPath.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: w * 0.22,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            innerPath.closeSubpath()
            context.fill(innerPath, with: .color(warmAmber.opacity(0.5)))

            // Green shoot on top
            let shootRect = CGRect(
                x: cx - w * 0.04,
                y: h * 0.08,
                width: w * 0.08,
                height: h * 0.3
            )
            let shootPath = Capsule().path(in: shootRect)
            context.fill(shootPath, with: .color(Color(red: 0.4, green: 0.65, blue: 0.3)))
        }
    }

    // MARK: - Star Anise

    private var starAniseIcon: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2
            let outerR = min(canvasSize.width, canvasSize.height) * 0.45
            let innerR = outerR * 0.4

            var path = Path()
            for i in 0..<16 {
                let angle = (Double(i) * 360.0 / 16.0 - 90.0) * .pi / 180.0
                let r = i.isMultiple(of: 2) ? outerR : innerR
                let x = cx + CGFloat(cos(angle)) * r
                let y = cy + CGFloat(sin(angle)) * r
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
            context.fill(path, with: .color(warmAmber))

            // Center dot
            let dotSize = outerR * 0.3
            let dotRect = CGRect(x: cx - dotSize / 2, y: cy - dotSize / 2, width: dotSize, height: dotSize)
            context.fill(Circle().path(in: dotRect), with: .color(warmAmber.opacity(0.6)))
        }
    }

    // MARK: - Bone

    private var boneIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cy = h / 2
            let boneH = h * 0.28
            let knobSize = h * 0.34

            // Main shaft
            let shaftRect = CGRect(
                x: w * 0.18,
                y: cy - boneH / 2,
                width: w * 0.64,
                height: boneH
            )
            context.fill(Capsule().path(in: shaftRect), with: .color(warmAmber))

            // Left knob
            let leftKnob = CGRect(
                x: w * 0.06,
                y: cy - knobSize / 2,
                width: knobSize,
                height: knobSize
            )
            context.fill(Circle().path(in: leftKnob), with: .color(warmAmber))

            // Right knob
            let rightKnob = CGRect(
                x: w - w * 0.06 - knobSize,
                y: cy - knobSize / 2,
                width: knobSize,
                height: knobSize
            )
            context.fill(Circle().path(in: rightKnob), with: .color(warmAmber))
        }
    }

    // MARK: - Pot

    private var potIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            // Pot body
            let bodyW = w * 0.7
            let bodyH = h * 0.42
            let bodyRect = CGRect(
                x: (w - bodyW) / 2,
                y: h * 0.48,
                width: bodyW,
                height: bodyH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 4).path(in: bodyRect),
                with: .color(warmAmber)
            )

            // Left handle
            let handleW = w * 0.1
            let handleH = h * 0.12
            let leftHandle = CGRect(
                x: (w - bodyW) / 2 - handleW + 2,
                y: h * 0.55,
                width: handleW,
                height: handleH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 2).path(in: leftHandle),
                with: .color(warmAmber.opacity(0.7))
            )

            // Right handle
            let rightHandle = CGRect(
                x: (w + bodyW) / 2 - 2,
                y: h * 0.55,
                width: handleW,
                height: handleH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 2).path(in: rightHandle),
                with: .color(warmAmber.opacity(0.7))
            )

            // Lid
            let lidRect = CGRect(
                x: (w - bodyW * 0.85) / 2,
                y: h * 0.42,
                width: bodyW * 0.85,
                height: h * 0.08
            )
            context.fill(
                Capsule().path(in: lidRect),
                with: .color(warmAmber.opacity(0.8))
            )

            // Steam lines
            let steamColors: [Color] = [warmAmber.opacity(0.4), warmAmber.opacity(0.3), warmAmber.opacity(0.35)]
            let steamXOffsets: [CGFloat] = [-0.12, 0, 0.12]
            for i in 0..<3 {
                var steamPath = Path()
                let startX = w / 2 + w * steamXOffsets[i]
                let startY = h * 0.36
                steamPath.move(to: CGPoint(x: startX, y: startY))
                steamPath.addQuadCurve(
                    to: CGPoint(x: startX + w * 0.04, y: startY - h * 0.12),
                    control: CGPoint(x: startX + w * 0.08, y: startY - h * 0.06)
                )
                steamPath.addQuadCurve(
                    to: CGPoint(x: startX, y: startY - h * 0.24),
                    control: CGPoint(x: startX - w * 0.06, y: startY - h * 0.18)
                )
                context.stroke(
                    steamPath,
                    with: .color(steamColors[i]),
                    lineWidth: 1.5
                )
            }
        }
    }

    // MARK: - Beef Slice

    private var beefSliceIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let sliceW = w * 0.75
            let sliceH = h * 0.5

            // Main slice
            let sliceRect = CGRect(
                x: (w - sliceW) / 2,
                y: (h - sliceH) / 2,
                width: sliceW,
                height: sliceH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 6).path(in: sliceRect),
                with: .color(warmAmber)
            )

            // Marbling lines
            let baseX = (w - sliceW) / 2
            let baseY = (h - sliceH) / 2
            for i in 0..<3 {
                var marblePath = Path()
                let yOff = sliceH * CGFloat(0.25 + Double(i) * 0.25)
                marblePath.move(to: CGPoint(x: baseX + sliceW * 0.15, y: baseY + yOff))
                marblePath.addLine(to: CGPoint(x: baseX + sliceW * 0.85, y: baseY + yOff - sliceH * 0.12))
                context.stroke(
                    marblePath,
                    with: .color(warmAmber.opacity(0.4)),
                    lineWidth: 1.2
                )
            }
        }
    }

    // MARK: - Fish Sauce

    private var fishSauceIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2

            // Bottle body
            let bodyW = w * 0.4
            let bodyH = h * 0.52
            let bodyRect = CGRect(
                x: cx - bodyW / 2,
                y: h * 0.4,
                width: bodyW,
                height: bodyH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 4).path(in: bodyRect),
                with: .color(warmAmber)
            )

            // Neck
            let neckW = bodyW * 0.5
            let neckH = h * 0.2
            let neckRect = CGRect(
                x: cx - neckW / 2,
                y: h * 0.22,
                width: neckW,
                height: neckH
            )
            context.fill(
                RoundedRectangle(cornerRadius: 2).path(in: neckRect),
                with: .color(warmAmber.opacity(0.85))
            )

            // Cap
            var capPath = Path()
            let capTop = h * 0.1
            let capBottom = h * 0.24
            let capHalfW = neckW * 0.6
            capPath.move(to: CGPoint(x: cx, y: capTop))
            capPath.addLine(to: CGPoint(x: cx - capHalfW, y: capBottom))
            capPath.addLine(to: CGPoint(x: cx + capHalfW, y: capBottom))
            capPath.closeSubpath()
            context.fill(capPath, with: .color(warmAmber.opacity(0.7)))

            // Label line
            let labelRect = CGRect(
                x: cx - bodyW * 0.3,
                y: h * 0.58,
                width: bodyW * 0.6,
                height: h * 0.03
            )
            context.fill(
                RoundedRectangle(cornerRadius: 1).path(in: labelRect),
                with: .color(warmAmber.opacity(0.4))
            )
        }
    }

    // MARK: - Noodles

    private var noodlesIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            for i in 0..<4 {
                var path = Path()
                let y = h * (0.2 + Double(i) * 0.18)
                let startX = w * 0.12
                let endX = w * 0.88
                let segments = 6
                let segWidth = (endX - startX) / CGFloat(segments)
                let amplitude = h * 0.06

                path.move(to: CGPoint(x: startX, y: y))
                for seg in 0..<segments {
                    let xStart = startX + segWidth * CGFloat(seg)
                    let xEnd = xStart + segWidth
                    let controlY = seg.isMultiple(of: 2)
                        ? y - amplitude
                        : y + amplitude
                    path.addQuadCurve(
                        to: CGPoint(x: xEnd, y: y),
                        control: CGPoint(x: (xStart + xEnd) / 2, y: controlY)
                    )
                }

                context.stroke(
                    path,
                    with: .color(warmAmber.opacity(0.7 + Double(i) * 0.08)),
                    lineWidth: 2.0
                )
            }
        }
    }

    // MARK: - Herbs

    private var herbsIcon: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2

            // Leaf shape (teardrop)
            var leafPath = Path()
            leafPath.move(to: CGPoint(x: cx, y: h * 0.08))
            leafPath.addQuadCurve(
                to: CGPoint(x: cx, y: h * 0.88),
                control: CGPoint(x: cx + w * 0.38, y: h * 0.45)
            )
            leafPath.addQuadCurve(
                to: CGPoint(x: cx, y: h * 0.08),
                control: CGPoint(x: cx - w * 0.38, y: h * 0.45)
            )
            leafPath.closeSubpath()
            context.fill(leafPath, with: .color(Color(red: 0.4, green: 0.65, blue: 0.3)))

            // Center vein
            var veinPath = Path()
            veinPath.move(to: CGPoint(x: cx, y: h * 0.15))
            veinPath.addLine(to: CGPoint(x: cx, y: h * 0.8))
            context.stroke(
                veinPath,
                with: .color(Color(red: 0.3, green: 0.5, blue: 0.22)),
                lineWidth: 1.2
            )

            // Side veins
            for i in 0..<3 {
                let veinY = h * (0.3 + Double(i) * 0.15)
                var leftVein = Path()
                leftVein.move(to: CGPoint(x: cx, y: veinY))
                leftVein.addLine(to: CGPoint(x: cx - w * 0.15, y: veinY - h * 0.05))
                context.stroke(leftVein, with: .color(Color(red: 0.3, green: 0.5, blue: 0.22).opacity(0.6)), lineWidth: 0.8)

                var rightVein = Path()
                rightVein.move(to: CGPoint(x: cx, y: veinY))
                rightVein.addLine(to: CGPoint(x: cx + w * 0.15, y: veinY - h * 0.05))
                context.stroke(rightVein, with: .color(Color(red: 0.3, green: 0.5, blue: 0.22).opacity(0.6)), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.05, blue: 0.03).ignoresSafeArea()
        HStack(spacing: 24) {
            ForEach(PhoIngredientIcon.allCases, id: \.rawValue) { icon in
                VStack(spacing: 8) {
                    PhoIngredientIconView(icon: icon, size: 40)
                    Text(String(describing: icon))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}
