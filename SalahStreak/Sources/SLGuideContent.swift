import Foundation

// The written reference material. Everything here is plainly worded, avoids ruling on
// points the schools differ over, and says so wherever a count is not agreed. No Arabic
// script is shipped anywhere in the app: transliteration and English only, because an
// unverifiable rendering of a sacred text is worse than none at all.

// MARK: - Per-prayer reference

struct SLPrayerReference: Identifiable {
    let prayer: SLPrayer
    var id: Int { prayer.rawValue }

    /// The obligatory rak'ahs. This number is agreed.
    let fardRakah: Int
    /// Emphasised sunnah before the fard, where there is one.
    let sunnahBefore: String
    /// Emphasised sunnah after the fard, where there is one.
    let sunnahAfter: String
    /// Further voluntary rak'ahs commonly prayed alongside it.
    let voluntary: String
    /// The window, in words a person can check against the sky.
    let window: String
    /// What sets this prayer apart from the other four.
    let distinct: String
    /// Anything a reader should know before treating the counts above as final.
    let caveat: String
}

enum SLPrayerGuide {

    static let all: [SLPrayerReference] = [
        SLPrayerReference(
            prayer: .fajr,
            fardRakah: 2,
            sunnahBefore: "2 rak'ah, emphasised",
            sunnahAfter: "None",
            voluntary: "None after the fard until the sun has fully risen",
            window: "Begins at the true dawn — the first light spreading along the horizon — and ends the moment the sun's upper edge appears. It is the shortest window of the five, and the only one that ends at sunrise rather than at the next prayer.",
            distinct: "Fajr is recited aloud, and it is the prayer most often missed, because the window closes while most people are still asleep. The two sunnah rak'ah before it are the most emphasised voluntary prayer of the day.",
            caveat: "Once the sun has begun to rise the window has closed. A Fajr prayed after sunrise is a make-up, and this app records it as late."
        ),
        SLPrayerReference(
            prayer: .dhuhr,
            fardRakah: 4,
            sunnahBefore: "4 rak'ah, emphasised",
            sunnahAfter: "2 rak'ah, emphasised",
            voluntary: "A further 2 rak'ah after the sunnah are commonly prayed",
            window: "Begins shortly after the sun has passed its highest point of the day and ends when an upright object's shadow has grown to the Asr length. It is usually the longest window of the five.",
            distinct: "Dhuhr is prayed silently. On Friday it is replaced entirely by Jumu'ah, which is two rak'ah preceded by the sermon and prayed in congregation.",
            caveat: "The Hanafi and Shafi'i schools count the emphasised sunnah before Dhuhr differently — four together in one school, two pairs in another. Both are within the tradition."
        ),
        SLPrayerReference(
            prayer: .asr,
            fardRakah: 4,
            sunnahBefore: "4 rak'ah, not emphasised",
            sunnahAfter: "None",
            voluntary: "Nothing voluntary after the fard until Maghrib",
            window: "Begins when an upright object's shadow has grown by one further object length beyond its midday shadow — two further lengths in the Hanafi reckoning — and ends at sunset.",
            distinct: "Asr is the prayer whose start time depends on which school you follow, which is why this app asks you to choose. It is prayed silently, and there is a long-standing emphasis on not letting it slip until the sun has begun to redden.",
            caveat: "The Standard and Hanafi Asr times differ by roughly forty to seventy minutes depending on the season and latitude. Neither is a mistake."
        ),
        SLPrayerReference(
            prayer: .maghrib,
            fardRakah: 3,
            sunnahBefore: "None emphasised",
            sunnahAfter: "2 rak'ah, emphasised",
            voluntary: "Some pray a further 2 light rak'ah before the fard while waiting",
            window: "Begins the moment the sun's disc has fully set and ends when the red of the evening twilight has gone from the sky.",
            distinct: "Maghrib is the only prayer with an odd number of obligatory rak'ah, and the only one whose window is measured from a moment anyone can watch happen. The first two rak'ah are recited aloud.",
            caveat: "Its window is short — often under an hour and a half — which is why it is the prayer most often prayed immediately rather than delayed."
        ),
        SLPrayerReference(
            prayer: .isha,
            fardRakah: 4,
            sunnahBefore: "None emphasised",
            sunnahAfter: "2 rak'ah, emphasised",
            voluntary: "Witr, an odd number of rak'ah, closes the night's prayers",
            window: "Begins when the evening twilight has faded completely and runs until the true dawn of the following day. In practice it is best prayed before the middle of the night.",
            distinct: "Isha is the only window that crosses midnight, and this app follows it across: a prayer marked at half past midnight is filed against the day that has just ended, not the one that has just begun. The first two rak'ah are recited aloud.",
            caveat: "Witr is treated as obligatory in the Hanafi school and as a strongly emphasised sunnah in the others. It is tracked here as a voluntary prayer for that reason."
        )
    ]

    static func reference(for prayer: SLPrayer) -> SLPrayerReference {
        all.first { $0.prayer == prayer } ?? all[0]
    }

    static let jumuahNote = """
    On Friday the midday prayer is Jumu'ah. It is two rak'ah rather than four, it is prayed \
    aloud, and it is preceded by a sermon delivered from the pulpit. It is prayed in \
    congregation; someone who cannot attend prays Dhuhr as normal instead. This app shows a \
    Jumu'ah card in place of the Dhuhr card on Fridays, and marking it works exactly the same way.
    """
}

// MARK: - How the prayer is performed

struct SLPostureStep: Identifiable {
    let id: Int
    let posture: SLPosture
    /// The English name of the position.
    let title: String
    /// The transliterated Arabic name.
    let transliteration: String
    /// What the body is doing.
    let description: String
    /// What is said at this point, transliterated.
    let saying: String
    /// What the saying means in English.
    let meaning: String
}

enum SLPosture: Int, CaseIterable {
    case takbir = 0
    case qiyam = 1
    case ruku = 2
    case itidal = 3
    case sujud = 4
    case jalsa = 5
    case tashahhud = 6
    case taslim = 7
}

enum SLPrayerSequence {

    static let intro = """
    One rak'ah is a single cycle of standing, bowing and prostrating. Every prayer is made \
    of these cycles: two for Fajr, four for Dhuhr, and so on. The order below is the order \
    inside one rak'ah, followed by the sitting and the closing that end the prayer. \
    Wording differs a little between schools; what follows is the form most widely taught.
    """

    static let steps: [SLPostureStep] = [
        SLPostureStep(
            id: 0, posture: .takbir,
            title: "The opening declaration",
            transliteration: "Takbirat al-Ihram",
            description: "Stand facing the qiblah, raise both hands to about the level of the ears or shoulders, then lower them and fold them over the chest or below the navel, depending on what you were taught. From this moment until the closing, ordinary speech and movement are set aside.",
            saying: "Allahu akbar",
            meaning: "God is greater."
        ),
        SLPostureStep(
            id: 1, posture: .qiyam,
            title: "Standing",
            transliteration: "Qiyam",
            description: "Standing upright with the eyes lowered towards the place of prostration. An opening supplication is said quietly, then the first chapter of the Qur'an, and after it a further passage in the first two rak'ah of the prayer.",
            saying: "Surat al-Fatihah, then a passage of the reader's choosing",
            meaning: "Al-Fatihah is recited in every single rak'ah of every prayer, without exception."
        ),
        SLPostureStep(
            id: 2, posture: .ruku,
            title: "Bowing",
            transliteration: "Ruku",
            description: "Bend forward from the waist until the back is level, with the hands resting on the knees and the fingers spread. The head stays in line with the back rather than dropping or lifting.",
            saying: "Subhana rabbiya al-azim",
            meaning: "Glory to my Lord, the Most Great. Said three times."
        ),
        SLPostureStep(
            id: 3, posture: .itidal,
            title: "Rising from the bow",
            transliteration: "I'tidal",
            description: "Straighten fully back to standing and pause there. This pause is part of the prayer, not a transition through it — settling before moving on is what distinguishes an unhurried prayer from a rushed one.",
            saying: "Sami' Allahu liman hamidah — Rabbana wa laka al-hamd",
            meaning: "God hears the one who praises Him. Our Lord, and to You belongs all praise."
        ),
        SLPostureStep(
            id: 4, posture: .sujud,
            title: "Prostration",
            transliteration: "Sujud",
            description: "Go down to the ground so that seven parts touch it: the forehead together with the nose, both palms, both knees, and the toes of both feet. The arms are kept clear of the sides and the elbows off the floor.",
            saying: "Subhana rabbiya al-a'la",
            meaning: "Glory to my Lord, the Most High. Said three times."
        ),
        SLPostureStep(
            id: 5, posture: .jalsa,
            title: "Sitting between the two prostrations",
            transliteration: "Jalsa",
            description: "Rise from the ground into a settled sitting position, pause, then prostrate a second time in exactly the same way. Two prostrations, with this sitting between them, complete one rak'ah.",
            saying: "Rabbi ighfir li",
            meaning: "My Lord, forgive me."
        ),
        SLPostureStep(
            id: 6, posture: .tashahhud,
            title: "The sitting declaration",
            transliteration: "Tashahhud",
            description: "After every second rak'ah, and at the end of the prayer, sit and recite the tashahhud with the right index finger raised at the point of testimony. In the final sitting the blessings upon the Prophet and a short supplication follow it.",
            saying: "At-tahiyyatu lillahi wa as-salawatu wa at-tayyibat...",
            meaning: "All greetings, prayers and good things belong to God. The declaration of faith is said within it."
        ),
        SLPostureStep(
            id: 7, posture: .taslim,
            title: "The closing greeting",
            transliteration: "Taslim",
            description: "Turn the head to the right and give the greeting, then to the left and give it again. The prayer is now finished.",
            saying: "As-salamu alaykum wa rahmatullah",
            meaning: "Peace be upon you, and the mercy of God."
        )
    ]

    static let closing = """
    Between the rak'ah there is no pause and no announcement: standing follows the second \
    prostration directly, and the cycle begins again with the recitation. What is described \
    above is the shape of the prayer, not a substitute for learning it from someone who can \
    correct you.
    """
}

// MARK: - About the calculations

enum SLAboutText {

    static let howItWorks = """
    Prayer times are not looked up from anywhere. This app has no network access for its \
    own content and stores nothing outside your device. Each time is solved from the \
    position of the sun for the latitude, longitude and time zone of the city you picked.
    """

    static let theAngles = """
    Dhuhr, Asr and Maghrib follow from the sun itself: Dhuhr from the moment it crosses the \
    meridian, Asr from the length of a shadow, Maghrib from the moment the disc sets. Fajr \
    and Isha are different. They depend on how far below the horizon the sun has to be for \
    the twilight to be considered begun or ended, and that depth is a judgement, not a \
    measurement. Different authorities settled on different angles, which is why this app \
    asks you to choose one and shows you its numbers.
    """

    static let highLatitude = """
    Above roughly forty-eight degrees of latitude there are nights in summer when the sun \
    never falls far enough below the horizon for the Fajr or Isha angle to be reached at \
    all. The three high-latitude rules divide the night instead of solving for an angle. \
    Where even that is impossible — where the sun does not rise or does not set — this app \
    shows a dash and says so. It will not invent a time.
    """

    static let authority = """
    Whatever this app computes, the timetable of your local mosque is the one to follow. \
    Mosques take account of things a formula cannot: the practice of the community, a \
    minute of caution added by the imam, the moment the muezzin actually calls. Use the \
    per-prayer adjustments in Settings to line this app up with them, and where the two \
    still disagree, follow the mosque.
    """

    static let noNotifications = """
    This app does not send notifications of any kind. It has no adhan, no alarm and no \
    reminder, and it never asks for permission to send one. It is a record of what you have \
    prayed, kept by you, and nothing more.
    """

    static let privacy = """
    Everything you record stays in this app's own storage on this device. There is no \
    account, no sign-in, no analytics and no location permission — the city list is there \
    precisely so that nothing about your position has to be read.
    """
}
