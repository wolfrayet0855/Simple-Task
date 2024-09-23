//  Simple TaskViewModel.swift
//  Simple Task
//
//  Created by user on 9/14/24.

import Foundation
import SwiftData

@Model
class ToDo {
    @Attribute(.unique) var item = ""
    var reminderIsOn = false
    var dueDate = Date.now + (60*60*24)
    var notes = ""
    var isCompleted = false

    init(item: String = "", reminderIsOn: Bool = false, dueDate: Date = .now + (60*60*24), notes: String = "", isCompleted: Bool = false) {
        if item.isEmpty {
            print("Error: Item cannot be empty")
            return
        }
        self.item = item
        self.reminderIsOn = reminderIsOn
        self.dueDate = dueDate
        self.notes = notes
        self.isCompleted = isCompleted
        print("Initialized ToDo with item: \(item), Reminder: \(reminderIsOn), Due Date: \(dueDate), Notes: \(notes), Completed: \(isCompleted)")
    }
}
