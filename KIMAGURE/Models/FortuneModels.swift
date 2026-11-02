import Foundation
import SwiftData

enum CardKind: String, Codable, CaseIterable {
    case cover
    case message
    case mission
    case prediction
    case closing
}

enum MissionDifficulty: String, Codable {
    case easy
    case adventure

    var label: String {
        switch self {
        case .easy: "EASY"
        case .adventure: "ADVENTURE"
        }
    }
}

@Model
final class FortuneSession {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var localDateKey: String
    var createdAt: Date
    var title: String
    @Relationship(deleteRule: .cascade) var cards: [FortuneCard]
    @Relationship(deleteRule: .cascade) var missions: [DailyMission]

    init(
        id: UUID = UUID(),
        localDateKey: String,
        createdAt: Date = .now,
        title: String,
        cards: [FortuneCard],
        missions: [DailyMission]
    ) {
        self.id = id
        self.localDateKey = localDateKey
        self.createdAt = createdAt
        self.title = title
        self.cards = cards
        self.missions = missions
    }

    var orderedCards: [FortuneCard] {
        cards.sorted { $0.order < $1.order }
    }

    var orderedMissions: [DailyMission] {
        missions.sorted { $0.cardOrder < $1.cardOrder }
    }

    var completedCount: Int {
        missions.filter(\.isCompleted).count
    }

    var isAllCompleted: Bool {
        !missions.isEmpty && completedCount == missions.count
    }
}

@Model
final class FortuneCard {
    @Attribute(.unique) var id: UUID
    var order: Int
    var kindRawValue: String
    var title: String
    var body: String
    var missionID: UUID?

    init(
        id: UUID = UUID(),
        order: Int,
        kind: CardKind,
        title: String,
        body: String,
        missionID: UUID? = nil
    ) {
        self.id = id
        self.order = order
        self.kindRawValue = kind.rawValue
        self.title = title
        self.body = body
        self.missionID = missionID
    }

    var kind: CardKind {
        CardKind(rawValue: kindRawValue) ?? .message
    }
}

@Model
final class DailyMission {
    @Attribute(.unique) var id: UUID
    var sourceTemplateID: String
    var text: String
    var difficultyRawValue: String
    var cardOrder: Int
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        sourceTemplateID: String,
        text: String,
        difficulty: MissionDifficulty,
        cardOrder: Int,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.sourceTemplateID = sourceTemplateID
        self.text = text
        self.difficultyRawValue = difficulty.rawValue
        self.cardOrder = cardOrder
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    var difficulty: MissionDifficulty {
        MissionDifficulty(rawValue: difficultyRawValue) ?? .easy
    }
}
