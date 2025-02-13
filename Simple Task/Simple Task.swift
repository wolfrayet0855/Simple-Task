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
    var notes = ""
    var isCompleted = false
    var isAllDay = false
    @Relationship(inverse: \SubTask.parent) var subtasks: [SubTask] = []

    init(item: String = "",
         reminderIsOn: Bool = false,
         dueDate: Date = Date().addingTimeInterval(60*60*24),
         notes: String = "",
         isCompleted: Bool = false,
         isAllDay: Bool = false) {
        self.item = item
        self.reminderIsOn = reminderIsOn
        self.dueDate = dueDate
        self.notes = notes
        self.isCompleted = isCompleted
        self.isAllDay = isAllDay
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

