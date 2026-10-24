import Foundation
import SwiftData

public enum Completion {
    public static let undoWindow: TimeInterval = 5

    /// Marks the task done and returns the new Cairn total. Completing again changes nothing.
    @discardableResult
    public static func complete(_ task: ToDo, in context: ModelContext, now: Date = .now) throws -> Int {
        if !task.isCompleted {
            task.isCompleted = true
            task.completedAt = now
            task.stateRaw = "done"
            task.modifiedAt = now
            try context.save()
        }
        return try cairnTotal(in: context)
    }

    /// Reopens a task completed within the last 5 seconds. Returns false when the window has passed.
    @discardableResult
    public static func undo(_ task: ToDo, in context: ModelContext, now: Date = .now) throws -> Bool {
        guard task.isCompleted, let at = task.completedAt, now.timeIntervalSince(at) <= undoWindow else { return false }
        task.isCompleted = false
        task.completedAt = nil
        task.stateRaw = "active"
        task.modifiedAt = now
        try context.save()
        return true
    }

    public static func cairnTotal(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<ToDo>(predicate: #Predicate { $0.isCompleted }))
    }
}
