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

    private static func extractDate(from text: inout String, now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        var dayOffset: Int?
        var defaultHour = 9
        var instant: Date?

        if let rel = extract(#"(?<![\p{L}])in (\d+) ?(days?|weeks?|hours?|hrs?|h|d|w)(?![\p{L}])"#, from: &text, group: 0) {
            let n = Int(rel.filter(\.isNumber)) ?? 0
            let unit = rel.drop { !$0.isLetter }
            if unit.hasPrefix("h") { instant = calendar.date(byAdding: .hour, value: n, to: now) }
            else { dayOffset = unit.hasPrefix("w") ? 7 * n : n }
        } else if let word = extract(#"(?<![\p{L}])(today|tonight|tomorrow|tmrw|mon(?:day)?|tue(?:s|sday)?|wed(?:nesday)?|thu(?:r|rs|rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)(?![\p{L}])"#,
                                      from: &text, group: 1)?.lowercased() {
            switch word {
            case "today": dayOffset = 0
            case "tonight": dayOffset = 0; defaultHour = 20
            case "tomorrow", "tmrw": dayOffset = 1
            default:
                if let target = weekdays.firstIndex(where: { word.hasPrefix($0) }) {
                    let current = calendar.component(.weekday, from: now) - 1
                    let delta = (target - current + 7) % 7
                    dayOffset = delta == 0 ? 7 : delta
                }
            }
        }

        var time: (hour: Int, minute: Int)?
        if let t = extract(#"(?<![\p{L}\d:])(\d{1,2})(?::(\d{2}))?\s?(am|pm)(?![\p{L}])"#, from: &text, group: 0) {
            let digits = t.lowercased().split(whereSeparator: { !$0.isNumber })
            var hour = Int(digits[0]) ?? 0
            let minute = digits.count > 1 ? Int(digits[1]) ?? 0 : 0
            if hour == 12 { hour = 0 }
            if t.lowercased().contains("pm") { hour += 12 }
            time = (hour % 24, minute)
        } else if let t = extract(#"(?<![\d:])([01]?\d|2[0-3]):([0-5]\d)(?!\d)"#, from: &text, group: 0) {
            let parts = t.split(separator: ":").compactMap { Int($0) }
            time = (parts[0], parts[1])
        }

        if let instant { return instant }
        if dayOffset == nil, let time {
            let candidate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today)!
            return candidate > now ? candidate : calendar.date(byAdding: .day, value: 1, to: candidate)
        }
        if let dayOffset {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let (h, m) = time ?? (defaultHour, 0)
            return calendar.date(bySettingHour: h, minute: m, second: 0, of: day)
        }
        return detectExplicitDate(in: &text)
    }

    private static func detectExplicitDate(in text: inout String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let ns = text as NSString
        guard let match = detector.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              let date = match.date,
              ns.substring(with: match.range).contains(where: \.isNumber) else { return nil }
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
}
