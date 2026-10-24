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

        try fm.createDirectory(at: groupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        removeStoreFiles(at: groupURL)   // partial copy from an interrupted run

        let expected = try legacyRowCount(at: legacyURL)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        try coordinator.replacePersistentStore(
            at: groupURL, destinationOptions: nil,
            withPersistentStoreFrom: legacyURL, sourceOptions: nil, type: .sqlite)

        let got = try ModelContext(try makeContainer(storeURL: groupURL)).fetchCount(FetchDescriptor<ToDo>())
        guard got == expected else {
            removeStoreFiles(at: groupURL)
            throw RelocationError.rowCountMismatch(expected: expected, got: got)
        }
        removeStoreFiles(at: legacyURL)
        defaults.set("group", forKey: locationKey)
        return .moved(rows: got)
    }

    private static func legacyRowCount(at url: URL) throws -> Int {
        let container = try ModelContainer(
            for: SchemaV1.ToDo.self, SchemaV1.SubTask.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        return try ModelContext(container).fetchCount(FetchDescriptor<SchemaV1.ToDo>())
    }

    private static func removeStoreFiles(at url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + suffix)
        }
    }

    /// App entry point: relocate, open (migrating if needed), reconcile.
    public static func bootstrap() throws -> ModelContainer {
        _ = try relocateIfNeeded(legacyURL: legacyStoreURL, groupURL: defaultStoreURL)
        let container = try makeContainer()
        try reconcile(context: ModelContext(container))
        return container
    }
}
