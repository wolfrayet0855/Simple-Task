import Foundation

public enum CardTint: CaseIterable, Sendable {
    case ember, landmark, witness, slipped, ink

    public static func tint(band: Band, isEmber: Bool) -> CardTint {
        if band == .slipped { return .slipped }
        return isEmber ? .ember : .ink
    }

    /// Light-mode value of the matching colour token.
    public var hex: UInt32 {
        switch self {
        case .ember: 0xD9712B
        case .landmark: 0x4B4FA8
        case .witness: 0x2F8F8A
        case .slipped: 0x8A93A6
        case .ink: 0x1C1E22
        }
    }

    public var isRed: Bool {
        let r = Double((hex >> 16) & 0xFF) / 255, g = Double((hex >> 8) & 0xFF) / 255, b = Double(hex & 0xFF) / 255
        return r > 0.7 && g < 0.4 && b < 0.4
    }
}

public struct HorizonModel: Equatable {
    public struct Group: Equatable {
        public let band: Band
        public let visible: [TaskSnapshot]
        public let overflow: Int
    }

    public let groups: [Band: Group]
    public let ember: TaskSnapshot?
    public let cairnTotal: Int

    /// True when there is no open work in the field (done tasks live in the Cairn, shelved ones behind the Shelf).
    public var isEmpty: Bool { groups.filter { $0.key != .shelf }.values.allSatisfy { $0.visible.isEmpty } }

    public static func build(_ tasks: [TaskSnapshot], cairnTotal: Int, now: Date, calendar: Calendar) -> HorizonModel {
        var buckets: [Band: [TaskSnapshot]] = [:]
        for task in tasks {
            let band = TimeBands.band(for: task, now: now, calendar: calendar)
            guard band != .cairn else { continue }
            buckets[band, default: []].append(task)
        }
        var groups: [Band: Group] = [:]
        for band in Band.allCases where band != .cairn {
            let sorted = (buckets[band] ?? []).sorted(by: Self.ordered)
            let cap = min(TimeBands.caps(band), sorted.count)
            groups[band] = Group(band: band, visible: Array(sorted.prefix(cap)), overflow: sorted.count - cap)
        }
        return HorizonModel(groups: groups, ember: groups[.inHand]?.visible.first, cairnTotal: cairnTotal)
    }

    private static func ordered(_ a: TaskSnapshot, _ b: TaskSnapshot) -> Bool {
        switch (a.due, b.due) {
        case let (x?, y?): return x != y ? x < y : a.title < b.title
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return a.title < b.title
        }
    }
}
