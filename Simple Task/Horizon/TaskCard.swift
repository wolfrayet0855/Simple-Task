import SwiftUI
import SimpleTaskKit

/// A completed card drops into the Cairn.
struct SinkTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content.scaleEffect(phase.isIdentity ? 1 : 0.3, anchor: .bottom)
            .offset(y: phase.isIdentity ? 0 : 120)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

/// In Hand card. Size is weight: S/M/L set the minimum height. The ember card is the next action.
struct TaskCard: View {
    let task: TaskSnapshot
    let isEmber: Bool
    let now: Date

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    private var pebbles: Int { task.weight == .S ? 1 : task.weight == .M ? 2 : 3 }

    var meta: String? {
        guard let due = task.due else { return nil }
        let time = due.formatted(.dateTime.hour().minute())
        return isEmber || due < now ? "\(time) · \(BandLabel.countdown(to: due, now: now))" : time
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        HStack(alignment: .center, spacing: 0) {
            if isEmber {
                Capsule().fill(Tokens.ember).frame(width: 4).padding(.vertical, 12).padding(.trailing, 14)
            }
            VStack(alignment: .leading, spacing: 4) {
                if isEmber {
                    Text("NEXT").font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(Tokens.emberText)
                }
                Text(task.title)
                    .font(isEmber ? .title3.weight(.semibold) : .body.weight(.medium))
                    .foregroundStyle(Tokens.ink).lineLimit(3).multilineTextAlignment(.leading)
                if let meta {
                    Text(meta).font(.caption.monospacedDigit()).foregroundStyle(Tokens.inkSecondary)
                }
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .padding(.leading, isEmber ? 4 : 0)
        .frame(maxWidth: .infinity, minHeight: task.weight.height, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 3) {
                ForEach(0..<pebbles, id: \.self) { _ in Circle().fill(Tokens.stone).frame(width: 5, height: 5) }
            }
            .padding(10).accessibilityHidden(true)
        }
        .background {
            shape.fill(isEmber ? Tokens.card.mix(with: Tokens.ember, by: 0.06) : Tokens.card)
                .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.06), radius: scheme == .dark ? 12 : 2, y: scheme == .dark ? 6 : 1)
                .shadow(color: scheme == .dark ? .clear : .black.opacity(0.08), radius: 16, y: 8)
                .shadow(color: isEmber && contrast != .increased ? Tokens.ember.opacity(0.22) : .clear, radius: 20, y: 6)
        }
        .overlay { shape.strokeBorder(isEmber && contrast == .increased ? Tokens.ember : Tokens.cardEdge, lineWidth: isEmber && contrast == .increased ? 1.5 : 1) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [isEmber ? "Next." : "", task.title]
        if let meta { parts.append(meta) }
        parts.append(task.weight == .S ? "Small" : task.weight == .M ? "Medium" : "Large")
        return parts.filter { !$0.isEmpty }.joined(separator: ". ")
    }
}

/// Distant work. Depth shows in type size, chip height and haze, never in shrunken glyphs.
struct FarChip: View {
    let task: TaskSnapshot
    let band: Band
    let width: CGFloat

    private var font: Font {
        switch band { case .tomorrow: .subheadline; case .week: .footnote; case .month: .caption; default: .caption2 }
    }
    private var fillOpacity: Double {
        switch band { case .tomorrow: 0.92; case .week: 0.80; case .month: 0.64; default: 0.12 }
    }

    var body: some View {
        let h = BandHeights.chipHeight(band)
        HStack(spacing: 6) {
            Text(task.title).font(font.weight(.medium)).lineLimit(1)
                .foregroundStyle(band == .month ? Tokens.inkSecondary : Tokens.ink)
            Spacer(minLength: 4)
            if let due = task.due {
                Text(BandLabel.stamp(for: due, band: band)).font(.caption2.monospacedDigit())
                    .foregroundStyle(Tokens.inkSecondary).layoutPriority(1)
            }
        }
        .padding(.horizontal, band == .tomorrow ? 12 : band == .week ? 10 : 9)
        .frame(width: width, height: h)
        .background(Capsule().fill(band == .horizon ? Tokens.landmark.opacity(fillOpacity) : Tokens.card.opacity(fillOpacity)))
        .overlay { if band != .month { Capsule().strokeBorder(band == .horizon ? Tokens.landmark.opacity(0.3) : Tokens.cardEdge) } }
        .contentShape(Rectangle().inset(by: -6))
        .accessibilityElement(children: .combine)
    }
}
