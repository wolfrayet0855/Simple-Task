import SwiftUI
import SimpleTaskKit

/// In Hand card. Size is weight: S/M/L set the minimum height.
struct TaskCard: View {
    let task: TaskSnapshot
    let isEmber: Bool
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isEmber ? Tokens.ember : Tokens.ink.opacity(0.18))
                .frame(width: 10, height: 10)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(isEmber ? .title3.weight(.semibold) : .body.weight(.medium))
                    .foregroundStyle(Tokens.ink)
                    .multilineTextAlignment(.leading)
                if let due = task.due {
                    Text(due, format: .dateTime.hour().minute())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Tokens.ink.opacity(0.55))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: task.weight.height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Tokens.ground)
                .shadow(color: .black.opacity(isEmber ? 0.14 : 0.07), radius: isEmber ? 14 : 8, y: isEmber ? 6 : 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isEmber ? Tokens.ember.opacity(0.7) : Tokens.ink.opacity(0.06), lineWidth: isEmber ? 1.5 : 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Distant work: smaller and fainter the further it is.
struct FarChip: View {
    let task: TaskSnapshot
    let depth: Double
    let width: CGFloat

    var body: some View {
        let s = TimeBands.scale(depth: depth)
        Text(task.title)
            .font(.footnote.weight(.medium))
            .lineLimit(1)
            .foregroundStyle(Tokens.ink.opacity(1 - 0.35 * depth))
            .padding(.horizontal, 10)
            .frame(width: width / s, height: 28, alignment: .leading)
            .background(Capsule().fill(Tokens.ground.opacity(0.85)))
            .overlay(Capsule().strokeBorder(Tokens.ink.opacity(0.07)))
            .scaleEffect(s, anchor: .leading)
            .frame(width: width, height: 28 * s, alignment: .leading)
    }
}
