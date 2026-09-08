import Foundation

// Named milestones. Each one is a plain count with a target, so what unlocks it is never
// a mystery and the progress bar under it is the honest number, not a guess.

enum SLMilestoneGroup: Int, CaseIterable, Identifiable {
    case consistency = 0
    case dawn = 1
    case congregation = 2
    case punctuality = 3
    case voluntary = 4
    case makeUp = 5
    case record = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .consistency: return "Complete days"
        case .dawn: return "Fajr"
        case .congregation: return "In congregation"
        case .punctuality: return "Punctuality"
        case .voluntary: return "Voluntary prayers"
        case .makeUp: return "Making up"
        case .record: return "Keeping the record"
        }
    }
}

enum SLMilestoneRule {
    case completeStreak(Int)
    case completeDaysTotal(Int)
    case prayerPerformedTotal(SLPrayer, Int)
    case prayerStreak(SLPrayer, Int)
    case fajrCongregationStreak(Int)
    case congregationTotal(Int)
    case fullCongregationDays(Int)
    case jumuahCongregation(Int)
    case punctualTotal(Int)
    case markedTotal(Int)
    case naflTotal(SLNafl, Int)
    case qadaPaidTotal(Int)
    case daysLogged(Int)

    var target: Int {
        switch self {
        case .completeStreak(let n), .completeDaysTotal(let n), .fajrCongregationStreak(let n),
             .congregationTotal(let n), .fullCongregationDays(let n), .jumuahCongregation(let n),
             .punctualTotal(let n), .markedTotal(let n), .qadaPaidTotal(let n), .daysLogged(let n):
            return max(1, n)
        case .prayerPerformedTotal(_, let n), .prayerStreak(_, let n), .naflTotal(_, let n):
            return max(1, n)
        }
    }

    func current(stats: SLStatistics, qadaPaid: Int) -> Int {
        switch self {
        case .completeStreak: return stats.longestStreak
        case .completeDaysTotal: return stats.completeDays
        case .prayerPerformedTotal(let prayer, _): return stats.performedByPrayer[prayer.rawValue]
        case .prayerStreak(let prayer, _): return stats.prayerLongestStreak[prayer.rawValue]
        case .fajrCongregationStreak: return stats.fajrCongregationBest
        case .congregationTotal: return stats.congregationTotal
        case .fullCongregationDays: return stats.fullCongregationDays
        case .jumuahCongregation: return stats.jumuahCongregationDays
        case .punctualTotal: return stats.punctualTotal
        case .markedTotal: return stats.markedTotal
        case .naflTotal(let item, _): return stats.naflTotals[item.rawValue]
        case .qadaPaidTotal: return qadaPaid
        case .daysLogged: return stats.totalDaysLogged
        }
    }
}

struct SLMilestone: Identifiable {
    let id: Int
    let title: String
    let line: String
    let group: SLMilestoneGroup
    let rule: SLMilestoneRule

    func progress(stats: SLStatistics, qadaPaid: Int) -> (current: Int, target: Int, unlocked: Bool) {
        let target = rule.target
        let current = min(rule.current(stats: stats, qadaPaid: qadaPaid), target)
        return (current, target, current >= target)
    }
}

enum SLMilestoneLibrary {

    static let all: [SLMilestone] = {
        var id = 0
        func m(_ title: String, _ line: String, _ group: SLMilestoneGroup, _ rule: SLMilestoneRule) -> SLMilestone {
            defer { id += 1 }
            return SLMilestone(id: id, title: title, line: line, group: group, rule: rule)
        }

        return [
            // Complete days
            m("First Full Day", "All five prayers recorded as performed on one day.",
              .consistency, .completeDaysTotal(1)),
            m("Three in a Row", "Three consecutive complete days.",
              .consistency, .completeStreak(3)),
            m("One Full Week", "Seven consecutive complete days.",
              .consistency, .completeStreak(7)),
            m("Ten Days Held", "Ten consecutive complete days.",
              .consistency, .completeStreak(10)),
            m("A Fortnight", "Fourteen consecutive complete days.",
              .consistency, .completeStreak(14)),
            m("Twenty-One Days", "Three unbroken weeks.",
              .consistency, .completeStreak(21)),
            m("One Full Month", "Thirty consecutive complete days.",
              .consistency, .completeStreak(30)),
            m("Forty Days", "Forty consecutive complete days.",
              .consistency, .completeStreak(40)),
            m("Sixty Days", "Two unbroken months.",
              .consistency, .completeStreak(60)),
            m("Ninety Days", "A full season without a break.",
              .consistency, .completeStreak(90)),
            m("Half a Year", "One hundred and eighty consecutive complete days.",
              .consistency, .completeStreak(180)),
            m("A Full Year", "Three hundred and sixty-five consecutive complete days.",
              .consistency, .completeStreak(365)),
            m("One Hundred Complete Days", "A hundred complete days in total, consecutive or not.",
              .consistency, .completeDaysTotal(100)),

            // Fajr
            m("First Dawn", "Your first Fajr recorded as performed.",
              .dawn, .prayerPerformedTotal(.fajr, 1)),
            m("Seven Dawns", "Fajr performed seven days running.",
              .dawn, .prayerStreak(.fajr, 7)),
            m("Thirty Dawns", "Fajr performed thirty days running.",
              .dawn, .prayerStreak(.fajr, 30)),
            m("One Hundred Dawns", "A hundred Fajr prayers recorded in total.",
              .dawn, .prayerPerformedTotal(.fajr, 100)),
            m("Three Hundred Dawns", "Three hundred Fajr prayers recorded in total.",
              .dawn, .prayerPerformedTotal(.fajr, 300)),
            m("Seven Fajr in Congregation", "A week of dawn prayers with others.",
              .dawn, .fajrCongregationStreak(7)),
            m("Forty Fajr in Congregation", "Forty consecutive dawns in congregation.",
              .dawn, .fajrCongregationStreak(40)),

            // Congregation
            m("First Congregation", "One prayer recorded as prayed with others.",
              .congregation, .congregationTotal(1)),
            m("Twenty-Five Together", "Twenty-five prayers in congregation.",
              .congregation, .congregationTotal(25)),
            m("One Hundred Together", "A hundred prayers in congregation.",
              .congregation, .congregationTotal(100)),
            m("Five Hundred Together", "Five hundred prayers in congregation.",
              .congregation, .congregationTotal(500)),
            m("A Whole Day Together", "All five prayers of one day in congregation.",
              .congregation, .fullCongregationDays(1)),
            m("Seven Days Together", "Seven separate days with all five in congregation.",
              .congregation, .fullCongregationDays(7)),
            m("Thirty Days Together", "Thirty separate days with all five in congregation.",
              .congregation, .fullCongregationDays(30)),
            m("Jumu'ah Kept", "One Friday midday prayer recorded in congregation.",
              .congregation, .jumuahCongregation(1)),
            m("Twelve Fridays", "Twelve Jumu'ah prayers in congregation.",
              .congregation, .jumuahCongregation(12)),
            m("Fifty Fridays", "Fifty Jumu'ah prayers in congregation.",
              .congregation, .jumuahCongregation(50)),

            // Punctuality
            m("One Hundred On Time", "A hundred prayers inside their own window.",
              .punctuality, .punctualTotal(100)),
            m("Five Hundred On Time", "Five hundred prayers inside their own window.",
              .punctuality, .punctualTotal(500)),
            m("One Thousand On Time", "A thousand prayers inside their own window.",
              .punctuality, .punctualTotal(1000)),
            m("Two Thousand Recorded", "Two thousand prayers marked, however they went.",
              .punctuality, .markedTotal(2000)),
            m("Maghrib Held Thirty Days", "Maghrib performed thirty days running.",
              .punctuality, .prayerStreak(.maghrib, 30)),
            m("Isha Held Thirty Days", "Isha performed thirty days running.",
              .punctuality, .prayerStreak(.isha, 30)),
            m("Asr Held Thirty Days", "Asr performed thirty days running.",
              .punctuality, .prayerStreak(.asr, 30)),

            // Voluntary
            m("First Witr", "The night's prayer closed with Witr.",
              .voluntary, .naflTotal(.witr, 1)),
            m("Thirty Witr", "Witr recorded on thirty nights.",
              .voluntary, .naflTotal(.witr, 30)),
            m("First Tahajjud", "One night's prayer in the last part of the night.",
              .voluntary, .naflTotal(.tahajjud, 1)),
            m("Ten Nights Standing", "Tahajjud recorded on ten nights.",
              .voluntary, .naflTotal(.tahajjud, 10)),
            m("Forty Nights Standing", "Tahajjud recorded on forty nights.",
              .voluntary, .naflTotal(.tahajjud, 40)),
            m("First Duha", "One mid-morning prayer recorded.",
              .voluntary, .naflTotal(.duha, 1)),
            m("Thirty Duha", "Duha recorded on thirty mornings.",
              .voluntary, .naflTotal(.duha, 30)),
            m("Sunnah of Fajr, Thirty Times", "The two rak'ah before Fajr, thirty times.",
              .voluntary, .naflTotal(.sunnahFajr, 30)),

            // Making up
            m("First Make-Up", "One missed prayer made up and cleared from the ledger.",
              .makeUp, .qadaPaidTotal(1)),
            m("Ten Made Up", "Ten missed prayers made up.",
              .makeUp, .qadaPaidTotal(10)),
            m("Fifty Made Up", "Fifty missed prayers made up.",
              .makeUp, .qadaPaidTotal(50)),
            m("One Hundred Made Up", "A hundred missed prayers made up.",
              .makeUp, .qadaPaidTotal(100)),

            // Keeping the record
            m("Thirty Days Logged", "Thirty days with something recorded on them.",
              .record, .daysLogged(30)),
            m("One Hundred Days Logged", "A hundred days with something recorded on them.",
              .record, .daysLogged(100)),
            m("One Year of Records", "Three hundred and sixty-five days recorded.",
              .record, .daysLogged(365))
        ]
    }()

    static var count: Int { all.count }

    static func grouped() -> [(group: SLMilestoneGroup, items: [SLMilestone])] {
        SLMilestoneGroup.allCases.compactMap { group in
            let items = all.filter { $0.group == group }
            return items.isEmpty ? nil : (group: group, items: items)
        }
    }

    static func unlockedCount(stats: SLStatistics, qadaPaid: Int) -> Int {
        all.filter { $0.progress(stats: stats, qadaPaid: qadaPaid).unlocked }.count
    }
}
