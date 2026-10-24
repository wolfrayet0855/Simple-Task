
import Foundation
import SwiftData

@Model
class ToDo: Identifiable {
    @Attribute(.unique) var item = ""
    var reminderIsOn = false
    var dueDate = Date() // Changed default from Date().addingTimeInterval(60*60*24) to Date()
    var reminderDate = Date() // Changed default from Date().addingTimeInterval(60*60*24) to Date()
    var isCompleted = false
    var isAllDay = false
    var category: String = "Work" // Managed via the category picker in DetailView.
    @Relationship(inverse: \SubTask.parent) var subtasks: [SubTask] = []

    init(item: String = "",
         reminderIsOn: Bool = false,
         dueDate: Date = Date(), // Updated default value here as well.
         reminderDate: Date = Date(), // Updated default value here as well.
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

import Combine
class CategoryManager: ObservableObject {
    @Published var categories: [String] = ["Work", "Personal", "Fitness", "Shopping", "Other"]
}

