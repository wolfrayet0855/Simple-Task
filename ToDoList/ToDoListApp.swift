//
//  ToDoListApp.swift
//  ToDoList
//
//  Created by user on 9/13/24.
//

import SwiftUI
import SwiftData
@main
struct ToDoListApp: App {

    
    var body: some Scene {
        WindowGroup {
            ToDoListView()
                .modelContainer(for: ToDo.self)
        }
    }
}
