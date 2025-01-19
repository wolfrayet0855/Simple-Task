//
//  Simple TaskApp.swift
//  Simple Task
//
//  Created by user on 9/13/24.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ToDoListApp: App {

    init() {
        requestNotificationPermission() // Request permission on app launch
    }

    var body: some Scene {
        WindowGroup {
            // IMPORTANT: Include both ToDo and SubTask in the model container
            ToDoListView()
                .modelContainer(for: [ToDo.self, SubTask.self])
        }
    }

    // Requesting Permission for Notifications
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            // Handle granted permission if needed
        }
    }
}
