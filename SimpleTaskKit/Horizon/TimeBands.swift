import Foundation
import CoreGraphics

public enum Band: Hashable, CaseIterable {
    case cairn, inHand, tomorrow, week, month, horizon
    case slipped, shelf   // outside the vertical field: left edge, and the pinch-out Shelf

    /// Fractions of screen height measured from the bottom.
    public static let fractions: [Band: ClosedRange<Double>] = [
        .cairn: 0...0.06, .inHand: 0.06...0.46, .tomorrow: 0.46...0.60,
        .week: 0.60...0.76, .month: 0.76...0.92, .horizon: 0.92...1.0,
    ]
}

public enum Weight: String, Sendable {
    case S, M, L

    public init(raw: String) { self = Weight(rawValue: raw) ?? .M }

    public var height: CGFloat {
        switch self { case .S: 56; case .M: 72; case .L: 96 }
    }
}

public struct TaskSnapshot: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let due: Date?
    public let weight: Weight
    public let isDone: Bool
    public let isShelved: Bool

    public init(id: UUID, title: String, due: Date?, weight: Weight, isDone: Bool, isShelved: Bool = false) {
        self.id = id; self.title = title; self.due = due
        self.weight = weight; self.isDone = isDone; self.isShelved = isShelved
    }

    public init(_ task: ToDo) {
        self.init(id: task.id, title: task.item, due: task.isDated ? task.dueDate : nil,
                  weight: Weight(raw: task.weightRaw), isDone: task.isCompleted,
                  isShelved: task.stateRaw == "shelved")
    }
}

public enum TimeBands {
    public static func band(for task: TaskSnapshot, now: Date, calendar: Calendar) -> Band {
        if task.isDone { return .cairn }
        if task.isShelved { return .shelf }
        guard let due = task.due else { return .inHand }
        let days = dayOffset(from: now, to: due, calendar: calendar)
        switch days {
        case ..<(-7): return .shelf
        case ..<0: return .slipped
        case 0: return .inHand
        case 1: return .tomorrow
        case 2...7: return .week
        case 8...31: return .month
        default: return .horizon
        }
    }

    public static func isSlipped(_ task: TaskSnapshot, now: Date, calendar: Calendar) -> Bool {
        guard !task.isDone, let due = task.due else { return false }
        return dayOffset(from: now, to: due, calendar: calendar) < 0
    }

    public static func scale(depth: Double) -> Double { max(0.45, 1 - 0.6 * depth) }

    public static func caps(_ band: Band) -> Int {
        switch band {
        case .inHand: 5
        case .tomorrow: 4
        case .week, .month: 6
        case .horizon: 4
        case .cairn, .slipped, .shelf: Int.max
        }
    }

    /// 0 at the band's near (bottom) edge, 1 at its far edge; linear in time within the band.
    public static func position(for task: TaskSnapshot, now: Date, calendar: Calendar) -> Double {
        guard let due = task.due else { return 0 }
        let days = Double(dayOffset(from: now, to: due, calendar: calendar))
        let start = calendar.startOfDay(for: due)
        let dayFraction = due.timeIntervalSince(start) / 86_400
        let t = days + dayFraction
        let (from, length): (Double, Double)
        switch band(for: task, now: now, calendar: calendar) {
        case .inHand: return dayFraction
        case .tomorrow: (from, length) = (1, 1)
        case .week: (from, length) = (2, 6)
        case .month: (from, length) = (8, 24)
        case .horizon: (from, length) = (32, 60)
        case .cairn, .slipped, .shelf: return 0
        }
        return min(1, max(0, (t - from) / length))
    }

    public static func dayOffset(from now: Date, to due: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                to: calendar.startOfDay(for: due)).day ?? 0
    }
}
