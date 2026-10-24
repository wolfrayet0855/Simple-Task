import Foundation
import SwiftData
import WidgetKit

public enum Widgets {
    public static func reload() { WidgetCenter.shared.reloadAllTimelines() }
}

/// Runs the Done, +1 hour and Tomorrow actions on a reminder.
public enum NotificationRouter {
    /// "task.<uuid>.reminder" -> uuid
    public static func taskID(fromIdentifier identifier: String) -> UUID? {
        let parts = identifier.split(separator: ".")
        guard parts.count == 3, parts[0] == "task", parts[2] == "reminder" else { return nil }
        return UUID(uuidString: String(parts[1]))
    }

    public static func handle(action: String, taskID: UUID, in context: ModelContext,
                              now: Date = .now, calendar: Calendar = .current) throws {
        let task = try TaskActions.task(id: taskID, in: context)
        switch action {
        case Scheduler.doneAction:
            try Completion.complete(task, in: context, now: now)
            return
        case Scheduler.plusHourAction:
            task.reminderDate = now.addingTimeInterval(3600)
            task.reminderIsOn = true
        case Scheduler.tomorrowAction:
            let day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
            task.isDated = true
            task.stateRaw = "active"
            task.dueDate = nineAM
            task.reminderDate = nineAM
            task.reminderIsOn = true
        default:
            return
        }
        task.modifiedAt = now
        try context.save()
    }
}
