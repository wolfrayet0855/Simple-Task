//
//  Simple Task.swift
//  Simple Task
//
//  Redesigned models with Identifiable conformance for SwiftUI
//
import Foundation
import SwiftData

@Model
class ToDo: Identifiable {
    @Attribute(.unique) var item = ""
    var reminderIsOn = false
    var dueDate = Date().addingTimeInterval(60*60*24)
    // Removed notes property
    var reminderDate = Date().addingTimeInterval(60*60*24) // New custom reminder date property.
    var isCompleted = false
    var isAllDay = false
    var category: String = "Work" // Still stored; will be managed via SettingsView.
    @Relationship(inverse: \SubTask.parent) var subtasks: [SubTask] = []

    init(item: String = "",
         reminderIsOn: Bool = false,
         dueDate: Date = Date().addingTimeInterval(60*60*24),
         reminderDate: Date = Date().addingTimeInterval(60*60*24),
         isCompleted: Bool = false,
         isAllDay: Bool = false,
         category: String = "Work") {
        self.item = item
        self.reminderIsOn = reminderIsOn
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.isAllDay = isAllDay
        self.category = category
    }
}

@Model
class SubTask: Identifiable {
    var name: String
    var isCompleted: Bool
    @Relationship var parent: ToDo?

    init(name: String = "", isCompleted: Bool = false, parent: ToDo? = nil) {
        self.name = name
        self.isCompleted = isCompleted
        self.parent = parent
    }
}
