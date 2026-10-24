import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct CompleteTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }

    @Test func completeIncrementsCairnAndIsUndoableWithin5s() throws {
        let c = try ctx()
        let a = ToDo(item: "a"), b = ToDo(item: "b")
        c.insert(a); c.insert(b)
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(try Completion.complete(a, in: c, now: t0) == 1)
        #expect(try Completion.complete(b, in: c, now: t0) == 2)
        #expect(a.isCompleted && a.stateRaw == "done" && a.completedAt == t0)

        #expect(try Completion.undo(b, in: c, now: t0.addingTimeInterval(4.9)))
        #expect(!b.isCompleted && b.completedAt == nil && b.stateRaw == "active")
        #expect(try Completion.cairnTotal(in: c) == 1)
    }

    @Test func undoAfter5sIsRejected() throws {
        let c = try ctx()
        let a = ToDo(item: "a")
        c.insert(a)
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        _ = try Completion.complete(a, in: c, now: t0)

        #expect(try !Completion.undo(a, in: c, now: t0.addingTimeInterval(5.1)))
        #expect(a.isCompleted)
    }

    @Test func completingTwiceDoesNotInflateTheCairn() throws {
        let c = try ctx()
        let a = ToDo(item: "a")
        c.insert(a)
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        _ = try Completion.complete(a, in: c, now: t0)
        #expect(try Completion.complete(a, in: c, now: t0.addingTimeInterval(60)) == 1)
        #expect(a.completedAt == t0)
    }
}
