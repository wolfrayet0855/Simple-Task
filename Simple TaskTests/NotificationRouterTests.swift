import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct NotificationRouterTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }

    @Test func doneActionFinishesTheTask() throws {
        let c = try ctx()
        let t = ToDo(item: "Send deck", reminderIsOn: true); c.insert(t)
        try NotificationRouter.handle(action: Scheduler.doneAction, taskID: t.id, in: c, now: Fixed.now, calendar: Fixed.calendar)
        #expect(t.isCompleted && t.stateRaw == "done")
    }

    @Test func plusHourMovesTheReminderOneHour() throws {
        let c = try ctx()
        let t = ToDo(item: "Send deck", reminderIsOn: true, reminderDate: Fixed.now); c.insert(t)
        try NotificationRouter.handle(action: Scheduler.plusHourAction, taskID: t.id, in: c, now: Fixed.now, calendar: Fixed.calendar)
        #expect(t.reminderDate == Fixed.now.addingTimeInterval(3600))
        #expect(t.reminderIsOn && !t.isCompleted)
    }

    @Test func tomorrowActionMovesDueAndReminderToNineAm() throws {
        let c = try ctx()
        let t = ToDo(item: "Send deck", reminderIsOn: true); c.insert(t)
        try NotificationRouter.handle(action: Scheduler.tomorrowAction, taskID: t.id, in: c, now: Fixed.now, calendar: Fixed.calendar)
        #expect(t.dueDate == Fixed.days(1, hour: 9) && t.isDated)
        #expect(t.reminderDate == Fixed.days(1, hour: 9))
    }

    @Test func unknownTaskIsAFriendlyError() throws {
        let c = try ctx()
        #expect(throws: TaskError.notFound) {
            try NotificationRouter.handle(action: Scheduler.doneAction, taskID: UUID(), in: c, now: Fixed.now, calendar: Fixed.calendar)
        }
    }
}
