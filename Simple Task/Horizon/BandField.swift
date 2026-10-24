import SwiftUI
import SimpleTaskKit

/// A far band: items sit at a height linear in time, staggered across lanes.
struct BandField: View {
    let group: HorizonModel.Group
    let depth: Double
    let now: Date
    let onOpen: (UUID) -> Void
    var accessibilityName: String

    private let chipHeight: CGFloat = 28
    private let gap: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let lanes = max(1, min(3, group.visible.count))
            let laneWidth = (geo.size.width - 32) / CGFloat(lanes)
            let placed = place(lanes: lanes, height: geo.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(group.visible) { task in
                    if let p = placed[task.id] {
                        FarChip(task: task, depth: depth, width: laneWidth - 8)
                            .offset(x: 16 + CGFloat(p.lane) * laneWidth, y: p.y)
                            .onTapGesture { onOpen(task.id) }
                            .accessibilityAddTraits(.isButton)
                    }
                }
                if group.overflow > 0 {
                    Text("+\(group.overflow)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Tokens.ink.opacity(0.6))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Tokens.stone.opacity(0.5)))
                        .offset(x: geo.size.width - 56, y: geo.size.height - 26)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityName)
    }

    private func place(lanes: Int, height: CGFloat) -> [UUID: (lane: Int, y: CGFloat)] {
        var result: [UUID: (Int, CGFloat)] = [:]
        var nextFree = [CGFloat](repeating: height, count: lanes)   // lowest free y per lane, from the bottom
        let sorted = group.visible.sorted {
            TimeBands.position(for: $0, now: now, calendar: .current) < TimeBands.position(for: $1, now: now, calendar: .current)
        }
        for (i, task) in sorted.enumerated() {
            let lane = i % lanes
            let t = TimeBands.position(for: task, now: now, calendar: .current)
            let ideal: CGFloat = (height - chipHeight) * CGFloat(1 - t)
            let y: CGFloat = max(0, min(ideal, nextFree[lane] - chipHeight - gap))
            result[task.id] = (lane, y)
            nextFree[lane] = y
        }
        return result.mapValues { (lane: $0.0, y: $0.1) }
    }
}
