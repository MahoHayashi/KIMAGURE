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
                    difficulty: template.difficulty,
                    cardOrder: index + 3
                )
            }

            var cards = [
                FortuneCard(order: 1, kind: .cover, title: "DAILY FORTUNE", body: draft.title),
                FortuneCard(order: 2, kind: .message, title: "あなたに必要な言葉", body: draft.message)
            ]
            cards.append(contentsOf: missions.map {
                FortuneCard(
                    order: $0.cardOrder,
                    kind: .mission,
                    title: $0.difficulty.label,
                    body: $0.text,
                    missionID: $0.id
                )
            })
            cards.append(FortuneCard(order: 8, kind: .prediction, title: "未来予知", body: draft.prediction))
            cards.append(FortuneCard(order: 9, kind: .closing, title: "今日の結び", body: draft.closing))

            let session = FortuneSession(
                localDateKey: LocalDay.key(for: .now),
                title: draft.title,
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
}
