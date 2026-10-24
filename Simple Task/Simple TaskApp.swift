import SwiftUI
import SwiftData
import UserNotifications
import SimpleTaskKit

@main
struct ToDoListApp: App {
    let container: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        let container: ModelContainer
        do {
            container = try Store.bootstrap()
            #if DEBUG
            DemoSeed.run(container)
            #endif
        } catch {
            fatalError("Error initializing ModelContainer: \(error)")
        }
        self.container = container
        notificationDelegate = NotificationDelegate(container: container)
        UNUserNotificationCenter.current().delegate = notificationDelegate
        Self.requestNotificationPermission()
        Scheduler.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            HorizonView()
                .modelContainer(container) // Inject the persistent container.
                .environmentObject(CategoryManager()) // Legacy screens only.
        }
    }

    static func requestNotificationPermission() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-skipPermission") { return }
        #endif
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
}
