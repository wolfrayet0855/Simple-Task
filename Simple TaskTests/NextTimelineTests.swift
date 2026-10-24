import Testing
import Foundation
@testable import SimpleTaskKit

struct NextTimelineTests {
    func snap(_ title: String, due: Date?, done: Bool = false) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: title, due: due, weight: .M, isDone: done)
    }

    @Test func nextEntryPicksEarliestInHand() {
        let entry = nextEntry(from: [
            snap("later", due: Fixed.days(0, hour: 17)),
            snap("sooner", due: Fixed.days(0, hour: 11)),
            snap("tomorrow", due: Fixed.days(1)),
        ], now: Fixed.now, calendar: Fixed.calendar)
        #expect(entry.task?.title == "sooner")
    }

    @Test func nextEntryEmptyWhenNothingInHand() {
        let entry = nextEntry(from: [snap("far", due: Fixed.days(9)), snap("done", due: nil, done: true)],
                              now: Fixed.now, calendar: Fixed.calendar)
        #expect(entry.task == nil)
    }

    @Test func nextEntryCountsStonesAndStampsTheTime() {
        let entry = nextEntry(from: [snap("a", due: nil, done: true), snap("b", due: nil, done: true)],
                              now: Fixed.now, calendar: Fixed.calendar)
        #expect(entry.stones == 2)
        #expect(entry.date == Fixed.now)
    }

    @Test func refreshDateIsNextMidnightWhenNothingIsTimed() {
        let entry = nextEntry(from: [], now: Fixed.now, calendar: Fixed.calendar)
        #expect(entry.refreshAt == Fixed.days(1, hour: 0))
    }
}
