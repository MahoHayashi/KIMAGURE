import Foundation

struct MissionTemplate: Sendable {
    let id: String
    let text: String
    let difficulty: MissionDifficulty
}

struct FortuneDraft {
    let title: String
    let message: String
    let prediction: String
    let closing: String
    let missions: [MissionTemplate]
}

enum FortuneGenerationError: LocalizedError {
    case insufficientCandidates

    var errorDescription: String? {
        "占い候補が不足しています。"
    }
}

enum FortuneGenerator {
    static let titles = [
        "今日は、偶然が味方する日。",
        "小さな冒険が、景色を変える日。",
        "直感の声に、耳を澄ませる日。",
        "いつもと違う一歩を選ぶ日。"
    ]

    static let messages = [
        "いつもと違う選択が、思いがけない幸せを連れてくる。",
        "迷ったときは、少し心が弾む方へ。",
        "完璧でなくても、始めたことが今日の答えになる。",
        "あなたが気づいた小さな光を、大切に。"
    ]

    static let predictions = [
        "今日、あなたは思いがけない発見をするかもしれません。",
        "何気ない会話の中に、次のヒントが隠れていそうです。",
        "いつもの道で、少し嬉しい偶然に出会えるかもしれません。",
        "夕方ごろ、今日を好きになる理由がひとつ増えそうです。"
    ]

    static let closings = [
        "今日の偶然が、明日のあなたをつくる。",
        "小さな一歩も、今日だけの物語。",
        "結果より、心が動いた瞬間を覚えていて。",
        "今日という日を、あなたらしく楽しんで。"
    ]

    static let easyMissions = [
        "今日の空を写真に残す",
        "いつもと違う音楽を聴く",
        "誰かに「ありがとう」を伝える",
        "普段選ばない色を取り入れる",
        "今日見つけた小さな幸せを記録する",
        "いつもより5分だけ遠回りする",
        "気になっていたことを1つ調べる",
        "今日の自分を褒める言葉を考える",
        "直感で何かを1つ選ぶ",
        "今日初めて知ったことを記録する"
    ]

    static let adventureMissions = [
        "行ったことのないお店に入る",
        "普段注文しないものを選ぶ",
        "気になっていた人に連絡する",
        "初めての場所に足を運ぶ",
        "新しい趣味を1つ体験する",
        "安全な範囲でいつもと違う交通手段を使う",
        "誰かを自分から誘ってみる",
        "今まで避けていた小さなことに挑戦する",
        "知らないジャンルの作品に触れる",
        "ずっと後回しにしていたことを始める"
    ]

    static func generate() throws -> FortuneDraft {
        guard easyMissions.count >= 3, adventureMissions.count >= 2 else {
            throw FortuneGenerationError.insufficientCandidates
        }

        let easy = easyMissions.shuffled().prefix(3).map {
            MissionTemplate(id: "easy-\(easyMissions.firstIndex(of: $0) ?? 0)", text: $0, difficulty: .easy)
        }
        let adventure = adventureMissions.shuffled().prefix(2).map {
            MissionTemplate(id: "adventure-\(adventureMissions.firstIndex(of: $0) ?? 0)", text: $0, difficulty: .adventure)
        }

        return FortuneDraft(
            title: titles.randomElement() ?? titles[0],
            message: messages.randomElement() ?? messages[0],
            prediction: predictions.randomElement() ?? predictions[0],
            closing: closings.randomElement() ?? closings[0],
            missions: Array(easy + adventure).shuffled()
        )
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
