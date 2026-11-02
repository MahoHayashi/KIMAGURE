//
//  KIMAGUREApp.swift
//  KIMAGURE
//
//  Created by maho hayashi on 2026/11/03.
//

import SwiftUI
import SwiftData

@main
struct KIMAGUREApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FortuneSession.self, FortuneCard.self, DailyMission.self])
    }
}
