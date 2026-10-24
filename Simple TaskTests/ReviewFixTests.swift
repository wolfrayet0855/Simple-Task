import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct ReviewFixTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }

    // 1. A half-finished migration leaves one shared id on many rows. Never delete them for that.
    @Test func reconcileRepairsCollapsedIdsInsteadOfDeleting() throws {
        let c = try ctx()
        let shared = UUID()
        let created = Date(timeIntervalSince1970: 100)
        for title in ["a", "b", "c", "d"] {
            let t = ToDo(item: title)
            t.id = shared
            t.createdAt = created
            c.insert(t)
        }
        try c.save()

        try Store.reconcile(context: c)

        let all = try c.fetch(FetchDescriptor<ToDo>())
        #expect(all.count == 4)
        #expect(Set(all.map(\.id)).count == 4)
        #expect(Set(all.map(\.item)) == ["a", "b", "c", "d"])
    }

    @Test func reconcileStillMergesExactDuplicates() throws {
        let c = try ctx()
        let shared = UUID()
        let created = Date(timeIntervalSince1970: 100)
        for modified in [100.0, 200.0] {
            let t = ToDo(item: "same")
            t.id = shared
            t.createdAt = created
            t.modifiedAt = Date(timeIntervalSince1970: modified)
            c.insert(t)
        }
        try c.save()
        try Store.reconcile(context: c)
        #expect(try c.fetchCount(FetchDescriptor<ToDo>()) == 1)
    }

    @Test func storeIsNotReadyWhileLegacyExistsAndFlagUnset() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let legacy = dir.appendingPathComponent("default.store")
        let defaults = UserDefaults(suiteName: "ready.\(UUID().uuidString)")!

        #expect(Store.isReady(defaults: defaults, legacyURL: legacy))          // nothing to move
        try Data("x".utf8).write(to: legacy)
        #expect(!Store.isReady(defaults: defaults, legacyURL: legacy))         // app must relocate first
        defaults.set("group", forKey: Store.locationKey)
        #expect(Store.isReady(defaults: defaults, legacyURL: legacy))
    }

    // 3. A store whose only open tasks are shelved shows the empty state.
    @Test func shelfOnlyFieldIsEmpty() {
        let shelved = TaskSnapshot(id: UUID(), title: "later", due: nil, weight: .M, isDone: false, isShelved: true)
        let m = HorizonModel.build([shelved], cairnTotal: 0, now: Fixed.now, calendar: Fixed.calendar)
        #expect(m.isEmpty)
        #expect(m.groups[.shelf]?.visible.count == 1)
    }

    @Test func undoWindowCanBeWidenedForVoiceOver() throws {
        let c = try ctx()
        let a = ToDo(item: "a"); c.insert(a)
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        _ = try Completion.complete(a, in: c, now: t0)
        #expect(try Completion.undo(a, in: c, now: t0.addingTimeInterval(12), window: 15))
    }
}

struct ParserFixTests {
    func parse(_ s: String) -> ParsedCapture? { CaptureParser.parse(s, now: Fixed.now, calendar: Fixed.calendar) }

    // 2. Typing a bad time must never crash.
    @Test func impossibleMinutesDoNotCrash() {
        #expect(parse("meet 7:60pm")?.due == nil)
        #expect(parse("meet 10:75am")?.due == nil)
        #expect(parse("meet 13pm")?.due == nil)
        #expect(parse("meet 25:00")?.due == nil)
        #expect(parse("call in 99999999999999999999 days") != nil)
    }

    // 8. Ordinary words are not dates.
    @Test func sunCreamKeepsItsTitle() throws {
        let p = try #require(parse("Buy sun cream"))
        #expect(p.title == "Buy sun cream")
        #expect(p.due == nil)
    }
    @Test func satDownIsNotSaturday() throws {
        let p = try #require(parse("I sat down"))
        #expect(p.title == "I sat down" && p.due == nil)
    }
    @Test func danglingAtGoesWithItsTime() throws {
        let p = try #require(parse("Call mom at 3pm"))
        #expect(p.title == "Call mom")
        #expect(p.due == Fixed.days(0, hour: 15))
    }
    @Test func shortWeekdayNeedsOnOrATime() throws {
        #expect(try #require(parse("review on wed")).due == Fixed.days(7, hour: 9))
        #expect(try #require(parse("review friday")).due == Fixed.days(2, hour: 9))
        #expect(try #require(parse("lunch fri 12pm")).due == Fixed.days(2, hour: 12))
        #expect(try #require(parse("review wed")).due == nil)
    }
}
