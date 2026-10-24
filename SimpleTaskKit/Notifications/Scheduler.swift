import Foundation
import UserNotifications

public protocol NotificationCenterProtocol {
    func schedule(_ request: UNNotificationRequest) async throws
    func removePending(_ identifiers: [String])
    func pendingIDs() async -> [String]
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    public func schedule(_ request: UNNotificationRequest) async throws { try await add(request) }
    public func removePending(_ identifiers: [String]) { removePendingNotificationRequests(withIdentifiers: identifiers) }
    public func pendingIDs() async -> [String] { await pendingNotificationRequests().map(\.identifier) }
}

/// Each device schedules its own local notifications from synced data; there is no cross-device relay.
public struct Scheduler {
    public static let categoryID = "TASK"
    public static let doneAction = "TASK_DONE"
    public static let plusHourAction = "TASK_PLUS_HOUR"
    public static let tomorrowAction = "TASK_TOMORROW"

    private let center: NotificationCenterProtocol

    public init(center: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    public static func registerCategories(on center: UNUserNotificationCenter = .current()) {
        let actions = [
            UNNotificationAction(identifier: doneAction, title: "Done", options: []),
            UNNotificationAction(identifier: plusHourAction, title: "+1 hour", options: []),
            UNNotificationAction(identifier: tomorrowAction, title: "Tomorrow", options: []),
        ]
        center.setNotificationCategories([
            UNNotificationCategory(identifier: categoryID, actions: actions, intentIdentifiers: [])
        ])
    }

    static func wantsReminder(_ task: ToDo, now: Date) -> Bool {
        task.reminderIsOn && !task.isCompleted && task.reminderDate > now
    }

    public func schedule(_ task: ToDo, now: Date = .now) async {
        let id = task.notificationID
        guard Self.wantsReminder(task, now: now) else {
            center.removePending([id])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Ready when you are"
        content.body = task.item
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        let parts = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: task.reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try? await center.schedule(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// Makes pending requests match the data: removes legacy title-keyed and orphaned requests, then schedules.
    public func reconcile(tasks: [ToDo], now: Date = .now) async {
        let wanted = tasks.filter { Self.wantsReminder($0, now: now) }
        let wantedIDs = Set(wanted.map(\.notificationID))
        let stale = await center.pendingIDs().filter { !wantedIDs.contains($0) }
        center.removePending(stale)
        for task in wanted { await schedule(task, now: now) }
    }
}
