import Testing
import Foundation
@testable import SimpleTaskKit

enum Fixed {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    /// Wednesday 2026-10-21 10:00 UTC
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 10))!
    static func days(_ n: Int, hour: Int = 12) -> Date {
        let day = calendar.date(byAdding: .day, value: n, to: calendar.startOfDay(for: now))!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }
}

struct TimeBandsTests {
    func snap(due: Date?, done: Bool = false, shelved: Bool = false) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: "t", due: due, weight: .M, isDone: done, isShelved: shelved)
    }
    func band(_ s: TaskSnapshot) -> Band { TimeBands.band(for: s, now: Fixed.now, calendar: Fixed.calendar) }

    @Test func dueTodayIsInHand() { #expect(band(snap(due: Fixed.days(0, hour: 18))) == .inHand) }
    @Test func earlierTodayIsStillInHandNotSlipped() { #expect(band(snap(due: Fixed.days(0, hour: 8))) == .inHand) }
    @Test func undatedIsInHand() { #expect(band(snap(due: nil)) == .inHand) }
    @Test func tomorrow() { #expect(band(snap(due: Fixed.days(1))) == .tomorrow) }
    @Test func fiveDaysIsWeek() { #expect(band(snap(due: Fixed.days(5))) == .week) }
    @Test func twentyDaysIsMonth() { #expect(band(snap(due: Fixed.days(20))) == .month) }
    @Test func sixtyDaysIsHorizon() { #expect(band(snap(due: Fixed.days(60))) == .horizon) }

    @Test func yesterdayIsSlippedNeverInHand() {
        let s = snap(due: Fixed.days(-1))
        #expect(TimeBands.isSlipped(s, now: Fixed.now, calendar: Fixed.calendar))
        #expect(band(s) == .slipped)
    }
    @Test func slippedMoreThanSevenDaysGoesToShelf() { #expect(band(snap(due: Fixed.days(-8))) == .shelf) }
    @Test func shelvedFlagGoesToShelf() { #expect(band(snap(due: Fixed.days(2), shelved: true)) == .shelf) }
    @Test func doneGoesToCairn() { #expect(band(snap(due: Fixed.days(-3), done: true)) == .cairn) }

    @Test func scaleEndpoints() {
        #expect(TimeBands.scale(depth: 0) == 1)
        #expect(TimeBands.scale(depth: 1) == 0.45)
    }
    @Test func capsMatchTheSpec() {
        #expect([Band.inHand, .tomorrow, .week, .month, .horizon].map(TimeBands.caps) == [5, 4, 6, 6, 4])
    }
    @Test func bandFractionsAreContiguousFromTheBottom() {
        let order: [Band] = [.cairn, .inHand, .tomorrow, .week, .month, .horizon]
        var edge = 0.0
        for b in order {
            let r = try! #require(Band.fractions[b])
            #expect(abs(r.lowerBound - edge) < 1e-9)
            edge = r.upperBound
        }
        #expect(edge == 1.0)
    }
    @Test func weightHeights() {
        #expect([Weight.S, .M, .L].map { Double($0.height) } == [56, 72, 96])
        #expect(Weight(raw: "garbage") == .M)
    }
}
