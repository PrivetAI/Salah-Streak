import SwiftUI

/// The posture illustrations. Every one is drawn from line segments and arcs in a unit
/// coordinate box, scaled to whatever frame it is given — no photographs, no imported
/// artwork, and nothing from the system icon set. The figure is deliberately abstract:
/// a head, a spine, one arm and one leg, enough to read the shape of the position without
/// depicting a person in any detail.
struct SLPostureFigure: View {

    let posture: SLPosture
    var tint: Color = SLTheme.teal
    var groundTint: Color = SLTheme.goldDeep
    var showArch: Bool = true

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let originX = (size.width - side) / 2
            let originY = (size.height - side) / 2
            func p(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: originX + side * x, y: originY + side * y)
            }

            let bodyWidth = max(2.0, side * 0.055)
            let thinWidth = max(1.0, side * 0.018)

            if showArch {
                // A mihrab arch behind the figure, the same shape as the app's own icon.
                var arch = Path()
                let left = 0.14, right = 0.86, top = 0.10, bottom = 0.88
                arch.move(to: p(left, bottom))
                arch.addLine(to: p(left, top + 0.16))
                arch.addQuadCurve(to: p(0.5, top), control: p(left, top))
                arch.addQuadCurve(to: p(right, top + 0.16), control: p(right, top))
                arch.addLine(to: p(right, bottom))
                context.stroke(arch, with: .color(SLTheme.hairline),
                               style: StrokeStyle(lineWidth: thinWidth, lineCap: .round, lineJoin: .round))
            }

            // The ground: a prayer mat, not a floor.
            var ground = Path()
            ground.move(to: p(0.12, 0.885))
            ground.addLine(to: p(0.88, 0.885))
            context.stroke(ground, with: .color(groundTint),
                           style: StrokeStyle(lineWidth: max(1.6, side * 0.022), lineCap: .round))

            let plan = SLPostureFigure.plan(for: posture)

            var strokes = Path()
            for segment in plan.segments {
                guard let first = segment.first else { continue }
                strokes.move(to: p(first.0, first.1))
                for point in segment.dropFirst() { strokes.addLine(to: p(point.0, point.1)) }
            }
            context.stroke(strokes, with: .color(tint),
                           style: StrokeStyle(lineWidth: bodyWidth, lineCap: .round, lineJoin: .round))

            var head = Path()
            let radius = side * plan.headRadius
            head.addEllipse(in: CGRect(x: originX + side * plan.head.0 - radius,
                                       y: originY + side * plan.head.1 - radius,
                                       width: radius * 2, height: radius * 2))
            context.fill(head, with: .color(tint))

            if let accent = plan.accent {
                var mark = Path()
                mark.move(to: p(accent.0.0, accent.0.1))
                mark.addLine(to: p(accent.1.0, accent.1.1))
                context.stroke(mark, with: .color(groundTint),
                               style: StrokeStyle(lineWidth: max(1.6, side * 0.026), lineCap: .round))
            }
        }
        .drawingGroup(opaque: false)
    }

    private struct Plan {
        let head: (Double, Double)
        let headRadius: Double
        /// Each entry is a polyline: spine, arm, leg.
        let segments: [[(Double, Double)]]
        /// An optional highlight — the raised finger in the tashahhud, the turn of the
        /// head in the taslim.
        let accent: ((Double, Double), (Double, Double))?
    }

    private static func plan(for posture: SLPosture) -> Plan {
        switch posture {

        case .takbir:
            return Plan(head: (0.42, 0.22), headRadius: 0.070,
                        segments: [
                            [(0.42, 0.30), (0.44, 0.60)],                       // spine
                            [(0.44, 0.60), (0.40, 0.86)],                       // near leg
                            [(0.44, 0.60), (0.52, 0.86)],                       // far leg
                            [(0.43, 0.35), (0.56, 0.38), (0.56, 0.22)],         // right arm raised
                            [(0.43, 0.35), (0.30, 0.38), (0.30, 0.22)]          // left arm raised
                        ],
                        accent: nil)

        case .qiyam:
            return Plan(head: (0.42, 0.22), headRadius: 0.070,
                        segments: [
                            [(0.42, 0.30), (0.44, 0.60)],
                            [(0.44, 0.60), (0.40, 0.86)],
                            [(0.44, 0.60), (0.52, 0.86)],
                            [(0.43, 0.35), (0.55, 0.45), (0.38, 0.47)],         // hands folded
                            [(0.43, 0.35), (0.32, 0.45), (0.38, 0.47)]
                        ],
                        accent: nil)

        case .ruku:
            return Plan(head: (0.26, 0.44), headRadius: 0.068,
                        segments: [
                            [(0.34, 0.45), (0.64, 0.47)],                       // level back
                            [(0.64, 0.47), (0.64, 0.68), (0.62, 0.86)],         // leg
                            [(0.38, 0.48), (0.52, 0.60), (0.60, 0.67)]          // arm to the knee
                        ],
                        accent: nil)

        case .itidal:
            return Plan(head: (0.42, 0.22), headRadius: 0.070,
                        segments: [
                            [(0.42, 0.30), (0.44, 0.60)],
                            [(0.44, 0.60), (0.40, 0.86)],
                            [(0.44, 0.60), (0.52, 0.86)],
                            [(0.43, 0.35), (0.36, 0.58)],                       // arms at the sides
                            [(0.43, 0.35), (0.52, 0.58)]
                        ],
                        accent: nil)

        case .sujud:
            return Plan(head: (0.26, 0.79), headRadius: 0.066,
                        segments: [
                            [(0.34, 0.74), (0.62, 0.54)],                       // back sloping down
                            [(0.62, 0.54), (0.68, 0.80), (0.78, 0.86)],         // folded leg to the toes
                            [(0.36, 0.72), (0.30, 0.85)]                        // arm to the ground
                        ],
                        accent: ((0.20, 0.86), (0.36, 0.86)))                   // hands and head down

        case .jalsa:
            return Plan(head: (0.44, 0.36), headRadius: 0.068,
                        segments: [
                            [(0.45, 0.44), (0.48, 0.66)],                       // upright seated spine
                            [(0.48, 0.68), (0.30, 0.74), (0.28, 0.84)],         // thigh and shin
                            [(0.28, 0.84), (0.56, 0.86)],                       // foot folded back
                            [(0.46, 0.48), (0.38, 0.68)]                        // hand resting on the thigh
                        ],
                        accent: nil)

        case .tashahhud:
            return Plan(head: (0.44, 0.34), headRadius: 0.068,
                        segments: [
                            [(0.45, 0.42), (0.48, 0.66)],
                            [(0.48, 0.68), (0.30, 0.74), (0.28, 0.84)],
                            [(0.28, 0.84), (0.56, 0.86)],
                            [(0.46, 0.46), (0.36, 0.66)]
                        ],
                        accent: ((0.36, 0.66), (0.34, 0.55)))                   // the raised finger

        case .taslim:
            return Plan(head: (0.53, 0.34), headRadius: 0.068,
                        segments: [
                            [(0.46, 0.42), (0.48, 0.66)],
                            [(0.48, 0.68), (0.30, 0.74), (0.28, 0.84)],
                            [(0.28, 0.84), (0.56, 0.86)],
                            [(0.46, 0.46), (0.38, 0.66)]
                        ],
                        accent: ((0.62, 0.30), (0.72, 0.26)))                   // the turn of the head
        }
    }
}
