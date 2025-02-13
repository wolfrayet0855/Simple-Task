//
//  Simple TaskApp.swift
//  Simple Task
//
//  Redesigned main app file with notification permission request on launch.
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
            ToDoListView()
                .modelContainer(for: [ToDo.self, SubTask.self])
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

