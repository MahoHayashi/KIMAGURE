import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class FortuneViewModel {
    private let modelContext: ModelContext

    var sessions: [FortuneSession] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    var todaySession: FortuneSession? {
        let key = LocalDay.key(for: .now)
        return sessions.first { $0.localDateKey == key }
    }

    func refresh() {
        let descriptor = FetchDescriptor<FortuneSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            sessions = try modelContext.fetch(descriptor)
            if backfillEnglishContent() {
                try modelContext.save()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func drawToday() -> FortuneSession? {
        if let todaySession {
            return todaySession
        }

        do {
            let draft = try FortuneGenerator.generate()
            let missions = draft.missions.enumerated().map { index, template in
                DailyMission(
                    sourceTemplateID: template.id,
                    text: template.text,
                    englishText: template.englishText,
                    difficulty: template.difficulty,
                    cardOrder: index + 3
                )
            }

            var cards = [
                FortuneCard(
                    order: 1,
                    kind: .cover,
                    title: "今日の運勢",
                    englishTitle: "DAILY FORTUNE",
                    body: draft.title.japanese,
                    englishBody: draft.title.english
                ),
                FortuneCard(
                    order: 2,
                    kind: .message,
                    title: "あなたに必要な言葉",
                    englishTitle: "WORDS FOR YOU",
                    body: draft.message.japanese,
                    englishBody: draft.message.english
                )
            ]
            cards.append(contentsOf: missions.map {
                FortuneCard(
                    order: $0.cardOrder,
                    kind: .mission,
                    title: $0.difficulty.japaneseLabel,
                    englishTitle: $0.difficulty.label,
                    body: $0.text,
                    englishBody: $0.englishText,
                    missionID: $0.id
                )
            })
            cards.append(FortuneCard(
                order: 8,
                kind: .prediction,
                title: "未来予知",
                englishTitle: "A GLIMPSE AHEAD",
                body: draft.prediction.japanese,
                englishBody: draft.prediction.english
            ))
            cards.append(FortuneCard(
                order: 9,
                kind: .closing,
                title: "今日の結び",
                englishTitle: "FINAL WORDS",
                body: draft.closing.japanese,
                englishBody: draft.closing.english
            ))

            let session = FortuneSession(
                localDateKey: LocalDay.key(for: .now),
                title: draft.title.japanese,
                englishTitle: draft.title.english,
                cards: cards,
                missions: missions
            )
            modelContext.insert(session)
            try modelContext.save()
            refresh()
            return sessions.first { $0.id == session.id } ?? session
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func toggle(_ mission: DailyMission, in session: FortuneSession) {
        guard LocalDay.isToday(session) else { return }
        mission.isCompleted.toggle()
        mission.completedAt = mission.isCompleted ? .now : nil
        save()
    }

    func mission(for card: FortuneCard, in session: FortuneSession) -> DailyMission? {
        guard let missionID = card.missionID else { return nil }
        return session.missions.first { $0.id == missionID }
    }

    private func save() {
        do {
            try modelContext.save()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func backfillEnglishContent() -> Bool {
        var changed = false
        for session in sessions {
            if session.englishTitle.isEmpty,
               let translation = FortuneGenerator.englishTranslation(for: session.title) {
                session.englishTitle = translation
                changed = true
            }
            for mission in session.missions where mission.englishText.isEmpty {
                mission.englishText = FortuneGenerator.englishTranslation(for: mission.text) ?? "Translation unavailable."
                changed = true
            }
            for card in session.cards {
                if card.englishTitle.isEmpty {
                    card.englishTitle = englishTitle(for: card, in: session)
                    changed = true
                }
                if card.englishBody.isEmpty {
                    card.englishBody = FortuneGenerator.englishTranslation(for: card.body) ?? "Translation unavailable."
                    changed = true
                }
            }
        }
        return changed
    }

    private func englishTitle(for card: FortuneCard, in session: FortuneSession) -> String {
        switch card.kind {
        case .cover: "DAILY FORTUNE"
        case .message: "WORDS FOR YOU"
        case .mission:
            mission(for: card, in: session)?.difficulty.label ?? "MISSION"
        case .prediction: "A GLIMPSE AHEAD"
        case .closing: "FINAL WORDS"
        }
    }
}
