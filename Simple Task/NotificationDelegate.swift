import UserNotifications
import SwiftData
import SimpleTaskKit

/// Routes the Done, +1 hour and Tomorrow buttons on a reminder, and shows banners while the app is open.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let container: ModelContainer
    private static var current: NotificationDelegate?

    /// Held strongly because the notification center only keeps a weak reference to its delegate.
    static func install(container: ModelContainer) {
        let delegate = NotificationDelegate(container: container)
        current = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    init(container: ModelContainer) { self.container = container }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard let id = NotificationRouter.taskID(fromIdentifier: response.notification.request.identifier) else { return }
        let action = response.actionIdentifier
        await MainActor.run {
            let context = container.mainContext
            try? NotificationRouter.handle(action: action, taskID: id, in: context)
            Widgets.reload()
            Task {
                let tasks = (try? context.fetch(FetchDescriptor<ToDo>())) ?? []
                await Scheduler(center: center).reconcile(tasks: tasks)
            }
        }
    }
}
