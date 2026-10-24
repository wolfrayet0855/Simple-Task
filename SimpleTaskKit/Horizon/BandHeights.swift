import CoreGraphics

/// Splits the perspective field between the far bands: empty bands collapse to a label, full ones breathe.
public enum BandHeights {
    public static let farBands: [Band] = [.horizon, .month, .week, .tomorrow]   // top to bottom

    static func weight(_ band: Band) -> CGFloat {
        switch band { case .tomorrow: 1.0; case .week: 0.8; case .month: 0.6; default: 0.45 }
    }
    public static func chipHeight(_ band: Band) -> CGFloat {
        switch band { case .tomorrow: 34; case .week: 30; case .month: 26; default: 28 }
    }
    public static func lanes(_ band: Band) -> Int {
        switch band { case .tomorrow, .week: 2; default: 3 }
    }
    public static let emptyHeight: CGFloat = 32

    /// Returns a height for each far band. The sum can be less than `total` when nothing needs the room;
    /// the caller leaves the rest as sky. It can exceed `total` only when the minimums themselves do not fit.
    public static func allocate(total: CGFloat, counts: [Band: Int]) -> [Band: CGFloat] {
        var heights: [Band: CGFloat] = [:]
        var populated: [Band] = []
        for band in farBands {
            let n = counts[band] ?? 0
            if n == 0 { heights[band] = emptyHeight; continue }
            populated.append(band)
            let rows = (n + lanes(band) - 1) / lanes(band)
            heights[band] = CGFloat(rows) * (chipHeight(band) + 6) + 12 + 28   // + label strip
        }
        let used = heights.values.reduce(0, +)
        let leftover = total - used
        guard leftover > 0, !populated.isEmpty else { return heights }
        let weights = populated.reduce(0) { $0 + weight($1) }
        for band in populated { heights[band]! += leftover * weight(band) / weights }
        return heights
    }
}
