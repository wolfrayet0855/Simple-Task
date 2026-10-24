import Foundation
import SwiftData

/// Pure edit logic behind the task sheet. Every edit stamps `modifiedAt` and saves.
/// The caller reschedules the notification and reloads widgets afterwards.
public enum TaskEdits {
    public enum When: Equatable {
        case undated
        case at(Date, allDay: Bool)
    }

    /// The six stops of the "where it sits" control.
    public enum Stop: String, CaseIterable, Identifiable, Sendable {
        case today = "Today", tomorrow = "Tomorrow", week = "Week", month = "Month", beyond = "Beyond", shelf = "Shelf"
        public var id: String { rawValue }
    }

    public enum ReminderOffset: CaseIterable, Sendable {
        case atTime, tenMinutesBefore, oneHourBefore, morningOf
    }

    public enum EditError: Error { case completedTaskCannotBeDeleted }

    private static func touch(_ task: ToDo, _ context: ModelContext, _ now: Date) throws {
        task.modifiedAt = now
        try context.save()
    }

    // MARK: Title, weight, notes

    /// Trims the title. An empty result is rejected and the old title kept; returns whether it changed.
    @discardableResult
    public static func setTitle(_ title: String, on task: ToDo, in context: ModelContext, now: Date = .now) throws -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        task.item = trimmed
        try touch(task, context, now)
        return true
    }

    public static func setWeight(_ weight: Weight, on task: ToDo, in context: ModelContext, now: Date = .now) throws {
        task.weightRaw = weight.rawValue
        try touch(task, context, now)
    }

    public static func setNotes(_ notes: String, on task: ToDo, in context: ModelContext, now: Date = .now) throws {
        task.notes = notes
        try touch(task, context, now)
    }

    // MARK: When

    public static func setWhen(_ when: When, on task: ToDo, in context: ModelContext, now: Date = .now) throws {
        switch when {
        case .undated:
            task.isDated = false
            if !task.isCompleted { task.stateRaw = "inHand" }
        case let .at(date, allDay):
            task.isDated = true
            task.dueDate = date
            task.isAllDay = allDay
            if !task.isCompleted { task.stateRaw = "active" }
        }
        try touch(task, context, now)
    }

    /// Which stop the task sits on, or nil when it has slipped or is done.
    public static func stop(of task: ToDo, now: Date = .now, calendar: Calendar = .current) -> Stop? {
        switch TimeBands.band(for: TaskSnapshot(task), now: now, calendar: calendar) {
        case .inHand: .today
        case .tomorrow: .tomorrow
        case .week: .week
        case .month: .month
        case .horizon: .beyond
        case .shelf: .shelf
        case .slipped, .cairn: nil
        }
    }

    /// Moves the task to a stop using the Horizon's reschedule rules. `.beyond` picks a provisional date 40 days out.
    public static func move(_ task: ToDo, to stop: Stop, in context: ModelContext,
                            now: Date = .now, calendar: Calendar = .current) throws {
        let start = calendar.startOfDay(for: now)
        func at9(_ day: Date) -> Date { calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day }
        switch stop {
        case .today:
            // Keep the time of day when it is still ahead today; otherwise the task is undated, In Hand.
            let time = calendar.dateComponents([.hour, .minute, .second], from: task.dueDate)
            let today = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0,
                                      second: time.second ?? 0, of: now)
            if task.isDated, !task.isAllDay, let today, today > now {
                try setWhen(.at(today, allDay: false), on: task, in: context, now: now)
            } else {
                try setWhen(.undated, on: task, in: context, now: now)
            }
        case .tomorrow:
            try setWhen(.at(at9(calendar.date(byAdding: .day, value: 1, to: start)!), allDay: false), on: task, in: context, now: now)
        case .week:
            let monday = calendar.nextDate(after: now, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)!
            try setWhen(.at(at9(monday), allDay: false), on: task, in: context, now: now)
        case .month:
            try setWhen(.at(at9(calendar.date(byAdding: .day, value: 14, to: start)!), allDay: false), on: task, in: context, now: now)
        case .beyond:
            try setWhen(.at(at9(calendar.date(byAdding: .day, value: 40, to: start)!), allDay: false), on: task, in: context, now: now)
        case .shelf:
            task.isDated = false
            task.stateRaw = "shelved"
            try touch(task, context, now)
        }
    }

    // MARK: Reminder

    public static func reminderDate(_ offset: ReminderOffset, due: Date, calendar: Calendar = .current) -> Date {
        switch offset {
        case .atTime: due
        case .tenMinutesBefore: due.addingTimeInterval(-600)
        case .oneHourBefore: due.addingTimeInterval(-3600)
        case .morningOf: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: due) ?? due
        }
    }

    public static func setReminder(on: Bool, at date: Date?, on task: ToDo, in context: ModelContext, now: Date = .now) throws {
        task.reminderIsOn = on
        if let date { task.reminderDate = date }
        try touch(task, context, now)
    }

    // MARK: Steps

    public static func orderedSteps(_ task: ToDo) -> [SubTask] {
        (task.subtasks ?? []).sorted { $0.order < $1.order }
    }

    private static func renumber(_ steps: [SubTask]) {
        for (i, step) in steps.enumerated() { step.order = i }
    }

    @discardableResult
    public static func addStep(_ name: String, to task: ToDo, in context: ModelContext, now: Date = .now) throws -> SubTask? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let step = SubTask(name: trimmed)
        step.order = (orderedSteps(task).last?.order ?? -1) + 1
        context.insert(step)
        step.parent = task
        try touch(task, context, now)
        return step
    }

    public static func toggleStep(_ step: SubTask, in context: ModelContext, now: Date = .now) throws {
        step.isCompleted.toggle()
        if let parent = step.parent { try touch(parent, context, now) } else { try context.save() }
    }

    public static func renameStep(_ step: SubTask, to name: String, in context: ModelContext, now: Date = .now) throws {
        step.name = name
        if let parent = step.parent { try touch(parent, context, now) } else { try context.save() }
    }

    /// Moves a step one place up (-1) or down (+1); a move past either end does nothing.
    public static func moveStep(_ step: SubTask, by delta: Int, in context: ModelContext, now: Date = .now) throws {
        guard let parent = step.parent else { return }
        var steps = orderedSteps(parent)
        guard let from = steps.firstIndex(where: { $0 === step }) else { return }
        let to = from + delta
        guard steps.indices.contains(to) else { return }
        steps.swapAt(from, to)
        renumber(steps)
        try touch(parent, context, now)
    }

    public static func removeStep(_ step: SubTask, in context: ModelContext, now: Date = .now) throws {
        let parent = step.parent
        context.delete(step)
        if let parent {
            renumber(orderedSteps(parent).filter { $0 !== step })
            try touch(parent, context, now)
        } else {
            try context.save()
        }
    }

    // MARK: Tags

    public static func setTag(_ tag: Tag?, on task: ToDo, in context: ModelContext, now: Date = .now) throws {
        task.tag = tag
        task.category = tag?.name ?? "Other"
        try touch(task, context, now)
    }

    /// Assigns the Tag with this name (case-insensitive), creating it with the next free `tag.N` colour when missing.
    @discardableResult
    public static func createTag(_ name: String, on task: ToDo, in context: ModelContext, now: Date = .now) throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = try context.fetch(FetchDescriptor<Tag>())
        let tag: Tag
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            tag = existing
        } else {
            let used = Set(all.map(\.colorToken))
            let token = (1...8).map { "tag.\($0)" }.first { !used.contains($0) } ?? "tag.\(all.count % 8 + 1)"
            tag = Tag(name: trimmed, colorToken: token, order: (all.map(\.order).max() ?? -1) + 1)
            context.insert(tag)
        }
        try setTag(tag, on: task, in: context, now: now)
        return tag
    }

    // MARK: Reopen and delete

    /// Takes a finished task back out of the Cairn's count (it is counted by completed tasks).
    public static func reopen(_ task: ToDo, in context: ModelContext, now: Date = .now) throws {
        task.isCompleted = false
        task.completedAt = nil
        task.stateRaw = task.isDated ? "active" : "inHand"
        try touch(task, context, now)
    }

    /// The Cairn total counts completed tasks, so finished work is never deleted from the sheet.
    public static func canDelete(_ task: ToDo) -> Bool { !task.isCompleted }

    /// Deletes the task and its steps. Returns the notification id the caller must cancel.
    @discardableResult
    public static func delete(_ task: ToDo, in context: ModelContext) throws -> String {
        guard canDelete(task) else { throw EditError.completedTaskCannotBeDeleted }
        let id = task.notificationID
        context.delete(task)
        try context.save()
        return id
    }
}
