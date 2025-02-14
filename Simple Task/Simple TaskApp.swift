import SwiftUI
import SwiftData
import UserNotifications

@main
struct ToDoListApp: App {
    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ToDoListView()
                .modelContainer(for: [ToDo.self, SubTask.self])
                .environmentObject(CategoryManager())  // Inject shared CategoryManager here
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

