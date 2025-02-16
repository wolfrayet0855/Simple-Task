import SwiftUI
import SwiftData
import UserNotifications

@main
struct ToDoListApp: App {
    // Use a closure to initialize the container so we can catch errors.
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: ToDo.self, SubTask.self)
        } catch {
            fatalError("Error initializing ModelContainer: \(error)")
        }
    }()

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ToDoListView()
                .modelContainer(container) // Inject the persistent container.
                .environmentObject(CategoryManager()) // Shared category manager.
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
}


