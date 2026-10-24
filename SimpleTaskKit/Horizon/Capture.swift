import Foundation
import SwiftData

public enum Capture {
    /// Turns a parsed capture into a task. An undated task lands In Hand; a witness creates an open pledge.
    @discardableResult
    public static func insert(_ parsed: ParsedCapture, in context: ModelContext,
                              now: Date = .now, calendar: Calendar = .current) throws -> ToDo {
        let task = ToDo(item: parsed.title, reminderIsOn: false)
        task.createdAt = now
        task.modifiedAt = now
        task.isDated = parsed.due != nil
        task.dueDate = parsed.due ?? now
        task.stateRaw = parsed.due == nil ? "inHand" : "active"
        context.insert(task)

        if let name = parsed.tag {
            let tag = try find(SchemaV2.Tag.self, in: context) { $0.name.caseInsensitiveCompare(name) == .orderedSame }
                ?? make(SchemaV2.Tag(name: name, colorToken: "tag.\(Int.random(in: 1...8))"), in: context)
            task.tag = tag
            task.category = tag.name
        }
        if let name = parsed.landmark {
            task.landmark = try find(Landmark.self, in: context) { $0.title.caseInsensitiveCompare(name) == .orderedSame }
                ?? make(Landmark(title: name, date: parsed.due ?? now), in: context)
        }
        if let name = parsed.witness {
            let witness = try find(Witness.self, in: context) { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }
                ?? make(Witness(displayName: name), in: context)
            let pledge = Pledge(statement: parsed.title, byDate: parsed.due ?? now)
            context.insert(pledge)
            pledge.witness = witness
            task.pledge = pledge
        }
        try context.save()
        return task
    }

    private static func find<T: PersistentModel>(_ type: T.Type, in context: ModelContext,
                                                 where match: (T) -> Bool) throws -> T? {
        try context.fetch(FetchDescriptor<T>()).first(where: match)
    }

    private static func make<T: PersistentModel>(_ model: T, in context: ModelContext) -> T {
        context.insert(model)
        return model
    }
}
