import SwiftUI

/// The splash. It is shown while the launch check runs and again, over the panel, until
/// the page paints — the same screen in both places, so there is no seam between them.
///
/// The ground is deliberately dark: the branch that presents it runs in the dark colour
/// scheme, which draws the status bar glyphs white, and white glyphs need a dark strip
/// behind them.
struct SalahLoadingScreen: View {
    @State private var pulse = false

    private let ground = Color(red: 0.024, green: 0.176, blue: 0.176)   // #062D2D

    var body: some View {
        ZStack {
            ground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 22) {
                ZStack {
                    SLMihrabMark()
                        .stroke(SLTheme.gold, style: StrokeStyle(lineWidth: 2.2,
                                                                 lineCap: .round,
                                                                 lineJoin: .round))
                        .frame(width: 72, height: 92)
                        .opacity(pulse ? 1.0 : 0.45)
                        .scaleEffect(pulse ? 1.0 : 0.94)
                        .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                   value: pulse)
                }

                VStack(spacing: 5) {
                    Text("Salah Ledger")
                        .font(SLType.title(22))
                        .foregroundColor(Color(red: 0.976, green: 0.953, blue: 0.898))
                    Text("A record of what you have prayed")
                        .font(SLType.caption(12))
                        .foregroundColor(SLTheme.gold.opacity(0.75))
                }
            }
        }
        .onAppear { pulse = true }
    }
}

/// The arch used on the splash: the same mihrab outline the app icon carries, with a
/// simple woven border around it.
struct SLMihrabMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        // Outer border of the rug.
        path.addRoundedRect(in: CGRect(x: w * 0.03, y: h * 0.03,
                                       width: w * 0.94, height: h * 0.94),
                            cornerSize: CGSize(width: w * 0.06, height: w * 0.06))

        // The arch inside it.
        let left = w * 0.24, right = w * 0.76
        let top = h * 0.22, bottom = h * 0.86
        path.move(to: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left, y: top + h * 0.13))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: top),
                          control: CGPoint(x: left, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top + h * 0.13),
                          control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom))

        // A small lamp hanging in the arch.
        path.addEllipse(in: CGRect(x: w * 0.44, y: h * 0.36, width: w * 0.12, height: w * 0.12))
        path.move(to: CGPoint(x: w * 0.5, y: top + h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.36))

        return path
    }
}
