import Foundation

/// What the Next widget shows: the ember task, the stone count, and when to look again.
public struct NextEntry: Equatable, Sendable {
    public let date: Date
    public let task: TaskSnapshot?
    public let stones: Int
    public let refreshAt: Date
}

public func nextEntry(from tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) -> NextEntry {
    let stones = tasks.filter(\.isDone).count
    let model = HorizonModel.build(tasks, cairnTotal: stones, now: now, calendar: calendar)
    let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
    var refresh = midnight
    if let due = model.ember?.due, due > now { refresh = min(refresh, due) }
    return NextEntry(date: now, task: model.ember, stones: stones, refreshAt: refresh)
}
