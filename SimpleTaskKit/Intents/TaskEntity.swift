import AppIntents
import Foundation
import SwiftData

public struct TaskEntity: AppEntity, IndexedEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")
    public static let defaultQuery = TaskQuery()

    public var id: UUID
    @Property(title: "Title") public var title: String
    @Property(title: "Due") public var due: Date?
    @Property(title: "Done") public var isDone: Bool

    public var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }

    public init(id: UUID, title: String, due: Date?, isDone: Bool) {
        self.id = id
        self.title = title
        self.due = due
        self.isDone = isDone
    }

    public init(_ task: ToDo) {
        self.init(id: task.id, title: task.item, due: task.isDated ? task.dueDate : nil, isDone: task.isCompleted)
    }

    public init(_ snapshot: TaskSnapshot) {
        self.init(id: snapshot.id, title: snapshot.title, due: snapshot.due, isDone: snapshot.isDone)
    }
}

public struct TaskQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        let ids = Set(identifiers)
        return try TaskActions.makeContext().fetch(FetchDescriptor<ToDo>())
            .filter { ids.contains($0.id) }.map(TaskEntity.init)
    }

    public func entities(matching string: String) async throws -> [TaskEntity] {
        try TaskActions.makeContext().fetch(FetchDescriptor<ToDo>())
            .filter { !$0.isCompleted && $0.item.localizedCaseInsensitiveContains(string) }
            .prefix(20).map(TaskEntity.init)
    }

    public func suggestedEntities() async throws -> [TaskEntity] {
        try TaskActions.inHand(in: try TaskActions.makeContext())
    }
}
