import Foundation

public struct ParsedCapture: Equatable, Sendable {
    public var title: String
    public var due: Date?
    public var tag: String?
    public var witness: String?
    public var landmark: String?

    public init(title: String, due: Date? = nil, tag: String? = nil, witness: String? = nil, landmark: String? = nil) {
        self.title = title; self.due = due; self.tag = tag; self.witness = witness; self.landmark = landmark
    }
}

/// Rules-based. A deterministic date grammar runs first (it is testable against a fixed `now`);
/// `NSDataDetector` is only a fallback for explicit dates such as "Dec 14".
public enum CaptureParser {
    public static func parse(_ input: String, now: Date, calendar: Calendar) -> ParsedCapture? {
        var text = " " + input + " "
        var result = ParsedCapture(title: "")

        for (sigil, keyPath) in [("#", \ParsedCapture.tag), ("@", \.witness), ("^", \.landmark)] {
            let escaped = NSRegularExpression.escapedPattern(for: sigil)
            if let word = extract("(?<!\\S)" + escaped + #"([\p{L}\p{N}_\-]+)"#, from: &text, group: 1) {
                result[keyPath: keyPath] = word
            }
        }
        while extract(#"(?<!\S)[#@^]+(?=\s)"#, from: &text, group: 0) != nil {}   // stray sigils

        result.due = extractDate(from: &text, now: now, calendar: calendar)
        result.title = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return result.title.isEmpty ? nil : result
    }

    // MARK: - Dates

    private static let weekdays = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
    private static let shortDay = "mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun"
    private static let longDay = "monday|tuesday|wednesday|thursday|friday|saturday|sunday"
    private static let time12 = #"(1[0-2]|0?[1-9])(?::([0-5]\d))?\s?(am|pm)(?![\p{L}])"#
    private static let time24 = #"([01]?\d|2[0-3]):([0-5]\d)(?!\d)"#

    private static func extractDate(from text: inout String, now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        var dayOffset: Int?
        var defaultHour = 9
        var instant: Date?

        if let g = extractGroups(#"(?<![\p{L}])in (\d+) ?(days?|weeks?|hours?|hrs?|h|d|w)(?![\p{L}])"#, from: &text) {
            let n = min(Int(g[0]) ?? 3650, 3650)
            if g[1].lowercased().hasPrefix("h") { instant = calendar.date(byAdding: .hour, value: n, to: now) }
            else { dayOffset = g[1].lowercased().hasPrefix("w") ? 7 * n : n }
        } else if let g = extractGroups(#"(?<![\p{L}])(today|tonight|tomorrow|tmrw)(?![\p{L}])"#, from: &text) {
            switch g[0].lowercased() {
            case "today": dayOffset = 0
            case "tonight": dayOffset = 0; defaultHour = 20
            default: dayOffset = 1
            }
        } else if let word = weekdayWord(in: &text) {
            if let target = weekdays.firstIndex(where: { word.hasPrefix($0) }) {
                let current = calendar.component(.weekday, from: now) - 1
                let delta = (target - current + 7) % 7
                dayOffset = delta == 0 ? 7 : delta
            }
        }

        var time: (hour: Int, minute: Int)?
        if let g = extractGroups(#"(?:(?<![\p{L}])(?:at|by)\s+)?(?<![\p{L}\d:])"# + time12, from: &text) {
            var hour = Int(g[0]) ?? 0
            if hour == 12 { hour = 0 }
            if g[2].lowercased() == "pm" { hour += 12 }
            time = (hour, Int(g[1]) ?? 0)
        } else if let g = extractGroups(#"(?:(?<![\p{L}])(?:at|by)\s+)?(?<![\d:])"# + time24, from: &text) {
            time = (Int(g[0]) ?? 0, Int(g[1]) ?? 0)
        }

        if let instant { return instant }
        if dayOffset == nil, let time {
            guard let candidate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) else { return nil }
            return candidate > now ? candidate : calendar.date(byAdding: .day, value: 1, to: candidate)
        }
        if let dayOffset {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            let (h, m) = time ?? (defaultHour, 0)
            return calendar.date(bySettingHour: h, minute: m, second: 0, of: day)
        }
        return detectExplicitDate(in: &text)
    }

    /// A full weekday name, a short one after "on"/"next", or a short one right before a time.
    /// Bare "sun", "sat" or "wed" stay words ("sun cream", "I sat down").
    private static func weekdayWord(in text: inout String) -> String? {
        let patterns = [
            #"(?<![\p{L}])(?:on|next)\s+("# + longDay + "|" + shortDay + #")(?![\p{L}])"#,
            #"(?<![\p{L}])(?:on\s+)?("# + longDay + #")(?![\p{L}])"#,
            #"(?<![\p{L}])("# + shortDay + #")(?=\s+(?:\d{1,2}(?::\d{2})?\s?(?:am|pm)|\d{1,2}:\d{2}))"#,
        ]
        for pattern in patterns {
            if let g = extractGroups(pattern, from: &text) { return g[0].lowercased() }
        }
        return nil
    }

    private static func detectExplicitDate(in text: inout String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let ns = text as NSString
        guard let match = detector.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              let date = match.date else { return nil }
        let matched = ns.substring(with: match.range)
        let months = "jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec"
        let explicit = #"\d{1,2}[/.-]\d{1,2}|(?:"# + months + #")[a-z]*\.?\s+\d{1,2}|\d{1,2}\s+(?:"# + months + ")"
        guard matched.range(of: explicit, options: [.regularExpression, .caseInsensitive]) != nil else { return nil }
        text = ns.replacingCharacters(in: match.range, with: " ")
        return date
    }

    // MARK: - Regex helper

    /// Returns the requested group of the first match and blanks the whole match out of `text`.
    private static func extract(_ pattern: String, from text: inout String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let value = ns.substring(with: m.range(at: group))
        text = ns.replacingCharacters(in: m.range, with: " ")
        return value
    }

    /// Like `extract`, but returns every capture group ("" for groups that did not participate).
    private static func extractGroups(_ pattern: String, from text: inout String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let groups = (1..<max(m.numberOfRanges, 1)).map { i -> String in
            let r = m.range(at: i)
            return r.location == NSNotFound ? "" : ns.substring(with: r)
        }
        text = ns.replacingCharacters(in: m.range, with: " ")
        return groups
    }
}
