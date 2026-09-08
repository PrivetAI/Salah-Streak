import SwiftUI

struct SLGuideTab: View {
    @EnvironmentObject private var store: SLStore
    @State private var route: SLGuideRoute? = nil

    var body: some View {
        ZStack {
            content
            if let route = route {
                Group {
                    switch route {
                    case .prayer(let prayer):
                        SLPrayerReferenceScreen(prayer: prayer, onBack: close)
                    case .sequence:
                        SLSequenceScreen(onBack: close)
                    case .passages:
                        SLPassagesScreen(onBack: close)
                    case .milestones:
                        SLMilestonesScreen(onBack: close)
                    case .about:
                        SLAboutScreen(onBack: close)
                    }
                }
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { route = nil }
    }

    private func open(_ target: SLGuideRoute) {
        withAnimation(.easeOut(duration: 0.2)) { route = target }
    }

    private var content: some View {
        let stats = store.statistics()
        let unlocked = SLMilestoneLibrary.unlockedCount(stats: stats, qadaPaid: store.qadaTotalPaid)

        return VStack(spacing: 0) {
            SLHeader(title: "Guide",
                     subtitle: "Reference, the shape of the prayer, and the passages")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    SLSectionTitle(text: "The five prayers", trailing: "rak'ah counts and windows")
                    SLRowGroup {
                        ForEach(SLPrayer.allCases) { prayer in
                            SLNavRow(title: prayer.name,
                                     value: "\(SLPrayerGuide.reference(for: prayer).fardRakah) fard",
                                     detail: prayer.windowSummary,
                                     action: { open(.prayer(prayer)) })
                            if prayer != SLPrayer.allCases.last { SLDivider() }
                        }
                    }

                    SLSectionTitle(text: "Learning and reference")
                    SLRowGroup {
                        SLNavRow(title: "How the prayer is performed",
                                 value: "\(SLPrayerSequence.steps.count) steps",
                                 detail: "Every position in order, what the body does and what is said.",
                                 action: { open(.sequence) })
                        SLDivider()
                        SLNavRow(title: "Passages on prayer",
                                 value: "\(SLPassageLibrary.count)",
                                 detail: "From the Qur'an, in Pickthall's 1930 English rendering.",
                                 action: { open(.passages) })
                        SLDivider()
                        SLNavRow(title: "Milestones",
                                 value: "\(unlocked) of \(SLMilestoneLibrary.count)",
                                 detail: "Named marks that unlock as your record grows.",
                                 action: { open(.milestones) })
                        SLDivider()
                        SLNavRow(title: "About the calculations",
                                 value: store.settings.method.name,
                                 detail: "Which method, which angles, and why the mosque comes first.",
                                 action: { open(.about) })
                    }

                    SLCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Friday")
                                .font(SLType.title(16))
                                .foregroundColor(SLTheme.ink)
                            Text(SLPrayerGuide.jumuahNote)
                                .font(SLType.body(13.5))
                                .foregroundColor(SLTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SLCard(fill: SLTheme.surfaceAlt) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What this app is not")
                                .font(SLType.title(16))
                                .foregroundColor(SLTheme.ink)
                            Text(SLAboutText.noNotifications)
                                .font(SLType.body(13.5))
                                .foregroundColor(SLTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: SLMetric.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(SLTheme.canvas.ignoresSafeArea())
    }
}

enum SLGuideRoute: Identifiable {
    case prayer(SLPrayer)
    case sequence
    case passages
    case milestones
    case about

    var id: Int {
        switch self {
        case .prayer(let p): return 100 + p.rawValue
        case .sequence: return 1
        case .passages: return 2
        case .milestones: return 3
        case .about: return 4
        }
    }
}

// MARK: - One prayer's reference page

struct SLPrayerReferenceScreen: View {
    @EnvironmentObject private var store: SLStore
    let prayer: SLPrayer
    let onBack: () -> Void

    var body: some View {
        let reference = SLPrayerGuide.reference(for: prayer)

        return SLDetailScreen(title: prayer.name,
                              subtitle: prayer.transliteration,
                              onBack: onBack) {

            HStack(spacing: 16) {
                prayer.glyph(size: 44, color: SLTheme.teal, weight: 2.0)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(reference.fardRakah) rak'ah fard")
                        .font(SLType.title(19))
                        .foregroundColor(SLTheme.ink)
                    Text("Obligatory. This number is agreed by every school.")
                        .font(SLType.caption(11.5))
                        .foregroundColor(SLTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(SLTheme.hairline, lineWidth: 1)
            )

            SLSectionTitle(text: "The window")
            SLCard {
                Text(reference.window)
                    .font(SLType.body(14))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SLSectionTitle(text: "Rak'ah alongside the fard")
            SLRowGroup {
                referenceRow("Before the fard", reference.sunnahBefore)
                SLDivider()
                referenceRow("After the fard", reference.sunnahAfter)
                SLDivider()
                referenceRow("Further voluntary", reference.voluntary)
            }

            SLSectionTitle(text: "What sets it apart")
            SLCard {
                Text(reference.distinct)
                    .font(SLType.body(14))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SLCard(fill: SLTheme.gold.opacity(0.16)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Worth knowing")
                        .font(SLType.label(11))
                        .tracking(1.2)
                        .foregroundColor(SLTheme.goldDeep)
                    Text(reference.caveat)
                        .font(SLType.body(13.5))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SLEmptyNote(title: "Counts differ between schools",
                        message: "The obligatory rak'ah are agreed. The voluntary rak'ah around them are not counted identically by every school, and this page follows the most widely taught arrangement rather than ruling between them.")
        }
    }

    @ViewBuilder
    private func referenceRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(SLType.bodyMedium(14))
                .foregroundColor(SLTheme.ink)
            Spacer(minLength: 8)
            Text(value)
                .font(SLType.body(13.5))
                .foregroundColor(SLTheme.inkSoft)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - The sequence

struct SLSequenceScreen: View {
    let onBack: () -> Void

    var body: some View {
        SLDetailScreen(title: "How the prayer is performed",
                       subtitle: "One rak'ah, in order",
                       onBack: onBack) {

            SLCard {
                Text(SLPrayerSequence.intro)
                    .font(SLType.body(14))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(SLPrayerSequence.steps) { step in
                stepCard(step)
            }

            SLCard(fill: SLTheme.surfaceAlt) {
                Text(SLPrayerSequence.closing)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func stepCard(_ step: SLPostureStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                SLPostureFigure(posture: step.posture)
                    .frame(width: 92, height: 92)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(SLTheme.canvasDeep)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(step.id + 1)".uppercased())
                        .font(SLType.label(10))
                        .tracking(1.3)
                        .foregroundColor(SLTheme.inkFaint)
                    Text(step.title)
                        .font(SLType.title(17))
                        .foregroundColor(SLTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(step.transliteration)
                        .font(SLType.bodyMedium(13))
                        .foregroundColor(SLTheme.teal)
                }
                Spacer(minLength: 0)
            }

            Text(step.description)
                .font(SLType.body(13.5))
                .foregroundColor(SLTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Said at this point".uppercased())
                    .font(SLType.label(9.5))
                    .tracking(1.2)
                    .foregroundColor(SLTheme.inkFaint)
                Text(step.saying)
                    .font(SLType.quote(15))
                    .foregroundColor(SLTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.meaning)
                    .font(SLType.caption(12))
                    .foregroundColor(SLTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SLTheme.tealWash.opacity(0.6))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .fill(SLTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .stroke(SLTheme.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Passages

struct SLPassagesScreen: View {
    let onBack: () -> Void

    var body: some View {
        SLDetailScreen(title: "Passages on prayer",
                       subtitle: "\(SLPassageLibrary.count) passages from the Qur'an",
                       onBack: onBack) {

            SLCard(fill: SLTheme.surfaceAlt) {
                Text(SLPassageLibrary.attribution)
                    .font(SLType.body(13))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(SLPassageTheme.allCases) { theme in
                let items = SLPassageLibrary.passages(theme: theme)
                if !items.isEmpty {
                    SLSectionTitle(text: theme.title, trailing: "\(items.count)")
                    VStack(spacing: 10) {
                        ForEach(items) { passage in
                            passageCard(passage)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func passageCard(_ passage: SLPassage) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(passage.text)
                .font(SLType.quote(15.5))
                .foregroundColor(SLTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                SLOrnamentRule(width: 40)
                Text(passage.citation)
                    .font(SLType.label(11))
                    .foregroundColor(SLTheme.teal)
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .fill(SLTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .stroke(SLTheme.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Milestones

struct SLMilestonesScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        let stats = store.statistics()
        let paid = store.qadaTotalPaid
        let unlocked = SLMilestoneLibrary.unlockedCount(stats: stats, qadaPaid: paid)

        return SLDetailScreen(title: "Milestones",
                              subtitle: "\(unlocked) of \(SLMilestoneLibrary.count) unlocked",
                              onBack: onBack) {

            SLCard {
                VStack(alignment: .leading, spacing: 8) {
                    SLProgressBar(value: SLMilestoneLibrary.count > 0
                                    ? Double(unlocked) / Double(SLMilestoneLibrary.count) : 0,
                                  height: 9)
                    Text("Each milestone is a plain count with a target. Nothing here is hidden and nothing expires: a milestone once reached stays reached, and the bar under a locked one shows exactly how far along you are.")
                        .font(SLType.body(13))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ForEach(SLMilestoneLibrary.grouped(), id: \.group.id) { section in
                SLSectionTitle(text: section.group.title, trailing: "\(section.items.count)")
                VStack(spacing: 8) {
                    ForEach(section.items) { milestone in
                        milestoneRow(milestone, stats: stats, paid: paid)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func milestoneRow(_ milestone: SLMilestone, stats: SLStatistics, paid: Int) -> some View {
        let progress = milestone.progress(stats: stats, qadaPaid: paid)
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(progress.unlocked ? SLTheme.teal : SLTheme.canvasDeep)
                    .frame(width: 30, height: 30)
                if progress.unlocked {
                    SLCheckMark()
                        .stroke(SLTheme.surface,
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 18, height: 18)
                } else {
                    Text("\(progress.target)")
                        .font(SLType.label(11))
                        .foregroundColor(SLTheme.inkFaint)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(milestone.title)
                    .font(SLType.bodyMedium(14.5))
                    .foregroundColor(progress.unlocked ? SLTheme.ink : SLTheme.inkSoft)
                Text(milestone.line)
                    .font(SLType.caption(11.5))
                    .foregroundColor(SLTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                if !progress.unlocked {
                    SLProgressBar(value: progress.target > 0
                                    ? Double(progress.current) / Double(progress.target) : 0,
                                  height: 5,
                                  tint: SLTheme.gold)
                    Text("\(progress.current) of \(progress.target)")
                        .font(SLType.caption(10))
                        .foregroundColor(SLTheme.inkFaint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(progress.unlocked ? SLTheme.surface : SLTheme.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(progress.unlocked ? SLTheme.teal.opacity(0.35) : SLTheme.hairline, lineWidth: 1)
        )
    }
}

// MARK: - About the calculations

struct SLAboutScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        let method = store.settings.method
        let city = store.city

        return SLDetailScreen(title: "About the calculations",
                              subtitle: "What the numbers are, and what they are not",
                              onBack: onBack) {

            SLCalculationNote()

            SLSectionTitle(text: "Your current setup")
            SLRowGroup {
                aboutRow("Method", method.name, method.angleLine)
                SLDivider()
                aboutRow("Asr", store.settings.asrSchool.title, store.settings.asrSchool.subtitle)
                SLDivider()
                aboutRow("High latitude", store.settings.highLatRule.title, store.settings.highLatRule.shortTitle)
                SLDivider()
                aboutRow("City", city.displayName, "\(city.coordinateLine)  ·  \(city.timeZoneID)")
            }

            section("How it works", SLAboutText.howItWorks)
            section("Why Fajr and Isha need a choice", SLAboutText.theAngles)
            section("Far north and far south", SLAboutText.highLatitude)
            section("The mosque comes first", SLAboutText.authority)
            section("No reminders", SLAboutText.noNotifications)
            section("Your records", SLAboutText.privacy)

            SLSectionTitle(text: "The six methods")
            VStack(spacing: 8) {
                ForEach(SLMethodCatalogue.all) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(entry.name)
                                .font(SLType.bodyMedium(14))
                                .foregroundColor(SLTheme.ink)
                            Spacer(minLength: 6)
                            Text(entry.angleLine)
                                .font(SLType.caption(11))
                                .foregroundColor(SLTheme.teal)
                        }
                        Text(entry.summary)
                            .font(SLType.caption(11.5))
                            .foregroundColor(SLTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(entry.id == method.id ? SLTheme.tealWash : SLTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(SLTheme.hairline, lineWidth: 1)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ body: String) -> some View {
        SLCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(SLType.title(16))
                    .foregroundColor(SLTheme.ink)
                Text(body)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func aboutRow(_ title: String, _ value: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(SLType.bodyMedium(14))
                    .foregroundColor(SLTheme.ink)
                Spacer(minLength: 8)
                Text(value)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.teal)
                    .multilineTextAlignment(.trailing)
            }
            Text(detail)
                .font(SLType.caption(11))
                .foregroundColor(SLTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
