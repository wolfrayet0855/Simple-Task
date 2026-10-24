import Foundation
import CoreData
import SwiftData

public enum RelocationResult: Equatable {
    case alreadyDone
    case moved(rows: Int)
    case nothingToMove
}

public enum RelocationError: Error { case rowCountMismatch(expected: Int, got: Int) }

extension Store {
    static let locationKey = "storeLocation"

    public static var legacyStoreURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("default.store")
    }

    public static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }

    /// Copies the shipped store into the shared location (WAL-safe), verifies row counts, and only then
    /// deletes the legacy files. Safe to call on every launch and after a crash mid-copy.
    public static func relocateIfNeeded(
        legacyURL: URL, groupURL: URL, defaults: UserDefaults = Store.groupDefaults
    ) throws -> RelocationResult {
        if defaults.string(forKey: locationKey) == "group" { return .alreadyDone }
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyURL.path) else { return .nothingToMove }

        let dir = groupURL.deletingLastPathComponent()
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let staging = dir.appendingPathComponent("SimpleTask.migrating.store")
        removeStoreFiles(at: staging)   // leftovers from an interrupted run

        let expected = try legacyCounts(at: legacyURL)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        try coordinator.replacePersistentStore(
            at: staging, destinationOptions: nil,
            withPersistentStoreFrom: legacyURL, sourceOptions: nil, type: .sqlite)

        // Migrate and verify in the staging file; the real location only ever sees a finished store.
        let got: (tasks: Int, subtasks: Int)
        do {
            let context = ModelContext(try makeContainer(storeURL: staging))
            let real = (try context.fetchCount(FetchDescriptor<ToDo>()), try context.fetchCount(FetchDescriptor<SubTask>()))
            got = relocationCountsOverride ?? real
        }
        guard got == expected else {
            removeStoreFiles(at: staging)
            throw RelocationError.rowCountMismatch(expected: expected.tasks, got: got.tasks)
        }
        removeStoreFiles(at: groupURL)   // partial copy from an older interrupted run
        for suffix in ["", "-wal", "-shm"] where fm.fileExists(atPath: staging.path + suffix) {
            try fm.moveItem(atPath: staging.path + suffix, toPath: groupURL.path + suffix)
        }
        removeStoreFiles(at: legacyURL)
        defaults.set("group", forKey: locationKey)
        return .moved(rows: got.tasks)
    }

    private static func legacyCounts(at url: URL) throws -> (tasks: Int, subtasks: Int) {
        let container = try ModelContainer(
            for: SchemaV1.ToDo.self, SchemaV1.SubTask.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let context = ModelContext(container)
        return (try context.fetchCount(FetchDescriptor<SchemaV1.ToDo>()),
                try context.fetchCount(FetchDescriptor<SchemaV1.SubTask>()))
    }

    private static func removeStoreFiles(at url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + suffix)
        }
    }
}
