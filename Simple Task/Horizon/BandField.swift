import SwiftUI
import SimpleTaskKit

/// A far band: items sit at a height linear in time, staggered across lanes inside the path.
struct BandField: View {
    let band: Band
    let group: HorizonModel.Group?
    let now: Date
    let horizontalInset: CGFloat
    let onOpen: (UUID) -> Void
    let label: String

    private let gap: CGFloat = 6
    private let labelStrip: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let tasks = group?.visible ?? []
            let lanes = max(1, min(BandHeights.lanes(band), tasks.count))
            let usable = max(0, geo.size.width - 2 * horizontalInset)
            let laneWidth = usable / CGFloat(lanes)
            let placed = place(tasks, lanes: lanes, height: geo.size.height)
            ZStack(alignment: .topLeading) {
                Text(label).font(.caption.weight(.semibold)).tracking(0.6).foregroundStyle(Tokens.inkSecondary)
                    .padding(.leading, Space.xl).padding(.top, 10).accessibilityHidden(true)
                ForEach(tasks) { task in
                    if let p = placed[task.id] {
                        FarChip(task: task, band: band, width: laneWidth - 8)
                            .offset(x: horizontalInset + CGFloat(p.lane) * laneWidth, y: p.y)
                            .onTapGesture { onOpen(task.id) }
                            .accessibilityAddTraits(.isButton)
                    }
                }
                if let overflow = group?.overflow, overflow > 0 {
                    Text("+\(overflow)").font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Tokens.ink).frame(width: 28, height: 28)
                        .background(Circle().fill(Tokens.stone.opacity(0.6)))
                        .offset(x: geo.size.width - horizontalInset - 28, y: geo.size.height - 30)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
        .accessibilityLabel((group?.visible.isEmpty ?? true) ? "\(label), nothing yet" : "\(label), \(group!.visible.count) \(group!.visible.count == 1 ? "task" : "tasks")")
    }

    private func place(_ tasks: [TaskSnapshot], lanes: Int, height: CGFloat) -> [UUID: (lane: Int, y: CGFloat)] {
        let chip = BandHeights.chipHeight(band)
        var result: [UUID: (lane: Int, y: CGFloat)] = [:]
        var nextFree = [CGFloat](repeating: height, count: lanes)
        let sorted = tasks.sorted {
            TimeBands.position(for: $0, now: now, calendar: .current) < TimeBands.position(for: $1, now: now, calendar: .current)
        }
        for (i, task) in sorted.enumerated() {
            let lane = i % lanes
            let t = TimeBands.position(for: task, now: now, calendar: .current)
            let ideal = labelStrip + (height - labelStrip - chip) * CGFloat(1 - t)
            let y = max(labelStrip, min(ideal, nextFree[lane] - chip - gap))
            result[task.id] = (lane, y)
            nextFree[lane] = y
        }
        return result
    }
}
