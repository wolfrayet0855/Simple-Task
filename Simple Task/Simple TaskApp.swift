import SwiftUI
import UserNotifications
import SimpleTaskKit

@main
struct ToDoListApp: App {
    init() {
        Scheduler.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
