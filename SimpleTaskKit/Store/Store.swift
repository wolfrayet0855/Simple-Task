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

    /// Run at launch. Only exact duplicates (same id, title and creation time) are merged, keeping the latest
    /// write and never reopening a completed task. Rows that merely share an id (a half-finished migration
    /// leaves every row with one id) get fresh ids: losing nothing beats tidiness.
    public static func reconcile(context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<ToDo>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]))
        var seen: [UUID: [ToDo]] = [:]
        for task in all {
            guard let group = seen[task.id] else { seen[task.id] = [task]; continue }
            if let winner = group.first(where: { $0.item == task.item && $0.createdAt == task.createdAt }) {
                if task.isCompleted && !winner.isCompleted {
                    winner.isCompleted = true
                    winner.completedAt = task.completedAt
                    winner.stateRaw = "done"
                }
                context.delete(task)
            } else {
                task.id = UUID()
                seen[task.id] = [task]
            }
        }
        try context.save()
    }

    /// False while a legacy store still waits to be relocated; widgets and intents must not open the store then.
    public static func isReady(defaults: UserDefaults = Store.groupDefaults,
                               legacyURL: URL = Store.legacyStoreURL) -> Bool {
        defaults.string(forKey: locationKey) == "group" || !FileManager.default.fileExists(atPath: legacyURL.path)
    }
}
