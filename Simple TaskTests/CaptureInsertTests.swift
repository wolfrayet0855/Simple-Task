import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct CaptureInsertTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }

    func insert(_ p: ParsedCapture, _ c: ModelContext) throws -> ToDo {
        try Capture.insert(p, in: c, now: Fixed.now, calendar: Fixed.calendar)
    }

    @Test func undatedTaskLandsInHandUndated() throws {
        let c = try ctx()
        let t = try insert(ParsedCapture(title: "buy milk"), c)
        #expect(t.item == "buy milk")
        #expect(!t.isDated)
        #expect(t.stateRaw == "inHand")
        #expect(!t.reminderIsOn)
    }

    @Test func datedTaskKeepsItsDate() throws {
        let c = try ctx()
        let due = Fixed.days(2, hour: 19)
        let t = try insert(ParsedCapture(title: "dinner", due: due), c)
        #expect(t.isDated && t.dueDate == due)
    }

    @Test func tagIsReusedCaseInsensitivelyAndCreatedWhenMissing() throws {
        let c = try ctx()
        let a = try insert(ParsedCapture(title: "a", tag: "home"), c)
        let b = try insert(ParsedCapture(title: "b", tag: "HOME"), c)
        #expect(a.tag === b.tag)
        #expect(try c.fetchCount(FetchDescriptor<SchemaV2.Tag>()) == 1)
    }

    @Test func witnessCreatesAPledgeOnce() throws {
        let c = try ctx()
        let t = try insert(ParsedCapture(title: "send deck", due: Fixed.days(1), witness: "Priya"), c)
        _ = try insert(ParsedCapture(title: "other", witness: "priya"), c)
        #expect(t.pledge?.witness?.displayName == "Priya")
        #expect(t.pledge?.stateRaw == "open")
        #expect(try c.fetchCount(FetchDescriptor<Witness>()) == 1)
    }

    @Test func landmarkIsJoinedOrCreated() throws {
        let c = try ctx()
        let a = try insert(ParsedCapture(title: "a", landmark: "Party"), c)
        let b = try insert(ParsedCapture(title: "b", landmark: "party"), c)
        #expect(a.landmark === b.landmark)
        #expect(try c.fetchCount(FetchDescriptor<Landmark>()) == 1)
    }

    @Test func positionWithinBandIsLinearInTime() {
        func pos(_ days: Int, hour: Int = 0, due: Bool = true) -> Double {
            let s = TaskSnapshot(id: UUID(), title: "t", due: due ? Fixed.days(days, hour: hour) : nil,
                                 weight: .M, isDone: false)
            return TimeBands.position(for: s, now: Fixed.now, calendar: Fixed.calendar)
        }
        #expect(pos(1, hour: 0) == 0)                      // tomorrow midnight: nearest edge
        #expect(abs(pos(1, hour: 12) - 0.5) < 1e-9)        // tomorrow noon
        #expect(pos(2) == 0)                               // week starts at +2d
        #expect(abs(pos(7) - 5.0 / 6.0) < 1e-9)        // week spans +2d..+8d
        #expect(pos(8) == 0)                               // month starts at +8d
        #expect(pos(500) == 1)                             // horizon clamps
        #expect(pos(0, due: false) == 0)                   // undated sits at the floor
    }
}
