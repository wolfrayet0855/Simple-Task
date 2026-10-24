import Foundation
import SwiftData

public enum TaskError: LocalizedError, Equatable {
    case notFound
    case storeNotReady
    public var errorDescription: String? {
        switch self {
        case .notFound: "That task isn't here anymore."
        case .storeNotReady: "Open the app once to finish updating your tasks."
        }
    }
}

/// The work behind the intents and the widget, kept free of AppIntents types so it can be tested.
public enum TaskActions {
    public static func makeContext() throws -> ModelContext {
        guard Store.isReady() else { throw TaskError.storeNotReady }
        return ModelContext(try Store.makeContainer())
    }

    static func task(id: UUID, in context: ModelContext) throws -> ToDo {
        var descriptor = FetchDescriptor<ToDo>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let task = try context.fetch(descriptor).first else { throw TaskError.notFound }
        return task
    }

    /// Finishes the task and returns the new Cairn total ("stone number").
    public static func complete(id: UUID, in context: ModelContext, now: Date = .now) throws -> Int {
        try Completion.complete(try task(id: id, in: context), in: context, now: now)
    }

    public static func snapshots(in context: ModelContext) throws -> [TaskSnapshot] {
        try context.fetch(FetchDescriptor<ToDo>()).map(TaskSnapshot.init)
    }

    public static func inHand(in context: ModelContext, now: Date = .now,
                              calendar: Calendar = .current) throws -> [TaskEntity] {
        let model = HorizonModel.build(try snapshots(in: context), cairnTotal: 0, now: now, calendar: calendar)
        let ids = Set((model.groups[.inHand]?.visible ?? []).map(\.id))
        return try context.fetch(FetchDescriptor<ToDo>())
            .filter { ids.contains($0.id) }
            .sorted { ($0.isDated ? $0.dueDate : .distantFuture) < ($1.isDated ? $1.dueDate : .distantFuture) }
            .map(TaskEntity.init)
    }
}
