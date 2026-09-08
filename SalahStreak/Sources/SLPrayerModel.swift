import SwiftUI

// MARK: - The five obligatory prayers, plus sunrise as a boundary marker

enum SLPrayer: Int, CaseIterable, Codable, Identifiable {
    case fajr = 0
    case dhuhr = 1
    case asr = 2
    case maghrib = 3
    case isha = 4

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    /// English transliteration only. No Arabic script is shipped anywhere in this app:
    /// unverifiable shaping is worse than none.
    var transliteration: String {
        switch self {
        case .fajr: return "al-Fajr"
        case .dhuhr: return "az-Zuhr"
        case .asr: return "al-Asr"
        case .maghrib: return "al-Maghrib"
        case .isha: return "al-Isha"
        }
    }

    /// The name the Friday midday prayer carries in place of Dhuhr.
    var fridayName: String { self == .dhuhr ? "Jumu'ah" : name }

    var windowSummary: String {
        switch self {
        case .fajr:
            return "From the first true light on the horizon until the sun's upper edge appears."
        case .dhuhr:
            return "From just after the sun passes its highest point until an upright object's shadow reaches the Asr length."
        case .asr:
            return "From the moment the Asr shadow length is reached until the sun sets."
        case .maghrib:
            return "From sunset until the red of the evening twilight has gone."
        case .isha:
            return "From the end of the evening twilight until the true dawn of the following day."
        }
    }

    @ViewBuilder
    func glyph(size: CGFloat, color: Color, weight: CGFloat = 1.7) -> some View {
        let style = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
        switch self {
        case .fajr: SLDawnGlyph().stroke(color, style: style).frame(width: size, height: size)
        case .dhuhr: SLNoonGlyph().stroke(color, style: style).frame(width: size, height: size)
        case .asr: SLShadowGlyph().stroke(color, style: style).frame(width: size, height: size)
        case .maghrib: SLSunsetGlyph().stroke(color, style: style).frame(width: size, height: size)
        case .isha: SLNightGlyph().stroke(color, style: style).frame(width: size, height: size)
        }
    }
}

// MARK: - How a prayer was performed

enum SLPrayerState: Int, CaseIterable, Codable {
    case none = 0
    case congregation = 1
    case onTime = 2
    case late = 3
    case missed = 4

    /// The order the four marks are offered in, best to worst. `none` is not offered —
    /// it is what a prayer reverts to when its current mark is tapped again.
    static var markable: [SLPrayerState] { [.congregation, .onTime, .late, .missed] }

    var title: String {
        switch self {
        case .none: return "Not recorded"
        case .congregation: return "In congregation"
        case .onTime: return "On time"
        case .late: return "Late"
        case .missed: return "Missed"
        }
    }

    var shortTitle: String {
        switch self {
        case .none: return "—"
        case .congregation: return "Jama'ah"
        case .onTime: return "On time"
        case .late: return "Late"
        case .missed: return "Missed"
        }
    }

    var detail: String {
        switch self {
        case .none: return "No mark yet for this prayer."
        case .congregation: return "Prayed together with others, in a mosque or in a group."
        case .onTime: return "Prayed alone, inside the prayer's own window."
        case .late: return "Prayed after the window had already closed."
        case .missed: return "Not prayed. It goes to the make-up ledger."
        }
    }

    var colour: Color {
        switch self {
        case .none: return SLTheme.stateBlank
        case .congregation: return SLTheme.stateJamaah
        case .onTime: return SLTheme.stateOnTime
        case .late: return SLTheme.stateLate
        case .missed: return SLTheme.stateMissed
        }
    }

    /// Counts towards a completed day.
    var isPerformed: Bool { self == .congregation || self == .onTime || self == .late }
    /// Counts towards the on-time percentage.
    var isPunctual: Bool { self == .congregation || self == .onTime }

    /// How much of the completion ring one prayer in this state fills.
    var ringWeight: Double {
        switch self {
        case .congregation: return 1.0
        case .onTime: return 1.0
        case .late: return 0.6
        case .missed, .none: return 0.0
        }
    }
}

// MARK: - Optional voluntary prayers tracked per day

enum SLNafl: Int, CaseIterable, Codable, Identifiable {
    case sunnahFajr = 0
    case sunnahDhuhr = 1
    case sunnahAsr = 2
    case sunnahMaghrib = 3
    case sunnahIsha = 4
    case witr = 5
    case tahajjud = 6
    case duha = 7

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunnahFajr: return "Sunnah of Fajr"
        case .sunnahDhuhr: return "Sunnah of Dhuhr"
        case .sunnahAsr: return "Sunnah of Asr"
        case .sunnahMaghrib: return "Sunnah of Maghrib"
        case .sunnahIsha: return "Sunnah of Isha"
        case .witr: return "Witr"
        case .tahajjud: return "Tahajjud"
        case .duha: return "Duha"
        }
    }

    var subtitle: String {
        switch self {
        case .sunnahFajr: return "2 rak'ah before the fard"
        case .sunnahDhuhr: return "4 before and 2 after the fard"
        case .sunnahAsr: return "4 before the fard, nafl"
        case .sunnahMaghrib: return "2 rak'ah after the fard"
        case .sunnahIsha: return "2 rak'ah after the fard"
        case .witr: return "Odd-numbered, after Isha"
        case .tahajjud: return "In the last part of the night"
        case .duha: return "Mid-morning, after the sun has risen"
        }
    }

    /// The fard prayer this voluntary prayer sits beside, when there is one.
    var attachedTo: SLPrayer? {
        switch self {
        case .sunnahFajr: return .fajr
        case .sunnahDhuhr: return .dhuhr
        case .sunnahAsr: return .asr
        case .sunnahMaghrib: return .maghrib
        case .sunnahIsha, .witr: return .isha
        case .tahajjud, .duha: return nil
        }
    }
}

// MARK: - Calculation method

/// How a method fixes the start of Isha.
enum SLIshaRule: Equatable {
    /// A solar depression angle, in degrees below the horizon.
    case depression(Double)
    /// A fixed interval after Maghrib, in minutes. Used by the Umm al-Qura family.
    case interval(minutes: Double, ramadanMinutes: Double)
}

struct SLMethod: Identifiable, Equatable {
    let id: Int
    let name: String
    let authority: String
    let region: String
    let fajrAngle: Double
    let ishaRule: SLIshaRule
    let summary: String

    static func == (a: SLMethod, b: SLMethod) -> Bool { a.id == b.id }

    var fajrLabel: String { SLMethod.angleText(fajrAngle) }

    var ishaLabel: String {
        switch ishaRule {
        case .depression(let a): return SLMethod.angleText(a)
        case .interval(let m, _): return "\(Int(m)) min after Maghrib"
        }
    }

    /// The line shown under every method row so the choice is made with the numbers visible.
    var angleLine: String { "Fajr \(fajrLabel)  ·  Isha \(ishaLabel)" }

    static func angleText(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 { return "\(Int(value.rounded()))\u{00B0}" }
        return String(format: "%.1f\u{00B0}", value)
    }
}

enum SLMethodCatalogue {

    static let all: [SLMethod] = [
        SLMethod(id: 0,
                 name: "Muslim World League",
                 authority: "Muslim World League, Makkah",
                 region: "Europe, the Far East, and the common default elsewhere",
                 fajrAngle: 18.0,
                 ishaRule: .depression(17.0),
                 summary: "The most widely used general-purpose set of angles. Fajr is taken at 18 degrees of solar depression and Isha at 17 degrees."),
        SLMethod(id: 1,
                 name: "ISNA",
                 authority: "Islamic Society of North America",
                 region: "United States and Canada",
                 fajrAngle: 15.0,
                 ishaRule: .depression(15.0),
                 summary: "The shallowest angles in common use, adopted so that Fajr and Isha remain workable through the long northern summer. Both twilights are taken at 15 degrees."),
        SLMethod(id: 2,
                 name: "Egyptian General Authority",
                 authority: "Egyptian General Authority of Survey",
                 region: "Egypt, the Levant, parts of Africa and Malaysia",
                 fajrAngle: 19.5,
                 ishaRule: .depression(17.5),
                 summary: "A deep Fajr angle of 19.5 degrees with Isha at 17.5 degrees. Long established and followed well beyond Egypt itself."),
        SLMethod(id: 3,
                 name: "Umm al-Qura",
                 authority: "Umm al-Qura University, Makkah",
                 region: "Saudi Arabia",
                 fajrAngle: 18.5,
                 ishaRule: .interval(minutes: 90, ramadanMinutes: 120),
                 summary: "Fajr at 18.5 degrees. Isha is not an angle at all: it is a fixed 90 minutes after Maghrib, extended to 120 minutes during Ramadan."),
        SLMethod(id: 4,
                 name: "Karachi",
                 authority: "University of Islamic Sciences, Karachi",
                 region: "Pakistan, India, Bangladesh and Afghanistan",
                 fajrAngle: 18.0,
                 ishaRule: .depression(18.0),
                 summary: "Symmetric twilight angles, 18 degrees for both Fajr and Isha. The usual choice across South Asia."),
        SLMethod(id: 5,
                 name: "Singapore",
                 authority: "Majlis Ugama Islam Singapura",
                 region: "Singapore, Brunei and parts of Indonesia",
                 fajrAngle: 20.0,
                 ishaRule: .depression(18.0),
                 summary: "The deepest Fajr angle in common use, 20 degrees, suited to the very short equatorial twilight, with Isha at 18 degrees.")
    ]

    static func method(id: Int) -> SLMethod {
        guard id >= 0, id < all.count else { return all[0] }
        return all[id]
    }

    static var count: Int { all.count }
}

// MARK: - Asr school

enum SLAsrSchool: Int, CaseIterable, Codable {
    case standard = 0
    case hanafi = 1

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .hanafi: return "Hanafi"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return "Shafi'i, Maliki, Hanbali"
        case .hanafi: return "Hanafi"
        }
    }

    var shadowFactor: Double { self == .standard ? 1.0 : 2.0 }

    var explanation: String {
        switch self {
        case .standard:
            return "Asr begins when an upright object's shadow has grown by one further object length, measured from the shadow it already casts at midday. This is the position of the Shafi'i, Maliki and Hanbali schools."
        case .hanafi:
            return "Asr begins when an upright object's shadow has grown by two further object lengths, measured from the shadow it already casts at midday. It falls roughly 40 to 70 minutes later than the standard time."
        }
    }
}

// MARK: - High latitude rule

enum SLHighLatRule: Int, CaseIterable, Codable {
    case none = 0
    case middleOfNight = 1
    case seventhOfNight = 2
    case angleBased = 3

    var title: String {
        switch self {
        case .none: return "No adjustment"
        case .middleOfNight: return "Middle of the night"
        case .seventhOfNight: return "One seventh of the night"
        case .angleBased: return "Angle based"
        }
    }

    var shortTitle: String {
        switch self {
        case .none: return "None"
        case .middleOfNight: return "Mid-night"
        case .seventhOfNight: return "1/7 night"
        case .angleBased: return "Angle"
        }
    }

    var explanation: String {
        switch self {
        case .none:
            return "Nothing is adjusted. Above roughly 48 degrees of latitude the sun may not fall far enough below the horizon in summer for Fajr or Isha to have any solution at all; on those days this app shows a dash and says so, rather than inventing a time."
        case .middleOfNight:
            return "The night, from sunset to sunrise, is halved. Fajr may not begin before the midpoint and Isha may not begin after it. The simplest and most conservative of the three."
        case .seventhOfNight:
            return "The night is divided into seven equal parts. Fajr is capped at one seventh of the night before sunrise, and Isha at one seventh of the night after sunset."
        case .angleBased:
            return "The night is divided in proportion to the method's own twilight angles: the portion used is the angle divided by sixty. A method with a deep Fajr angle therefore keeps a longer pre-dawn interval than a shallow one."
        }
    }
}

// MARK: - Display preferences

enum SLClockStyle: Int, CaseIterable, Codable {
    case twelveHour = 0
    case twentyFourHour = 1

    var title: String { self == .twelveHour ? "12-hour" : "24-hour" }
}

enum SLWeekStart: Int, CaseIterable, Codable {
    case saturday = 0
    case sunday = 1
    case monday = 2

    var title: String {
        switch self {
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        }
    }

    /// Gregorian weekday number as `Calendar` reports it: 1 = Sunday.
    var calendarWeekday: Int {
        switch self {
        case .saturday: return 7
        case .sunday: return 1
        case .monday: return 2
        }
    }

    /// Column headers in this week's order, starting from the chosen first day.
    var dayInitials: [String] {
        let base = ["S", "M", "T", "W", "T", "F", "S"]          // Sunday first
        let shift = calendarWeekday - 1
        return (0..<7).map { base[($0 + shift) % 7] }
    }

    var dayShortNames: [String] {
        let base = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let shift = calendarWeekday - 1
        return (0..<7).map { base[($0 + shift) % 7] }
    }
}
