import SwiftUI
import SwiftData
import SimpleTaskKit

/// Small, Medium, Large pebbles.
struct WeightRow: View {
    let current: Weight
    let onSelect: (Weight) -> Void

    private let options: [(Weight, String, CGFloat)] = [(.S, "Small", 8), (.M, "Medium", 11), (.L, "Large", 14)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { weight, name, size in
                let selected = weight == current
                Button { onSelect(weight) } label: {
                    HStack(spacing: 6) {
                        Circle().frame(width: size, height: size)
                        Text(name).font(.subheadline.weight(selected ? .semibold : .regular))
                    }
                    .foregroundStyle(selected ? Tokens.ground : Tokens.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Capsule().fill(selected ? Tokens.ink : SheetTokens.card))
                    .overlay(Capsule().strokeBorder(SheetTokens.cardEdge, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight")
        .accessibilityValue(options.first { $0.0 == current }?.1 ?? "Medium")
        .accessibilityAdjustableAction { direction in
            let all = options.map(\.0)
            guard let i = all.firstIndex(of: current) else { return }
            switch direction {
            case .increment: if i + 1 < all.count { onSelect(all[i + 1]) }
            case .decrement: if i > 0 { onSelect(all[i - 1]) }
            @unknown default: break
            }
        }
    }
}

/// None, each tag, and "+ New".
struct TagRow: View {
    let tags: [Tag]
    let selected: Tag?
    let onSelect: (Tag?) -> Void
    let onNew: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(isOn: selected == nil, label: { Text("None") }) { onSelect(nil) }
                ForEach(tags) { tag in
                    chip(isOn: selected?.id == tag.id, label: {
                        HStack(spacing: 6) {
                            Circle().fill(SheetTokens.tagColor(tag.colorToken)).frame(width: 6, height: 6)
                            Text(tag.name)
                        }
                    }) { onSelect(tag) }
                }
                Button(action: onNew) {
                    Text("+ New").font(.subheadline).foregroundStyle(Tokens.ink)
                        .padding(.horizontal, 12).frame(minHeight: 36)
                        .overlay(Capsule().strokeBorder(SheetTokens.contour, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }

    private func chip<L: View>(isOn: Bool, @ViewBuilder label: () -> L, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label().font(.subheadline).foregroundStyle(Tokens.ink)
                .padding(.horizontal, 12).frame(minHeight: 36)
                .background(Capsule().fill(SheetTokens.card))
                .overlay(Capsule().strokeBorder(isOn ? Tokens.ink : SheetTokens.cardEdge, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
