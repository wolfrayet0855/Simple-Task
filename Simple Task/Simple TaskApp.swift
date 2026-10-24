import SwiftUI
import SwiftData
import UserNotifications
import SimpleTaskKit

@main
struct ToDoListApp: App {
    // Use a closure to initialize the container so we can catch errors.
    let container: ModelContainer = {
        do {
            let container = try Store.bootstrap()
            #if DEBUG
            DemoSeed.run(container)
            #endif
            return container
        } catch {
            fatalError("Error initializing ModelContainer: \(error)")
        }
    }()

    init() {
        requestNotificationPermission()
        Scheduler.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            HorizonView()
                .modelContainer(container) // Inject the persistent container.
                .environmentObject(CategoryManager()) // Shared category manager.
        }
    }

    func requestNotificationPermission() {
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


