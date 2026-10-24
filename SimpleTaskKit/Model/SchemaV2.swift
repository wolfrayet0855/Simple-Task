import Foundation
import SwiftData

/// CloudKit-safe: UUID ids, no unique constraints, defaults everywhere, optional relationships.
public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [ToDo.self, SubTask.self, Tag.self, Landmark.self, Witness.self, Pledge.self]
    }

    @Model
    public final class ToDo {
        public var id = UUID()
        public var item = ""
        public var notes = ""
        public var dueDate = Date()
        public var isDated = true
        public var isAllDay = false
        public var reminderIsOn = false
        public var reminderDate = Date()
        public var isCompleted = false
        public var completedAt: Date? = nil
        public var createdAt = Date()
        public var modifiedAt = Date()
        public var stateRaw = "active"          // active | inHand | shelved | done
        public var weightRaw = "M"              // S | M | L
        public var estimateMinutes: Int? = nil
        public var actualMinutes: Int? = nil
        public var cueKindRaw = "none"          // none | time | place | after
        public var cueText = ""
        public var cuePlaceCategory: String? = nil
        public var offsetDays: Int? = nil       // T-minus on a trail
        public var recurrenceRaw: String? = nil
        public var category = "Work"            // legacy, kept for a lossless round trip
        public var calendarItemID: String? = nil
        @Relationship(deleteRule: .cascade, inverse: \SubTask.parent) public var subtasks: [SubTask]? = []
        public var tag: Tag? = nil
        public var landmark: Landmark? = nil
        public var pledge: Pledge? = nil

        public var notificationID: String { "task.\(id.uuidString).reminder" }

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
        public var id = UUID()
        public var name = ""
        public var isCompleted = false
        public var order = 0
        public var parent: ToDo? = nil

        public init(name: String = "", isCompleted: Bool = false, parent: ToDo? = nil) {
            self.name = name
            self.isCompleted = isCompleted
            self.parent = parent
        }
    }

    @Model
    public final class Tag {
        public var id = UUID()
        public var name = ""
        public var colorToken = "tag.1"
        public var order = 0
        @Relationship(deleteRule: .nullify, inverse: \ToDo.tag) public var tasks: [ToDo]? = []

        public init(name: String = "", colorToken: String = "tag.1", order: Int = 0) {
            self.name = name
            self.colorToken = colorToken
            self.order = order
        }
    }

    @Model
    public final class Landmark {
        public var id = UUID()
        public var title = ""
        public var date = Date()
        public var endDate: Date? = nil
        public var isAllDay = true
        public var location = ""
        public var bufferDays = 1
        public var templateRaw = "custom"
        public var runOfShowJSON: Data? = nil
        public var calendarEventID: String? = nil
        @Relationship(deleteRule: .nullify, inverse: \ToDo.landmark) public var tasks: [ToDo]? = []

        public init(title: String = "", date: Date = Date()) {
            self.title = title
            self.date = date
        }
    }

    @Model
    public final class Witness {
        public var id = UUID()
        public var displayName = ""
        public var contactID: String? = nil
        public var isSelf = false
        @Relationship(deleteRule: .nullify, inverse: \Pledge.witness) public var pledges: [Pledge]? = []

        public init(displayName: String = "", isSelf: Bool = false) {
            self.displayName = displayName
            self.isSelf = isSelf
        }
    }

    @Model
    public final class Pledge {
        public var id = UUID()
        public var statement = ""
        public var byDate = Date()
        public var stateRaw = "open"            // open | kept | renegotiated | released
        public var toldAt: Date? = nil
        public var resolvedAt: Date? = nil
        public var note = ""
        public var witness: Witness? = nil
        @Relationship(inverse: \ToDo.pledge) public var task: ToDo? = nil

        public init(statement: String = "", byDate: Date = Date()) {
            self.statement = statement
            self.byDate = byDate
        }
    }
}
