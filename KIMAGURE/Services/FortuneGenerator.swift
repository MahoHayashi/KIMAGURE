import Foundation

struct BilingualCopy: Sendable {
    let japanese: String
    let english: String
}

struct MissionTemplate: Sendable {
    let id: String
    let text: String
    let englishText: String
    let difficulty: MissionDifficulty
}

struct FortuneDraft {
    let title: BilingualCopy
    let message: BilingualCopy
    let prediction: BilingualCopy
    let closing: BilingualCopy
    let missions: [MissionTemplate]
}

enum FortuneGenerationError: LocalizedError {
    case insufficientCandidates

    var errorDescription: String? { "占い候補が不足しています。" }
}

enum FortuneGenerator {
    static let titles = [
        BilingualCopy(japanese: "今日は、偶然が味方する日。", english: "Today, chance is on your side."),
        BilingualCopy(japanese: "小さな冒険が、景色を変える日。", english: "A small adventure will change the view today."),
        BilingualCopy(japanese: "直感の声に、耳を澄ませる日。", english: "Today is a day to listen to your intuition."),
        BilingualCopy(japanese: "いつもと違う一歩を選ぶ日。", english: "Choose a different step today.")
    ]

    static let messages = [
        BilingualCopy(japanese: "いつもと違う選択が、思いがけない幸せを連れてくる。", english: "An unusual choice may bring unexpected happiness."),
        BilingualCopy(japanese: "迷ったときは、少し心が弾む方へ。", english: "When in doubt, follow what makes your heart lift."),
        BilingualCopy(japanese: "完璧でなくても、始めたことが今日の答えになる。", english: "It does not need to be perfect. Beginning is today's answer."),
        BilingualCopy(japanese: "あなたが気づいた小さな光を、大切に。", english: "Treasure the small light you notice today.")
    ]

    static let predictions = [
        BilingualCopy(japanese: "今日、あなたは思いがけない発見をするかもしれません。", english: "You may make an unexpected discovery today."),
        BilingualCopy(japanese: "何気ない会話の中に、次のヒントが隠れていそうです。", english: "Your next clue may be hidden in a casual conversation."),
        BilingualCopy(japanese: "いつもの道で、少し嬉しい偶然に出会えるかもしれません。", english: "A pleasant coincidence may meet you along a familiar path."),
        BilingualCopy(japanese: "夕方ごろ、今日を好きになる理由がひとつ増えそうです。", english: "By evening, you may find one more reason to love today.")
    ]

    static let closings = [
        BilingualCopy(japanese: "今日の偶然が、明日のあなたをつくる。", english: "Today's coincidences shape who you become tomorrow."),
        BilingualCopy(japanese: "小さな一歩も、今日だけの物語。", english: "Even a small step belongs to today's unique story."),
        BilingualCopy(japanese: "結果より、心が動いた瞬間を覚えていて。", english: "Remember the moment your heart moved, not only the result."),
        BilingualCopy(japanese: "今日という日を、あなたらしく楽しんで。", english: "Enjoy this day in your own way.")
    ]

    static let easyMissions = [
        BilingualCopy(japanese: "今日の空を写真に残す", english: "Take a photo of today's sky."),
        BilingualCopy(japanese: "いつもと違う音楽を聴く", english: "Listen to music you do not usually choose."),
        BilingualCopy(japanese: "誰かに「ありがとう」を伝える", english: "Say thank you to someone."),
        BilingualCopy(japanese: "普段選ばない色を取り入れる", english: "Add a color you do not usually choose."),
        BilingualCopy(japanese: "今日見つけた小さな幸せを記録する", english: "Write down a small happiness you find today."),
        BilingualCopy(japanese: "いつもより5分だけ遠回りする", english: "Take a five-minute detour."),
        BilingualCopy(japanese: "気になっていたことを1つ調べる", english: "Look up one thing you have been curious about."),
        BilingualCopy(japanese: "今日の自分を褒める言葉を考える", english: "Think of a kind word for yourself today."),
        BilingualCopy(japanese: "直感で何かを1つ選ぶ", english: "Choose one thing by intuition."),
        BilingualCopy(japanese: "今日初めて知ったことを記録する", english: "Record something new you learn today.")
    ]

    static let adventureMissions = [
        BilingualCopy(japanese: "行ったことのないお店に入る", english: "Visit a shop you have never entered."),
        BilingualCopy(japanese: "普段注文しないものを選ぶ", english: "Order something you would not normally choose."),
        BilingualCopy(japanese: "気になっていた人に連絡する", english: "Reach out to someone you have been thinking about."),
        BilingualCopy(japanese: "初めての場所に足を運ぶ", english: "Go somewhere you have never been."),
        BilingualCopy(japanese: "新しい趣味を1つ体験する", english: "Try one new hobby."),
        BilingualCopy(japanese: "安全な範囲でいつもと違う交通手段を使う", english: "Safely try a different way of getting around."),
        BilingualCopy(japanese: "誰かを自分から誘ってみる", english: "Invite someone to do something together."),
        BilingualCopy(japanese: "今まで避けていた小さなことに挑戦する", english: "Try one small thing you have been avoiding."),
        BilingualCopy(japanese: "知らないジャンルの作品に触れる", english: "Explore a work from an unfamiliar genre."),
        BilingualCopy(japanese: "ずっと後回しにしていたことを始める", english: "Begin something you have kept putting off.")
    ]

    static func generate() throws -> FortuneDraft {
        guard easyMissions.count >= 3, adventureMissions.count >= 2 else {
            throw FortuneGenerationError.insufficientCandidates
        }

        let easy = easyMissions.shuffled().prefix(3).map { copy in
            MissionTemplate(
                id: "easy-\(easyMissions.firstIndex { $0.japanese == copy.japanese } ?? 0)",
                text: copy.japanese,
                englishText: copy.english,
                difficulty: .easy
            )
        }
        let adventure = adventureMissions.shuffled().prefix(2).map { copy in
            MissionTemplate(
                id: "adventure-\(adventureMissions.firstIndex { $0.japanese == copy.japanese } ?? 0)",
                text: copy.japanese,
                englishText: copy.english,
                difficulty: .adventure
            )
        }

        return FortuneDraft(
            title: titles.randomElement() ?? titles[0],
            message: messages.randomElement() ?? messages[0],
            prediction: predictions.randomElement() ?? predictions[0],
            closing: closings.randomElement() ?? closings[0],
            missions: Array(easy + adventure).shuffled()
        )
    }

    static func englishTranslation(for japanese: String) -> String? {
        allCopies.first { $0.japanese == japanese }?.english
    }

    private static var allCopies: [BilingualCopy] {
        titles + messages + predictions + closings + easyMissions + adventureMissions
    }
}

enum LocalDay {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func isToday(_ session: FortuneSession, now: Date = .now, calendar: Calendar = .current) -> Bool {
        session.localDateKey == key(for: now, calendar: calendar)
    }
}
