import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct IntentTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }

    @Test func completeIntentMarksTaskDoneAndReportsStoneNumber() throws {
        let c = try ctx()
        let done = ToDo(item: "old", isCompleted: true)
        let open = ToDo(item: "Send deck")
        c.insert(done); c.insert(open)

        let stone = try TaskActions.complete(id: open.id, in: c, now: Fixed.now)

        #expect(stone == 2)
        #expect(open.isCompleted && open.stateRaw == "done")
    }

    @Test func completeIntentOnMissingTaskThrowsFriendlyError() throws {
        let c = try ctx()
        #expect(throws: TaskError.notFound) {
            try TaskActions.complete(id: UUID(), in: c, now: Fixed.now)
        }
        #expect(TaskError.notFound.errorDescription == "That task isn't here anymore.")
    }

    @Test func suggestedEntitiesAreInHandOnly() throws {
        let c = try ctx()
        let today = ToDo(item: "today"); today.dueDate = Fixed.days(0, hour: 15)
        let later = ToDo(item: "later"); later.dueDate = Fixed.days(10)
        let finished = ToDo(item: "finished", isCompleted: true)
        [today, later, finished].forEach(c.insert)

        let titles = try TaskActions.inHand(in: c, now: Fixed.now, calendar: Fixed.calendar).map(\.title)

        #expect(titles == ["today"])
    }

    @Test func entityMapsFromTask() {
        let t = ToDo(item: "Pay rent")
        t.dueDate = Fixed.days(1)
        let e = TaskEntity(t)
        #expect(e.id == t.id && e.title == "Pay rent" && e.due == t.dueDate && !e.isDone)
    }
}
