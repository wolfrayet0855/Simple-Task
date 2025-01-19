//
//  Simple TaskViewModel.swift
//  Simple Task
//
//  Created by user on 9/14/24.
//

import Foundation
import SwiftData

@Model
class ToDo {
    @Attribute(.unique) var item = ""
    var reminderIsOn = false
    var dueDate = Date.now + (60*60*24)
    var notes = ""
    var isCompleted = false

    // New property to support "All Day"
    var isAllDay = false

    // Use the 'inverse' relationship here, but remove the .cascade option.
    @Relationship(inverse: \SubTask.parent) var subtasks: [SubTask] = []

    init(item: String = "",
         reminderIsOn: Bool = false,
         dueDate: Date = .now + (60*60*24),
         notes: String = "",
         isCompleted: Bool = false,
         isAllDay: Bool = false)  // new parameter
    {
        if item.isEmpty {
            print("Error: Item cannot be empty")
            return
        }
        self.item = item
        self.reminderIsOn = reminderIsOn
        self.dueDate = dueDate
        self.notes = notes
        self.isCompleted = isCompleted
        self.isAllDay = isAllDay  // new assignment
        print("Initialized ToDo with item: \(item), Reminder: \(reminderIsOn), Due Date: \(dueDate), Notes: \(notes), Completed: \(isCompleted), All Day: \(isAllDay)")
    }
}

@Model
class SubTask {
    var name: String
    var isCompleted: Bool

    // No inverse declared here to avoid circular reference errors.
    @Relationship var parent: ToDo?

    init(name: String = "", isCompleted: Bool = false, parent: ToDo? = nil) {
        self.name = name
        self.isCompleted = isCompleted
        self.parent = parent
        print("Initialized SubTask with name: \(name), isCompleted: \(isCompleted)")
    }
}
