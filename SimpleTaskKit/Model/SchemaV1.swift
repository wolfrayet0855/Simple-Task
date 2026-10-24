import Foundation
import SwiftData

/// Verbatim copy of the shipped model. Never edit: it describes stores already on devices.
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    public static var models: [any PersistentModel.Type] { [ToDo.self, SubTask.self] }

    @Model
    public final class ToDo {
        @Attribute(.unique) public var item = ""
        public var reminderIsOn = false
        public var dueDate = Date()
        public var reminderDate = Date()
        public var isCompleted = false
        public var isAllDay = false
        public var category: String = "Work"
        @Relationship(inverse: \SubTask.parent) public var subtasks: [SubTask] = []

        public init(item: String = "", reminderIsOn: Bool = false, dueDate: Date = Date(),
                    reminderDate: Date = Date(), isCompleted: Bool = false,
                    isAllDay: Bool = false, category: String = "Work") {
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
    public final class SubTask {
        public var name: String
        public var isCompleted: Bool
        @Relationship public var parent: ToDo?

        public init(name: String = "", isCompleted: Bool = false, parent: ToDo? = nil) {
            self.name = name
            self.isCompleted = isCompleted
            self.parent = parent
        }
    }
}
