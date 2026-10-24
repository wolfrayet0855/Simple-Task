import Foundation

/// Text that labels a band and a task's distance. Pure, so it is testable.
public enum BandLabel {
    private static func fmt(_ pattern: String, _ date: Date, _ calendar: Calendar) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateFormat = pattern
        return f.string(from: date)
    }

    public static func text(_ band: Band, now: Date, calendar: Calendar = .current) -> String {
        func day(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: now) ?? now }
        switch band {
        case .tomorrow: return "Tomorrow · \(fmt("EEE", day(1), calendar))"
        case .week: return "This week · to \(fmt("EEE d", day(7), calendar))"
        case .month: return "This month · to \(fmt("d MMM", day(31), calendar))"
        case .horizon: return "Beyond"
        case .inHand: return "Today"
        case .slipped: return "Slipped"
        case .shelf: return "Shelf"
        case .cairn: return "Cairn"
        }
    }

    /// Short stamp at a chip's trailing edge: time for tomorrow, weekday for the week, day and month beyond.
    public static func stamp(for due: Date, band: Band, calendar: Calendar = .current) -> String {
        switch band {
        case .tomorrow: return fmt("h:mm a", due, calendar)
        case .week: return fmt("EEE", due, calendar)
        default: return fmt("d MMM", due, calendar)
        }
    }

    /// "in 1h 26m", "in 12m", "now", or "40m ago".
    public static func countdown(to due: Date, now: Date) -> String {
        let minutes = Int((due.timeIntervalSince(now) / 60).rounded())
        if minutes == 0 { return "now" }
        let n = abs(minutes)
        let span = n >= 60 ? (n % 60 == 0 ? "\(n / 60)h" : "\(n / 60)h \(n % 60)m") : "\(n)m"
        return minutes > 0 ? "in \(span)" : "\(span) ago"
    }
}
