//
//  KIMAGURETests.swift
//  KIMAGURETests
//
//  Created by maho hayashi on 2026/11/03.
//

import Foundation
import Testing
@testable import KIMAGURE

struct KIMAGURETests {
    @Test func generatedFortuneHasRequiredMissionMix() throws {
        let draft = try FortuneGenerator.generate()

        #expect(draft.missions.count == 5)
        #expect(draft.missions.filter { $0.difficulty == .easy }.count == 3)
        #expect(draft.missions.filter { $0.difficulty == .adventure }.count == 2)
        #expect(Set(draft.missions.map(\.text)).count == 5)
    }

    @Test func localDayKeyUsesProvidedCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 11,
            day: 3,
            hour: 23,
            minute: 30
        )))

        #expect(LocalDay.key(for: date, calendar: calendar) == "2026-11-03")
    }
}
