import Foundation

// Qur'anic passages about prayer, in Marmaduke Pickthall's 1930 English rendering,
// *The Meaning of the Glorious Koran*, which is in the public domain.
//
// Only Qur'anic quotation appears in this app. No hadith is quoted anywhere, and no
// Arabic script is shipped, so nothing here depends on a rendering the app cannot verify.
// Pickthall's own conventions are kept exactly as he wrote them: "worship" where a modern
// translator would write "prayer", "the poor-due" for zakat, and his parenthetical
// clarifications in round brackets.

struct SLPassage: Identifiable {
    let id: Int
    let surah: Int
    let surahName: String
    let reference: String
    let theme: SLPassageTheme
    let text: String

    var citation: String { "Surah \(surahName) \(reference)" }
}

enum SLPassageTheme: Int, CaseIterable, Identifiable {
    case command = 0
    case times = 1
    case steadfastness = 2
    case presence = 3
    case congregation = 4
    case warning = 5
    case supplication = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .command: return "The command to pray"
        case .times: return "The times of the day"
        case .steadfastness: return "Constancy"
        case .presence: return "Attention in prayer"
        case .congregation: return "Praying together"
        case .warning: return "A warning"
        case .supplication: return "A supplication"
        }
    }
}

enum SLPassageLibrary {

    static let attribution = """
    All passages are quoted from Marmaduke Pickthall's English rendering of the Qur'an, \
    *The Meaning of the Glorious Koran*, first published in 1930 and long in the public \
    domain. Pickthall's own wording and punctuation are kept unchanged, including his use \
    of "worship" for the prayer and "the poor-due" for zakat. A translation is a reading of \
    the Qur'an, not the Qur'an itself.
    """

    static let all: [SLPassage] = [
        SLPassage(id: 0, surah: 2, surahName: "Al-Baqarah", reference: "2:3", theme: .command,
                  text: "Who believe in the Unseen, and establish worship, and spend of that We have bestowed upon them;"),
        SLPassage(id: 1, surah: 2, surahName: "Al-Baqarah", reference: "2:43", theme: .congregation,
                  text: "Establish worship, pay the poor-due, and bow your heads with those who bow (in worship)."),
        SLPassage(id: 2, surah: 2, surahName: "Al-Baqarah", reference: "2:45", theme: .steadfastness,
                  text: "Seek help in patience and prayer; and truly it is hard save for the humble-minded,"),
        SLPassage(id: 3, surah: 2, surahName: "Al-Baqarah", reference: "2:110", theme: .command,
                  text: "Establish worship, and pay the poor-due; and whatever of good ye send before (you) for your souls, ye will find it with Allah. Lo! Allah is Seer of what ye do."),
        SLPassage(id: 4, surah: 2, surahName: "Al-Baqarah", reference: "2:153", theme: .steadfastness,
                  text: "O ye who believe! Seek help in steadfastness and prayer. Lo! Allah is with the steadfast."),
        SLPassage(id: 5, surah: 2, surahName: "Al-Baqarah", reference: "2:238", theme: .steadfastness,
                  text: "Be guardians of your prayers, and of the midmost prayer, and stand up with devotion to Allah."),
        SLPassage(id: 6, surah: 2, surahName: "Al-Baqarah", reference: "2:277", theme: .command,
                  text: "Lo! those who believe and do good works and establish worship and pay the poor-due, their reward is with their Lord and there shall no fear come upon them neither shall they grieve."),
        SLPassage(id: 7, surah: 4, surahName: "An-Nisa", reference: "4:103", theme: .times,
                  text: "And when ye have performed the act of worship, remember Allah, standing, sitting and reclining. And when ye are in safety, observe proper worship. Worship at fixed hours hath been enjoined on the believers."),
        SLPassage(id: 8, surah: 6, surahName: "Al-An'am", reference: "6:162", theme: .presence,
                  text: "Say: Lo! my worship and my sacrifice and my living and my dying are for Allah, Lord of the Worlds."),
        SLPassage(id: 9, surah: 7, surahName: "Al-A'raf", reference: "7:31", theme: .presence,
                  text: "O Children of Adam! Look to your adornment at every place of worship, and eat and drink, but be not prodigal. Lo! He loveth not the prodigals."),
        SLPassage(id: 10, surah: 8, surahName: "Al-Anfal", reference: "8:3", theme: .command,
                  text: "Who establish worship and spend of that We have bestowed on them."),
        SLPassage(id: 11, surah: 11, surahName: "Hud", reference: "11:114", theme: .times,
                  text: "Establish worship at the two ends of the day and in some watches of the night. Lo! good deeds annul ill deeds. This is reminder for the mindful."),
        SLPassage(id: 12, surah: 13, surahName: "Ar-Ra'd", reference: "13:28", theme: .presence,
                  text: "Who have believed and whose hearts have rest in the remembrance of Allah. Verily in the remembrance of Allah do hearts find rest!"),
        SLPassage(id: 13, surah: 14, surahName: "Ibrahim", reference: "14:31", theme: .command,
                  text: "Tell My bondmen who believe to establish worship and spend of that which We have given them, secretly and publicly, before a day cometh wherein there will be neither traffick nor befriending."),
        SLPassage(id: 14, surah: 14, surahName: "Ibrahim", reference: "14:40", theme: .supplication,
                  text: "My Lord! Make me to establish proper worship, and some of my posterity (also); our Lord! and accept my prayer."),
        SLPassage(id: 15, surah: 17, surahName: "Bani Isra'il", reference: "17:78", theme: .times,
                  text: "Establish worship at the going down of the sun until the dark of night, and (the recital of) the Qur'an at dawn. Lo! (the recital of) the Qur'an at dawn is ever witnessed."),
        SLPassage(id: 16, surah: 17, surahName: "Bani Isra'il", reference: "17:79", theme: .times,
                  text: "And some part of the night awake for it, a largess for thee. It may be that thy Lord will raise thee to a praised estate."),
        SLPassage(id: 17, surah: 19, surahName: "Maryam", reference: "19:31", theme: .steadfastness,
                  text: "And hath made me blessed wheresoever I may be, and hath enjoined upon me prayer and almsgiving so long as I remain alive,"),
        SLPassage(id: 18, surah: 19, surahName: "Maryam", reference: "19:59", theme: .warning,
                  text: "Now there hath succeeded them a later generation who have ruined worship and have followed lusts. But they will meet deception."),
        SLPassage(id: 19, surah: 20, surahName: "Ta Ha", reference: "20:14", theme: .command,
                  text: "Lo! I, even I, am Allah, There is no God save Me. So serve Me and establish worship for My remembrance."),
        SLPassage(id: 20, surah: 20, surahName: "Ta Ha", reference: "20:132", theme: .steadfastness,
                  text: "And enjoin upon thy people worship, and be constant therein. We ask not of thee a provision: We provide for thee. And the sequel is for righteousness."),
        SLPassage(id: 21, surah: 22, surahName: "Al-Hajj", reference: "22:77", theme: .command,
                  text: "O ye who believe! Bow down and prostrate yourselves, and worship your Lord, and do good, that haply ye may prosper."),
        SLPassage(id: 22, surah: 23, surahName: "Al-Mu'minun", reference: "23:1-2", theme: .presence,
                  text: "Successful indeed are the believers, who are humble in their prayers,"),
        SLPassage(id: 23, surah: 23, surahName: "Al-Mu'minun", reference: "23:9", theme: .steadfastness,
                  text: "And who pay heed to their prayers."),
        SLPassage(id: 24, surah: 24, surahName: "An-Nur", reference: "24:37", theme: .steadfastness,
                  text: "Men whom neither merchandise nor sale beguileth from remembrance of Allah and constancy in prayer and paying to the poor their due; who fear a day when hearts and eyeballs will be overturned;"),
        SLPassage(id: 25, surah: 24, surahName: "An-Nur", reference: "24:56", theme: .command,
                  text: "Establish worship and pay the poor-due and obey the messenger, that haply ye may find mercy."),
        SLPassage(id: 26, surah: 29, surahName: "Al-Ankabut", reference: "29:45", theme: .presence,
                  text: "Recite that which hath been inspired in thee of the Scripture, and establish worship. Lo! worship preserveth from lewdness and iniquity, but verily remembrance of Allah is more important. And Allah knoweth what ye do."),
        SLPassage(id: 27, surah: 30, surahName: "Ar-Rum", reference: "30:17-18", theme: .times,
                  text: "So glory be to Allah when ye enter the night and when ye enter the morning \u{2014} unto Him be praise in the heavens and the earth! \u{2014} and at the sun's decline and in the noonday."),
        SLPassage(id: 28, surah: 31, surahName: "Luqman", reference: "31:17", theme: .steadfastness,
                  text: "O my dear son! Establish worship and enjoin kindness and forbid iniquity, and persevere whatever may befall thee. Lo! that is of the steadfast heart of things."),
        SLPassage(id: 29, surah: 33, surahName: "Al-Ahzab", reference: "33:41-42", theme: .times,
                  text: "O ye who believe! Remember Allah with much remembrance. And glorify Him early and late."),
        SLPassage(id: 30, surah: 35, surahName: "Fatir", reference: "35:29", theme: .command,
                  text: "Lo! those who read the Scripture of Allah, and establish worship, and spend of that which We have bestowed on them secretly and openly, they look forward to imperishable gain,"),
        SLPassage(id: 31, surah: 42, surahName: "Ash-Shura", reference: "42:38", theme: .congregation,
                  text: "And those who answer the call of their Lord and establish worship, and whose affairs are a matter of counsel, and who spend of what We have bestowed on them,"),
        SLPassage(id: 32, surah: 50, surahName: "Qaf", reference: "50:39", theme: .times,
                  text: "Therefor (O Muhammad) bear with what they say, and hymn the praise of thy Lord before the rising and before the setting of the sun;"),
        SLPassage(id: 33, surah: 62, surahName: "Al-Jumu'ah", reference: "62:9", theme: .congregation,
                  text: "O ye who believe! When the call is heard for the prayer of the day of congregation, haste unto remembrance of Allah and leave your trading. That is better for you if ye did but know."),
        SLPassage(id: 34, surah: 62, surahName: "Al-Jumu'ah", reference: "62:10", theme: .congregation,
                  text: "And when the prayer is ended, then disperse in the land and seek of Allah's bounty, and remember Allah much, that ye may be successful."),
        SLPassage(id: 35, surah: 70, surahName: "Al-Ma'arij", reference: "70:22-23", theme: .steadfastness,
                  text: "Save worshippers, who are constant at their worship"),
        SLPassage(id: 36, surah: 70, surahName: "Al-Ma'arij", reference: "70:34", theme: .presence,
                  text: "And those who are attentive at their worship."),
        SLPassage(id: 37, surah: 87, surahName: "Al-A'la", reference: "87:14-15", theme: .presence,
                  text: "He is successful who groweth, and remembereth the name of his Lord, so prayeth,"),
        SLPassage(id: 38, surah: 96, surahName: "Al-Alaq", reference: "96:19", theme: .command,
                  text: "Nay, Obey not thou him. But prostrate thyself, and draw near (unto Allah)."),
        SLPassage(id: 39, surah: 98, surahName: "Al-Bayyinah", reference: "98:5", theme: .command,
                  text: "And they are ordered naught else than to serve Allah, keeping religion pure for Him, as men by nature upright, and to establish worship and to pay the poor-due. That is true religion."),
        SLPassage(id: 40, surah: 107, surahName: "Al-Ma'un", reference: "107:4-5", theme: .warning,
                  text: "Ah, woe unto worshippers who are heedless of their prayer;"),
        SLPassage(id: 41, surah: 108, surahName: "Al-Kawthar", reference: "108:2", theme: .command,
                  text: "So pray unto thy Lord, and sacrifice.")
    ]

    static var count: Int { all.count }

    static func passages(theme: SLPassageTheme) -> [SLPassage] {
        all.filter { $0.theme == theme }
    }

    /// A stable passage for a given day, so the Today screen shows one that changes daily
    /// but never flickers between redraws.
    static func daily(for day: Date, timeZoneID: String) -> SLPassage {
        guard !all.isEmpty else {
            return SLPassage(id: 0, surah: 0, surahName: "", reference: "", theme: .command, text: "")
        }
        let key = SLTimeFormat.dayKey(day, timeZoneID: timeZoneID)
        // Unsigned throughout: `abs()` on a wrapped-around negative Int traps at the one
        // value it cannot negate, and a hash is exactly the sort of thing that reaches it.
        var hash: UInt64 = 5381
        for scalar in key.unicodeScalars { hash = (hash &* 33) &+ UInt64(scalar.value) }
        let index = Int(hash % UInt64(all.count))
        return all[index]
    }
}
