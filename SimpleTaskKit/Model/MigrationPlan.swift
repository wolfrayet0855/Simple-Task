import Foundation
import SwiftData

public enum SimpleTaskMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    public static var stages: [MigrationStage] { [v1ToV2] }

    public static let defaultTags = ["Work", "Personal", "Fitness", "Shopping", "Other"]

    private struct Snapshot { var category: String; var subtaskNames: [String] }
    // Array order does not survive the move to an optional relationship, so capture it first.
    private static var snapshots: [String: Snapshot] = [:]

    static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            snapshots = [:]
            for task in try context.fetch(FetchDescriptor<SchemaV1.ToDo>()) {
                snapshots[task.item] = Snapshot(category: task.category, subtaskNames: [])
            }
            // The relationship array has no stable order; a plain fetch walks rows in insertion order.
            for sub in try context.fetch(FetchDescriptor<SchemaV1.SubTask>()) {
                if let parent = sub.parent?.item { snapshots[parent]?.subtaskNames.append(sub.name) }
            }
        },
        didMigrate: { context in
            let now = Date()
            var tags: [String: Tag] = [:]
            func tag(named name: String) -> Tag {
                if let t = tags[name] { return t }
                let t = Tag(name: name, colorToken: "tag.\(tags.count % 8 + 1)", order: tags.count)
                context.insert(t)
                tags[name] = t
                return t
            }
            defaultTags.forEach { _ = tag(named: $0) }

            for task in try context.fetch(FetchDescriptor<ToDo>()) {
                let snap = snapshots[task.item]
                task.id = UUID()
                task.createdAt = now
                task.modifiedAt = now
                task.completedAt = task.isCompleted ? task.dueDate : nil
                task.stateRaw = task.isCompleted ? "done" : "active"
                let category = (snap?.category ?? task.category).trimmingCharacters(in: .whitespaces)
                task.tag = tag(named: category.isEmpty ? "Other" : category)

                let names = snap?.subtaskNames ?? []
                var used = Set<Int>()
                for (fallback, sub) in (task.subtasks ?? []).enumerated() {
                    sub.id = UUID()
                    if let i = names.indices.first(where: { names[$0] == sub.name && !used.contains($0) }) {
                        used.insert(i)
                        sub.order = i
                    } else {
                        sub.order = fallback
                    }
                }
            }
            try context.save()
            snapshots = [:]
        }
    )
}
