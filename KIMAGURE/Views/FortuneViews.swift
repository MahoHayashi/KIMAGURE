import SwiftUI

private enum FortuneStyle {
    static let background = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let card = Color(red: 0.99, green: 0.985, blue: 0.96)
    static let ink = Color(red: 0.12, green: 0.12, blue: 0.11)
}

struct FortuneRootView: View {
    @Bindable var viewModel: FortuneViewModel

    var body: some View {
        TabView {
            NavigationStack { HomeView(viewModel: viewModel) }
                .tabItem { Label("今日", systemImage: "sparkles") }
            NavigationStack { HistoryView(viewModel: viewModel) }
                .tabItem { Label("記録", systemImage: "books.vertical") }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーが発生しました。")
        }
    }
}

struct HomeView: View {
    @Bindable var viewModel: FortuneViewModel
    @State private var deckSession: FortuneSession?
    @State private var resultSession: FortuneSession?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("DAILY FORTUNE")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .tracking(4)
                    Text("今日という日を、\n運命に任せてみる。")
                        .font(.system(size: 28, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                }

                CardStackIllustration(hasResult: viewModel.todaySession != nil)
                    .frame(height: 320)

                if let today = viewModel.todaySession {
                    VStack(spacing: 12) {
                        Text(today.title)
                            .font(.system(.title3, design: .serif))
                            .multilineTextAlignment(.center)
                        Button("今日のカードを見る") { resultSession = today }
                            .buttonStyle(FortunePrimaryButtonStyle())
                        Button("9枚のカードを読み返す") { deckSession = today }
                            .font(.system(.subheadline, design: .serif))
                            .underline()
                    }
                } else {
                    Button("今日のカードを引く") { deckSession = viewModel.drawToday() }
                        .buttonStyle(FortunePrimaryButtonStyle())
                }

                Text("カードを引けるのは、1日1回だけ。")
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(FortuneStyle.background.ignoresSafeArea())
        .fullScreenCover(item: $deckSession) { session in
            CardDeckView(session: session, viewModel: viewModel) {
                deckSession = nil
                resultSession = session
            }
        }
        .sheet(item: $resultSession) { session in
            NavigationStack { MissionSummaryView(session: session, viewModel: viewModel) }
        }
    }
}

private struct CardStackIllustration: View {
    let hasResult: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(FortuneStyle.card)
                    .stroke(FortuneStyle.ink.opacity(0.7), lineWidth: 0.8)
                    .frame(width: 210, height: 285)
                    .rotationEffect(.degrees(Double(index - 1) * 3))
                    .offset(x: CGFloat(index - 1) * 5, y: CGFloat(index) * -2)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 5)
            }
            VStack(spacing: 16) {
                Image(systemName: hasResult ? "moon.stars" : "sparkle")
                    .font(.system(size: 30, weight: .light))
                Text(hasResult ? "TODAY'S FORTUNE" : "THE CARD AWAITS")
                    .font(.system(.caption, design: .serif))
                    .tracking(2)
            }
        }
        .accessibilityHidden(true)
    }
}

struct CardDeckView: View {
    let session: FortuneSession
    @Bindable var viewModel: FortuneViewModel
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero

    private var cards: [FortuneCard] { session.orderedCards }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.system(.caption, design: .serif))
                    .monospacedDigit()
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }

            ZStack {
                ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                    if index >= currentIndex && index <= currentIndex + 2 {
                        FortuneCardView(
                            card: card,
                            dateKey: session.localDateKey,
                            mission: viewModel.mission(for: card, in: session)
                        )
                        .scaleEffect(index == currentIndex ? 1 : 0.96 - CGFloat(index - currentIndex - 1) * 0.02)
                        .offset(
                            x: index == currentIndex ? dragOffset.width : 0,
                            y: index == currentIndex ? dragOffset.height * 0.08 : CGFloat(index - currentIndex) * 9
                        )
                        .rotationEffect(.degrees(index == currentIndex ? Double(dragOffset.width / 24) : 0))
                        .zIndex(Double(cards.count - index))
                        .gesture(index == currentIndex ? dragGesture : nil)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            if currentIndex == cards.count - 1 {
                Button("今日のミッションを見る", action: onFinish)
                    .buttonStyle(FortunePrimaryButtonStyle())
            } else {
                HStack(spacing: 20) {
                    Button("前へ") { moveBack() }.disabled(currentIndex == 0)
                    Button("次へ") { moveForward() }
                }
                .font(.system(.body, design: .serif))
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(FortuneStyle.background.ignoresSafeArea())
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                if value.translation.width < -80 { moveForward() }
                else if value.translation.width > 80 { moveBack() }
                else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func moveForward() {
        guard currentIndex < cards.count - 1 else { return }
        let update = { currentIndex += 1; dragOffset = .zero }
        if reduceMotion { update() } else { withAnimation(.easeOut(duration: 0.24), update) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func moveBack() {
        guard currentIndex > 0 else { return }
        let update = { currentIndex -= 1; dragOffset = .zero }
        if reduceMotion { update() } else { withAnimation(.easeOut(duration: 0.2), update) }
    }
}

private struct FortuneCardView: View {
    let card: FortuneCard
    let dateKey: String
    let mission: DailyMission?

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 24) {
                Text(card.title.uppercased())
                    .font(.system(.caption, design: .serif, weight: .semibold))
                    .tracking(2.5)
                Spacer()
                if card.kind == .cover {
                    Text(formattedDate).font(.system(.subheadline, design: .serif))
                }
                Text(card.body)
                    .font(.system(size: card.kind == .cover ? 27 : 24, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineSpacing(9)
                    .minimumScaleFactor(0.72)
                if let mission {
                    Text(mission.difficulty.label)
                        .font(.system(.caption2, design: .serif))
                        .tracking(2)
                        .padding(.top, 8)
                }
                Spacer()
                Text(String(format: "%02d", card.order))
                    .font(.system(.caption2, design: .serif))
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 34)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(alignment: .bottomTrailing) {
                if mission?.isCompleted == true { CompletedStamp().padding(24) }
            }
        }
        .frame(maxWidth: 430, maxHeight: 620)
        .background(FortuneStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(FortuneStyle.ink.opacity(0.75), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.order)枚目、\(card.title)、\(card.body)")
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else { return dateKey }
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

struct MissionSummaryView: View {
    let session: FortuneSession
    @Bindable var viewModel: FortuneViewModel
    @State private var showDeck = false

    private var isEditable: Bool { LocalDay.isToday(session) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.localDateKey)
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                    Text(session.title).font(.system(.title2, design: .serif))
                    Text("\(session.completedCount) / 5 COMPLETED")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .tracking(1)
                }

                if session.isAllCompleted {
                    VStack(spacing: 8) {
                        Text("ALL COMPLETED")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .tracking(2)
                        Text("今日の小さな冒険を、すべて集めました。")
                            .font(.system(.subheadline, design: .serif))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(22)
                    .overlay(Rectangle().stroke(FortuneStyle.ink, lineWidth: 1))
                }

                VStack(spacing: 12) {
                    ForEach(session.orderedMissions) { mission in
                        MissionRow(mission: mission, isEditable: isEditable) {
                            viewModel.toggle(mission, in: session)
                        }
                    }
                }

                Button("9枚のカードを読み返す") { showDeck = true }
                    .buttonStyle(FortunePrimaryButtonStyle())

                if !isEditable {
                    Text("過去のミッションは閲覧のみです。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(FortuneStyle.background.ignoresSafeArea())
        .navigationTitle("今日のミッション")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showDeck) {
            CardDeckView(session: session, viewModel: viewModel) { showDeck = false }
        }
    }
}

private struct MissionRow: View {
    let mission: DailyMission
    let isEditable: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 7) {
                    Text(mission.difficulty.label)
                        .font(.system(.caption2, design: .serif, weight: .semibold))
                        .tracking(1.5)
                    Text(mission.text)
                        .font(.system(.body, design: .serif))
                        .multilineTextAlignment(.leading)
                    if mission.isCompleted { CompletedStamp().padding(.top, 5) }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(FortuneStyle.ink)
            .padding(18)
            .background(FortuneStyle.card)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(FortuneStyle.ink.opacity(0.3), lineWidth: 0.7))
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityHint(isEditable ? "ダブルタップで達成状態を切り替えます" : "過去の記録です")
    }
}

private struct CompletedStamp: View {
    var body: some View {
        Text("COMPLETED")
            .font(.system(.caption2, design: .serif, weight: .bold))
            .tracking(1.5)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .overlay(Rectangle().stroke(FortuneStyle.ink, lineWidth: 1))
            .rotationEffect(.degrees(-5))
            .accessibilityLabel("達成済み")
    }
}

struct HistoryView: View {
    @Bindable var viewModel: FortuneViewModel

    var body: some View {
        List {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "まだ記録がありません",
                    systemImage: "moon.stars",
                    description: Text("今日のカードを引くと、ここに記録されます。")
                )
                .listRowBackground(FortuneStyle.background)
            } else {
                ForEach(viewModel.sessions) { session in
                    NavigationLink {
                        MissionSummaryView(session: session, viewModel: viewModel)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(session.localDateKey)
                                .font(.system(.caption, design: .serif))
                                .foregroundStyle(.secondary)
                            Text(session.title).font(.system(.body, design: .serif))
                            Text("\(session.completedCount) / 5")
                                .font(.system(.caption, design: .serif, weight: .semibold))
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(FortuneStyle.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FortuneStyle.background)
        .navigationTitle("過去の記録")
        .onAppear { viewModel.refresh() }
    }
}

private struct FortunePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(FortuneStyle.card)
            .background(FortuneStyle.ink.opacity(configuration.isPressed ? 0.75 : 1))
    }
}
