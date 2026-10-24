import Foundation
import SwiftData

public enum Store {
    public static var defaultStoreURL: URL {
        let dir = AppGroup.containerURL()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("SimpleTask.store")
    }

    /// Shared by the app, widgets and intents.
    public static func makeContainer(storeURL: URL? = nil, inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            config = ModelConfiguration(
                schema: schema,
                url: storeURL ?? defaultStoreURL,
                cloudKitDatabase: Features.cloudSync ? .private(Features.cloudContainer) : .none)
        }
        let container = try ModelContainer(for: schema, migrationPlan: SimpleTaskMigrationPlan.self,
                                           configurations: config)
        return container
    }

    /// Run at launch: one row per `id`, latest `modifiedAt` wins, completion is never undone by an older write.
    public static func reconcile(context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<ToDo>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]))
        var kept: [UUID: ToDo] = [:]
        for task in all {
            if let winner = kept[task.id] {
                if task.isCompleted && !winner.isCompleted {
                    winner.isCompleted = true
                    winner.completedAt = task.completedAt
                    winner.stateRaw = "done"
                }
                context.delete(task)
            } else {
                kept[task.id] = task
            }
        }
        try context.save()
    }
}
