import SwiftUI

// MARK: - Palette
//
// Every colour is a literal. Nothing here reads a system semantic colour, so the app
// renders identically no matter what appearance the device is set to; the native branch
// additionally pins itself with `.preferredColorScheme(.light)`.
// The values are lifted from the app icon so the icon and the first screen read as one
// product: warm sand ground, deep teal field, terracotta and gold accents.

enum SLTheme {

    // Ground
    static let canvas      = Color(red: 0.976, green: 0.953, blue: 0.898)   // #F9F3E5
    static let canvasDeep  = Color(red: 0.957, green: 0.922, blue: 0.847)   // #F4EBD8
    static let surface     = Color(red: 0.999, green: 0.988, blue: 0.965)   // #FFFCF6
    static let surfaceAlt  = Color(red: 0.984, green: 0.965, blue: 0.918)   // #FBF6EA
    static let hairline    = Color(red: 0.878, green: 0.831, blue: 0.741)   // #E0D4BD

    // Brand
    static let teal        = Color(red: 0.035, green: 0.290, blue: 0.286)   // #094A49
    static let tealSoft    = Color(red: 0.243, green: 0.451, blue: 0.435)   // #3E736F
    static let tealWash    = Color(red: 0.878, green: 0.918, blue: 0.906)   // #E0EAE7
    static let clay        = Color(red: 0.725, green: 0.278, blue: 0.149)   // #B94726
    static let claySoft    = Color(red: 0.949, green: 0.878, blue: 0.851)   // #F2E0D9
    static let gold        = Color(red: 0.953, green: 0.757, blue: 0.400)   // #F3C166
    static let goldDeep    = Color(red: 0.784, green: 0.573, blue: 0.216)   // #C89237

    // Text
    static let ink         = Color(red: 0.145, green: 0.129, blue: 0.106)   // #25211B
    static let inkSoft     = Color(red: 0.376, green: 0.345, blue: 0.294)   // #60584B
    static let inkFaint    = Color(red: 0.573, green: 0.537, blue: 0.475)   // #92897A

    // State colours for the four marks a prayer can carry
    static let stateJamaah = Color(red: 0.106, green: 0.400, blue: 0.325)   // #1B6653
    static let stateOnTime = Color(red: 0.325, green: 0.573, blue: 0.322)   // #539252
    static let stateLate   = Color(red: 0.847, green: 0.639, blue: 0.216)   // #D8A337
    static let stateMissed = Color(red: 0.729, green: 0.318, blue: 0.243)   // #BA513E
    static let stateBlank  = Color(red: 0.847, green: 0.812, blue: 0.741)   // #D8CFBD

    /// Ramp used by the month heatmap, from "nothing logged" to "a full day in congregation".
    static func heat(_ fraction: Double) -> Color {
        let f = max(0, min(1, fraction))
        if f <= 0 { return canvasDeep }
        // Sand -> gold -> teal.
        if f < 0.5 {
            let t = f / 0.5
            return Color(red: 0.957 + (0.953 - 0.957) * t,
                         green: 0.922 + (0.757 - 0.922) * t,
                         blue: 0.847 + (0.400 - 0.847) * t)
        }
        let t = (f - 0.5) / 0.5
        return Color(red: 0.953 + (0.035 - 0.953) * t,
                     green: 0.757 + (0.290 - 0.757) * t,
                     blue: 0.400 + (0.286 - 0.400) * t)
    }
}

// MARK: - Type scale

enum SLType {
    static func display(_ size: CGFloat = 30) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func title(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func bodyMedium(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .regular) }
    static func label(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .semibold) }
    static func mono(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
    static func quote(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .regular, design: .serif) }
}

// MARK: - Metrics

enum SLMetric {
    /// Content never runs edge to edge on an iPad; it sits in a readable centred column.
    static let readableWidth: CGFloat = 620
    static let cardRadius: CGFloat = 16
    static let tabBarHeight: CGFloat = 56

    /// A width-driven compact switch. Below this the hero blocks drop to their tight layout
    /// instead of letting a flexible child collapse to nothing.
    static func isCompact(_ width: CGFloat) -> Bool { width < 380 }

    /// The screen size, clamped so a `GeometryReader` that over-reports on an iPad
    /// compatibility slice can never push content off the right edge.
    static func safeWidth(_ proposed: CGFloat) -> CGFloat {
        let screen = UIScreen.main.bounds.width
        let usable = proposed > 0 ? proposed : screen
        return min(usable, max(screen, 320))
    }
}

// MARK: - Shared containers

/// The standard card. One rounded rectangle, one hairline, no shadow stack.
struct SLCard<Content: View>: View {
    var padding: CGFloat = 16
    var fill: Color = SLTheme.surface
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(SLTheme.hairline, lineWidth: 1)
            )
    }
}

/// Section heading used above every card group.
struct SLSectionTitle: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased())
                .font(SLType.label(11))
                .tracking(1.4)
                .foregroundColor(SLTheme.inkFaint)
            Spacer(minLength: 8)
            if let trailing = trailing {
                Text(trailing)
                    .font(SLType.caption(11))
                    .foregroundColor(SLTheme.inkFaint)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// The physical top inset of the key window.
///
/// Read from UIKit rather than from a `GeometryReader`, because the strip below lives
/// inside a container that has already consumed the safe area: a proxy there reports zero
/// and the strip would silently have no height at all.
enum SLSafeArea {
    static var top: CGFloat {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
            if let window = window { return window.safeAreaInsets.top }
        }
        return 0
    }
}

/// The opaque strip that owns the top safe area. It is added as the LAST sibling of the
/// root ZStack so a bouncing ScrollView can never draw over the clock. It takes no
/// touches, so nothing underneath loses a tap to it.
struct SLStatusStrip: View {
    var body: some View {
        VStack(spacing: 0) {
            SLTheme.canvas
                .frame(height: SLSafeArea.top)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}
