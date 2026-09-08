import SwiftUI

// Every icon in the app is drawn here from a `Path`. No SF Symbols, no system images,
// no emoji anywhere in the interface.

// MARK: - Stroke helpers

private func slLine(_ path: inout Path, _ points: [CGPoint]) {
    guard let first = points.first else { return }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
}

// MARK: - Navigation glyphs

struct SLChevron: Shape {
    enum Direction { case right, left, down, up }
    var direction: Direction = .right

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        switch direction {
        case .right: slLine(&path, [CGPoint(x: w * 0.35, y: h * 0.20),
                                    CGPoint(x: w * 0.68, y: h * 0.50),
                                    CGPoint(x: w * 0.35, y: h * 0.80)])
        case .left:  slLine(&path, [CGPoint(x: w * 0.65, y: h * 0.20),
                                    CGPoint(x: w * 0.32, y: h * 0.50),
                                    CGPoint(x: w * 0.65, y: h * 0.80)])
        case .down:  slLine(&path, [CGPoint(x: w * 0.20, y: h * 0.38),
                                    CGPoint(x: w * 0.50, y: h * 0.68),
                                    CGPoint(x: w * 0.80, y: h * 0.38)])
        case .up:    slLine(&path, [CGPoint(x: w * 0.20, y: h * 0.64),
                                    CGPoint(x: w * 0.50, y: h * 0.34),
                                    CGPoint(x: w * 0.80, y: h * 0.64)])
        }
        return path
    }
}

struct SLChevronIcon: View {
    var direction: SLChevron.Direction = .right
    var size: CGFloat = 14
    var color: Color = SLTheme.inkFaint
    var weight: CGFloat = 2

    var body: some View {
        SLChevron(direction: direction)
            .stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct SLCheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        slLine(&path, [CGPoint(x: rect.width * 0.20, y: rect.height * 0.52),
                       CGPoint(x: rect.width * 0.42, y: rect.height * 0.74),
                       CGPoint(x: rect.width * 0.80, y: rect.height * 0.26)])
        return path
    }
}

struct SLCrossMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        slLine(&path, [CGPoint(x: rect.width * 0.24, y: rect.height * 0.24),
                       CGPoint(x: rect.width * 0.76, y: rect.height * 0.76)])
        slLine(&path, [CGPoint(x: rect.width * 0.76, y: rect.height * 0.24),
                       CGPoint(x: rect.width * 0.24, y: rect.height * 0.76)])
        return path
    }
}

struct SLPlusMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        slLine(&path, [CGPoint(x: rect.width * 0.5, y: rect.height * 0.22),
                       CGPoint(x: rect.width * 0.5, y: rect.height * 0.78)])
        slLine(&path, [CGPoint(x: rect.width * 0.22, y: rect.height * 0.5),
                       CGPoint(x: rect.width * 0.78, y: rect.height * 0.5)])
        return path
    }
}

struct SLMinusMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        slLine(&path, [CGPoint(x: rect.width * 0.22, y: rect.height * 0.5),
                       CGPoint(x: rect.width * 0.78, y: rect.height * 0.5)])
        return path
    }
}

struct SLSearchGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(rect.width, rect.height)
        path.addEllipse(in: CGRect(x: r * 0.14, y: r * 0.14, width: r * 0.52, height: r * 0.52))
        slLine(&path, [CGPoint(x: r * 0.62, y: r * 0.62), CGPoint(x: r * 0.86, y: r * 0.86)])
        return path
    }
}

// MARK: - Tab bar glyphs

/// Today — a prayer rug seen end-on with its mihrab arch, echoing the app icon.
struct SLRugGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let body = CGRect(x: w * 0.24, y: h * 0.12, width: w * 0.52, height: h * 0.70)
        path.addRoundedRect(in: body, cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
        // Mihrab arch inside the field.
        let ax = w * 0.50, top = h * 0.24, bottom = h * 0.70
        let half = w * 0.14
        path.move(to: CGPoint(x: ax - half, y: bottom))
        path.addLine(to: CGPoint(x: ax - half, y: top + h * 0.09))
        path.addQuadCurve(to: CGPoint(x: ax, y: top),
                          control: CGPoint(x: ax - half, y: top))
        path.addQuadCurve(to: CGPoint(x: ax + half, y: top + h * 0.09),
                          control: CGPoint(x: ax + half, y: top))
        path.addLine(to: CGPoint(x: ax + half, y: bottom))
        // Fringe.
        for i in 0..<5 {
            let x = w * (0.28 + 0.11 * Double(i))
            slLine(&path, [CGPoint(x: x, y: h * 0.82), CGPoint(x: x, y: h * 0.92)])
        }
        return path
    }
}

/// Calendar — a month grid.
struct SLGridGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w * 0.14, y: h * 0.20, width: w * 0.72, height: h * 0.66),
                            cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
        slLine(&path, [CGPoint(x: w * 0.14, y: h * 0.40), CGPoint(x: w * 0.86, y: h * 0.40)])
        slLine(&path, [CGPoint(x: w * 0.30, y: h * 0.10), CGPoint(x: w * 0.30, y: h * 0.24)])
        slLine(&path, [CGPoint(x: w * 0.70, y: h * 0.10), CGPoint(x: w * 0.70, y: h * 0.24)])
        slLine(&path, [CGPoint(x: w * 0.38, y: h * 0.55), CGPoint(x: w * 0.38, y: h * 0.56)])
        slLine(&path, [CGPoint(x: w * 0.62, y: h * 0.55), CGPoint(x: w * 0.62, y: h * 0.56)])
        slLine(&path, [CGPoint(x: w * 0.38, y: h * 0.72), CGPoint(x: w * 0.38, y: h * 0.73)])
        slLine(&path, [CGPoint(x: w * 0.62, y: h * 0.72), CGPoint(x: w * 0.62, y: h * 0.73)])
        return path
    }
}

/// Statistics — three rising columns.
struct SLBarsGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        slLine(&path, [CGPoint(x: w * 0.24, y: h * 0.82), CGPoint(x: w * 0.24, y: h * 0.58)])
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.82), CGPoint(x: w * 0.50, y: h * 0.36)])
        slLine(&path, [CGPoint(x: w * 0.76, y: h * 0.82), CGPoint(x: w * 0.76, y: h * 0.20)])
        slLine(&path, [CGPoint(x: w * 0.14, y: h * 0.88), CGPoint(x: w * 0.86, y: h * 0.88)])
        return path
    }
}

/// Guide — an open book.
struct SLBookGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
        path.addQuadCurve(to: CGPoint(x: w * 0.13, y: h * 0.24),
                          control: CGPoint(x: w * 0.32, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.13, y: h * 0.76))
        path.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.80),
                          control: CGPoint(x: w * 0.32, y: h * 0.72))
        path.addQuadCurve(to: CGPoint(x: w * 0.87, y: h * 0.76),
                          control: CGPoint(x: w * 0.68, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.87, y: h * 0.24))
        path.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.28),
                          control: CGPoint(x: w * 0.68, y: h * 0.18))
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.28), CGPoint(x: w * 0.50, y: h * 0.80)])
        return path
    }
}

/// Settings — three labelled sliders.
struct SLSlidersGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let rows: [(Double, Double)] = [(0.28, 0.62), (0.50, 0.38), (0.72, 0.72)]
        for (y, knob) in rows {
            slLine(&path, [CGPoint(x: w * 0.15, y: h * y), CGPoint(x: w * 0.85, y: h * y)])
            path.addEllipse(in: CGRect(x: w * knob - w * 0.075, y: h * y - w * 0.075,
                                       width: w * 0.15, height: w * 0.15))
        }
        return path
    }
}

// MARK: - Prayer-time glyphs

/// Dawn / Fajr — a low sun with rays below the horizon line.
struct SLDawnGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.66), radius: w * 0.20,
                    startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        slLine(&path, [CGPoint(x: w * 0.10, y: h * 0.66), CGPoint(x: w * 0.90, y: h * 0.66)])
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.22), CGPoint(x: w * 0.50, y: h * 0.34)])
        slLine(&path, [CGPoint(x: w * 0.22, y: h * 0.36), CGPoint(x: w * 0.30, y: h * 0.44)])
        slLine(&path, [CGPoint(x: w * 0.78, y: h * 0.36), CGPoint(x: w * 0.70, y: h * 0.44)])
        return path
    }
}

/// Sunrise marker — a sun clearing the line with an upward arrow.
struct SLSunriseGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.32, y: h * 0.30, width: w * 0.36, height: w * 0.36))
        slLine(&path, [CGPoint(x: w * 0.10, y: h * 0.78), CGPoint(x: w * 0.90, y: h * 0.78)])
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.10), CGPoint(x: w * 0.50, y: h * 0.24)])
        return path
    }
}

/// Dhuhr — the sun at its highest, with a short shadow.
struct SLNoonGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.34, y: h * 0.16, width: w * 0.32, height: w * 0.32))
        for k in 0..<8 {
            let a = Double(k) * .pi / 4
            let inner = w * 0.24, outer = w * 0.33
            let cx = w * 0.5, cy = h * 0.16 + w * 0.16
            slLine(&path, [CGPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner),
                           CGPoint(x: cx + cos(a) * outer, y: cy + sin(a) * outer)])
        }
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.66), CGPoint(x: w * 0.50, y: h * 0.86)])
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.86), CGPoint(x: w * 0.62, y: h * 0.86)])
        return path
    }
}

/// Asr — a low sun on the left and the long shadow it casts to the right. The shadow is
/// drawn slanting away from the object's foot rather than along the ground line: at the
/// same y it would sit exactly on top of the ground and disappear.
struct SLShadowGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.10, y: h * 0.18, width: w * 0.20, height: w * 0.20))
        slLine(&path, [CGPoint(x: w * 0.45, y: h * 0.32), CGPoint(x: w * 0.45, y: h * 0.74)])   // the object
        slLine(&path, [CGPoint(x: w * 0.26, y: h * 0.76), CGPoint(x: w * 0.45, y: h * 0.76)])   // the ground at its foot
        slLine(&path, [CGPoint(x: w * 0.45, y: h * 0.78), CGPoint(x: w * 0.90, y: h * 0.88)])   // the shadow
        return path
    }
}

/// Maghrib — the sun dropping below the line.
struct SLSunsetGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.62), radius: w * 0.22,
                    startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        slLine(&path, [CGPoint(x: w * 0.10, y: h * 0.62), CGPoint(x: w * 0.90, y: h * 0.62)])
        slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.90), CGPoint(x: w * 0.50, y: h * 0.74)])
        slLine(&path, [CGPoint(x: w * 0.40, y: h * 0.82), CGPoint(x: w * 0.50, y: h * 0.92)])
        slLine(&path, [CGPoint(x: w * 0.60, y: h * 0.82), CGPoint(x: w * 0.50, y: h * 0.92)])
        return path
    }
}

/// Isha — a crescent with a single star.
struct SLNightGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let c = CGPoint(x: w * 0.46, y: h * 0.50)
        let r = w * 0.28
        path.addArc(center: c, radius: r, startAngle: .degrees(60), endAngle: .degrees(300), clockwise: false)
        path.addArc(center: CGPoint(x: c.x + r * 0.52, y: c.y), radius: r * 0.86,
                    startAngle: .degrees(300), endAngle: .degrees(60), clockwise: true)
        path.closeSubpath()
        // An eight-pointed star. Four strokes alone read as a plus sign, not a star.
        let sx = w * 0.80, sy = h * 0.26, s = w * 0.075, d = s * 0.62
        slLine(&path, [CGPoint(x: sx - s, y: sy), CGPoint(x: sx + s, y: sy)])
        slLine(&path, [CGPoint(x: sx, y: sy - s), CGPoint(x: sx, y: sy + s)])
        slLine(&path, [CGPoint(x: sx - d, y: sy - d), CGPoint(x: sx + d, y: sy + d)])
        slLine(&path, [CGPoint(x: sx + d, y: sy - d), CGPoint(x: sx - d, y: sy + d)])
        return path
    }
}

// MARK: - Small state marks

/// The four marks a prayer can carry, drawn as distinct silhouettes so they are told
/// apart by shape and not only by colour.
struct SLStateMark: View {
    let kind: SLPrayerState
    var size: CGFloat = 18
    var color: Color

    var body: some View {
        Group {
            switch kind {
            case .congregation:
                // Two figures side by side in a row — the congregation mark.
                Canvas { context, canvasSize in
                    var path = Path()
                    let w = canvasSize.width, h = canvasSize.height
                    for x in [0.30, 0.70] {
                        path.addEllipse(in: CGRect(x: w * x - w * 0.09, y: h * 0.16,
                                                   width: w * 0.18, height: w * 0.18))
                        path.move(to: CGPoint(x: w * x - w * 0.15, y: h * 0.72))
                        path.addQuadCurve(to: CGPoint(x: w * x + w * 0.15, y: h * 0.72),
                                          control: CGPoint(x: w * x, y: h * 0.34))
                    }
                    slLine(&path, [CGPoint(x: w * 0.10, y: h * 0.84), CGPoint(x: w * 0.90, y: h * 0.84)])
                    context.stroke(path, with: .color(color),
                                   style: StrokeStyle(lineWidth: max(1.4, size * 0.09),
                                                      lineCap: .round, lineJoin: .round))
                }
            case .onTime:
                SLCheckMark()
                    .stroke(color, style: StrokeStyle(lineWidth: max(1.6, size * 0.12),
                                                      lineCap: .round, lineJoin: .round))
            case .late:
                Canvas { context, canvasSize in
                    var path = Path()
                    let w = canvasSize.width, h = canvasSize.height
                    path.addEllipse(in: CGRect(x: w * 0.14, y: h * 0.14, width: w * 0.72, height: h * 0.72))
                    slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.30), CGPoint(x: w * 0.50, y: h * 0.52)])
                    slLine(&path, [CGPoint(x: w * 0.50, y: h * 0.52), CGPoint(x: w * 0.70, y: h * 0.62)])
                    context.stroke(path, with: .color(color),
                                   style: StrokeStyle(lineWidth: max(1.4, size * 0.09),
                                                      lineCap: .round, lineJoin: .round))
                }
            case .missed:
                SLCrossMark()
                    .stroke(color, style: StrokeStyle(lineWidth: max(1.6, size * 0.11),
                                                      lineCap: .round, lineJoin: .round))
            case .none:
                Circle()
                    .stroke(color, style: StrokeStyle(lineWidth: max(1.2, size * 0.08), dash: [2.4, 2.6]))
                    .padding(size * 0.14)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Decorative rule

/// A short ornamental divider: a hairline with a small lozenge at its centre.
struct SLOrnamentRule: View {
    var width: CGFloat = 120
    var color: Color = SLTheme.hairline

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let midY = size.height / 2
            slLine(&path, [CGPoint(x: 0, y: midY), CGPoint(x: size.width * 0.42, y: midY)])
            slLine(&path, [CGPoint(x: size.width * 0.58, y: midY), CGPoint(x: size.width, y: midY)])
            context.stroke(path, with: .color(color), lineWidth: 1)

            var diamond = Path()
            let c = CGPoint(x: size.width / 2, y: midY)
            let r = min(4.5, size.height / 2)
            diamond.move(to: CGPoint(x: c.x, y: c.y - r))
            diamond.addLine(to: CGPoint(x: c.x + r, y: c.y))
            diamond.addLine(to: CGPoint(x: c.x, y: c.y + r))
            diamond.addLine(to: CGPoint(x: c.x - r, y: c.y))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(color), lineWidth: 1)
        }
        .frame(width: width, height: 12)
    }
}
