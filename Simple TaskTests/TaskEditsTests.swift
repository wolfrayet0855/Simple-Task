import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct TaskEditsTests {
    func ctx() throws -> ModelContext { ModelContext(try Store.makeContainer(inMemory: true)) }
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func make(_ c: ModelContext, _ title: String = "a") -> ToDo {
        let t = ToDo(item: title); c.insert(t); return t
    }

    @Test func titleIsTrimmedAndEmptyIsRejected() throws {
        let c = try ctx(); let t = make(c, "old")
        #expect(try TaskEdits.setTitle("  new  ", on: t, in: c, now: now))
        #expect(t.item == "new" && t.modifiedAt == now)
        #expect(try !TaskEdits.setTitle("   ", on: t, in: c, now: now))
        #expect(t.item == "new")
    }

    @Test func weightRoundTrips() throws {
        let c = try ctx(); let t = make(c)
        try TaskEdits.setWeight(.L, on: t, in: c, now: now)
        #expect(t.weightRaw == "L" && Weight(raw: t.weightRaw) == .L && t.modifiedAt == now)
    }

    @Test func clearingTheDateMovesTaskInHand() throws {
        let c = try ctx(); let t = make(c)
        try TaskEdits.setWhen(.undated, on: t, in: c, now: now)
        #expect(!t.isDated && t.stateRaw == "inHand")
        #expect(TimeBands.band(for: TaskSnapshot(t), now: now, calendar: cal) == .inHand)
    }

    @Test func settingTomorrowNineLandsInTomorrowAndReactivatesShelved() throws {
        let c = try ctx(); let t = make(c)
        t.isDated = false; t.stateRaw = "shelved"
        let nine = cal.date(bySettingHour: 9, minute: 0, second: 0, of: cal.date(byAdding: .day, value: 1, to: now)!)!
        try TaskEdits.setWhen(.at(nine, allDay: false), on: t, in: c, now: now)
        #expect(t.isDated && t.dueDate == nine && !t.isAllDay && t.stateRaw == "active")
        #expect(TimeBands.band(for: TaskSnapshot(t), now: now, calendar: cal) == .tomorrow)
    }

    @Test func allDayFlagIsStored() throws {
        let c = try ctx(); let t = make(c)
        try TaskEdits.setWhen(.at(now, allDay: true), on: t, in: c, now: now)
        #expect(t.isAllDay)
    }

    @Test func stopsMoveTheTask() throws {
        let c = try ctx(); let t = make(c)
        func band() -> Band { TimeBands.band(for: TaskSnapshot(t), now: now, calendar: cal) }
        try TaskEdits.move(t, to: .tomorrow, in: c, now: now, calendar: cal)
        #expect(band() == .tomorrow && cal.component(.hour, from: t.dueDate) == 9)
        try TaskEdits.move(t, to: .week, in: c, now: now, calendar: cal)
        #expect(band() == .week && cal.component(.weekday, from: t.dueDate) == 2 && cal.component(.hour, from: t.dueDate) == 9)
        try TaskEdits.move(t, to: .month, in: c, now: now, calendar: cal)
        #expect(band() == .month && cal.component(.weekday, from: t.dueDate) == cal.component(.weekday, from: now))
        try TaskEdits.move(t, to: .shelf, in: c, now: now, calendar: cal)
        #expect(!t.isDated && t.stateRaw == "shelved")
        #expect(TaskEdits.stop(of: t, now: now, calendar: cal) == .shelf)
    }

    @Test func todayKeepsATimeStillAheadElseGoesUndated() throws {
        let c = try ctx(); let t = make(c)
        let later = now.addingTimeInterval(3 * 3600)
        t.isDated = true; t.isAllDay = false; t.dueDate = cal.date(byAdding: .day, value: 3, to: later)!
        try TaskEdits.move(t, to: .today, in: c, now: now, calendar: cal)
        #expect(t.isDated && t.dueDate == later && t.stateRaw == "active")

        let earlier = now.addingTimeInterval(-3 * 3600)
        t.dueDate = cal.date(byAdding: .day, value: 3, to: earlier)!
        try TaskEdits.move(t, to: .today, in: c, now: now, calendar: cal)
        #expect(!t.isDated && t.stateRaw == "inHand")
    }

    @Test func stopReflectsBands() throws {
        let c = try ctx(); let t = make(c)
        t.isDated = true; t.dueDate = cal.date(byAdding: .day, value: 40, to: now)!
        #expect(TaskEdits.stop(of: t, now: now, calendar: cal) == .beyond)
        t.isDated = false; t.stateRaw = "inHand"
        #expect(TaskEdits.stop(of: t, now: now, calendar: cal) == .today)
    }

    @Test func reminderOnOffAndOffsets() throws {
        let c = try ctx(); let t = make(c)
        let due = cal.date(bySettingHour: 15, minute: 0, second: 0, of: now)!
        #expect(TaskEdits.reminderDate(.tenMinutesBefore, due: due, calendar: cal) == due.addingTimeInterval(-600))
        #expect(TaskEdits.reminderDate(.oneHourBefore, due: due, calendar: cal) == due.addingTimeInterval(-3600))
        #expect(TaskEdits.reminderDate(.atTime, due: due, calendar: cal) == due)
        #expect(TaskEdits.reminderDate(.morningOf, due: due, calendar: cal) == cal.date(bySettingHour: 9, minute: 0, second: 0, of: due))
        try TaskEdits.setReminder(on: true, at: due, on: t, in: c, now: now)
        #expect(t.reminderIsOn && t.reminderDate == due)
        try TaskEdits.setReminder(on: false, at: nil, on: t, in: c, now: now)
        #expect(!t.reminderIsOn && t.reminderDate == due)
    }

    @Test func stepsAddToggleMoveRemoveKeepOrderContiguous() throws {
        let c = try ctx(); let t = make(c)
        let a = try #require(try TaskEdits.addStep("a", to: t, in: c, now: now))
        let b = try #require(try TaskEdits.addStep("b", to: t, in: c, now: now))
        let d = try #require(try TaskEdits.addStep("c", to: t, in: c, now: now))
        #expect(TaskEdits.orderedSteps(t).map(\.name) == ["a", "b", "c"])
        try TaskEdits.moveStep(d, by: -1, in: c, now: now)
        #expect(TaskEdits.orderedSteps(t).map(\.name) == ["a", "c", "b"])
        #expect(TaskEdits.orderedSteps(t).map(\.order) == [0, 1, 2])
        try TaskEdits.moveStep(a, by: -1, in: c, now: now)
        #expect(TaskEdits.orderedSteps(t).first?.name == "a")
        try TaskEdits.toggleStep(b, in: c, now: now)
        #expect(b.isCompleted)
        try TaskEdits.removeStep(d, in: c, now: now)
        #expect(TaskEdits.orderedSteps(t).map(\.name) == ["a", "b"])
        #expect(TaskEdits.orderedSteps(t).map(\.order) == [0, 1])
    }

    @Test func blankStepIsIgnored() throws {
        let c = try ctx(); let t = make(c)
        #expect(try TaskEdits.addStep("  ", to: t, in: c, now: now) == nil)
        #expect(TaskEdits.orderedSteps(t).isEmpty)
    }

    @Test func tagAssignClearAndNewTagGetsNextFreeColour() throws {
        let c = try ctx(); let t = make(c)
        let first = try TaskEdits.createTag("Garden", on: t, in: c, now: now)
        #expect(t.tag === first && t.category == "Garden" && first.colorToken == "tag.1")
        let second = try TaskEdits.createTag("Work", on: t, in: c, now: now)
        #expect(second.colorToken == "tag.2")
        let again = try TaskEdits.createTag("garden", on: t, in: c, now: now)
        #expect(again === first)
        #expect(try c.fetchCount(FetchDescriptor<SchemaV2.Tag>()) == 2)
        try TaskEdits.setTag(nil, on: t, in: c, now: now)
        #expect(t.tag == nil)
    }

    @Test func notesRoundTrip() throws {
        let c = try ctx(); let t = make(c)
        try TaskEdits.setNotes("hello\nworld", on: t, in: c, now: now)
        #expect(t.notes == "hello\nworld" && t.modifiedAt == now)
    }

    @Test func reopenClearsCompletion() throws {
        let c = try ctx(); let t = make(c)
        _ = try Completion.complete(t, in: c, now: now)
        try TaskEdits.reopen(t, in: c, now: now.addingTimeInterval(600))
        #expect(!t.isCompleted && t.completedAt == nil && t.stateRaw == "active")
    }

    @Test func deleteRemovesTaskAndStepsAndReturnsNotificationID() throws {
        let c = try ctx(); let t = make(c)
        _ = try TaskEdits.addStep("a", to: t, in: c, now: now)
        let id = t.notificationID
        let returned = try TaskEdits.delete(t, in: c)
        #expect(returned == id)
        #expect(try c.fetchCount(FetchDescriptor<ToDo>()) == 0)
        #expect(try c.fetchCount(FetchDescriptor<SubTask>()) == 0)
    }

    @Test func deleteIsRefusedForCompletedTasksSoTheCairnNeverShrinks() throws {
        let c = try ctx(); let t = make(c)
        _ = try Completion.complete(t, in: c, now: now)
        #expect(!TaskEdits.canDelete(t))
        #expect(throws: TaskEdits.EditError.self) { try TaskEdits.delete(t, in: c) }
        #expect(try Completion.cairnTotal(in: c) == 1)
    }
}
