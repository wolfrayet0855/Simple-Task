import Foundation

public enum SkyKey: CaseIterable, Sendable {
    case night, dawn, day, golden, dusk

    /// Top and horizon colours, light then dark mode.
    public var top: Palette.Pair {
        switch self {
        case .night: (0xCBD3E6, 0x070B14)
        case .dawn: (0xDCE3F0, 0x111A2C)
        case .day: (0xD6E6F7, 0x0E1626)
        case .golden: (0xE4E2EE, 0x15162A)
        case .dusk: (0xD9D3E6, 0x120F22)
        }
    }
    public var glow: Palette.Pair {
        switch self {
        case .night: (0xEDE9F0, 0x141A2A)
        case .dawn: (0xF8DCCB, 0x3A2A2E)
        case .day: (0xF3F6F8, 0x1B2536)
        case .golden: (0xF7E1C4, 0x3A2B22)
        case .dusk: (0xF2D6D0, 0x2E1E2E)
        }
    }
}

/// The sky follows local time, with no SwiftUI so it can be tested.
public enum Sky {
    private static let anchors: [(hour: Double, key: SkyKey)] = [
        (4.5, .night), (6, .dawn), (8, .day), (16.5, .day), (18, .golden), (19.5, .dusk), (21, .night),
    ]

    static func hour(_ date: Date, _ calendar: Calendar) -> Double {
        Double(calendar.component(.hour, from: date)) + Double(calendar.component(.minute, from: date)) / 60
    }

    public static func keyframes(at date: Date, calendar: Calendar = .current) -> (from: SkyKey, to: SkyKey, t: Double) {
        let h = hour(date, calendar)
        if h < anchors[0].hour || h >= anchors[anchors.count - 1].hour { return (.night, .night, 0) }
        for i in 0..<(anchors.count - 1) where h >= anchors[i].hour && h < anchors[i + 1].hour {
            let (a, b) = (anchors[i], anchors[i + 1])
            return (a.key, b.key, (h - a.hour) / (b.hour - a.hour))
        }
        return (.night, .night, 0)
    }

    /// 0…1 across 06:00–20:00, nil at night.
    public static func sunPosition(at date: Date, calendar: Calendar = .current) -> Double? {
        let h = hour(date, calendar)
        guard h >= 6, h <= 20 else { return nil }
        return (h - 6) / 14
    }
}
