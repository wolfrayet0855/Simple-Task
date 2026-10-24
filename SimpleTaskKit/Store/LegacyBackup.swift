import Foundation
import SwiftData

public struct LegacyTaskRow: Codable, Equatable, Identifiable {
    public var id: String { title }
    public let title: String
    public let dueDate: Date
    public let isAllDay: Bool
    public let isCompleted: Bool
    public let category: String
    public let subtasks: [String]
}

/// Read-only view of the shipped store, for the recovery screen. Never writes to the file.
public enum LegacyBackup {
    public static func rows(at url: URL = Store.legacyStoreURL) throws -> [LegacyTaskRow] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let container = try ModelContainer(
            for: SchemaV1.ToDo.self, SchemaV1.SubTask.self,
            configurations: ModelConfiguration(url: url, allowsSave: false, cloudKitDatabase: .none))
        let todos = try ModelContext(container).fetch(FetchDescriptor<SchemaV1.ToDo>(sortBy: [SortDescriptor(\.dueDate)]))
        return todos.map { LegacyTaskRow(title: $0.item, dueDate: $0.dueDate, isAllDay: $0.isAllDay,
                                         isCompleted: $0.isCompleted, category: $0.category,
                                         subtasks: $0.subtasks.map(\.name)) }
    }

    public static func json(at url: URL = Store.legacyStoreURL) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(rows(at: url))
    }
}
