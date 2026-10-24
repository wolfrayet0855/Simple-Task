import SimpleTaskKit
import SwiftUI

/// The Cairn: one stone per finished task. The total only ever grows.
struct CairnStrip: View {
    let total: Int
    let today: Int

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<min(max(total, 0), 14), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i >= min(total, 14) - min(today, 14) ? Tokens.ember.opacity(0.85) : Tokens.stone)
                        .frame(width: 14, height: 10 + CGFloat((i * 7) % 5))
                        .rotationEffect(.degrees(Double((i * 13) % 7) - 3))
                }
            }
            .frame(height: 16, alignment: .bottom)
            Spacer(minLength: 0)
            Text(CairnLabel.text(total: total, today: today))
                .font(.footnote.monospacedDigit()).foregroundStyle(Tokens.inkSecondary).lineLimit(2).minimumScaleFactor(0.8)
        }
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CairnLabel.text(total: total, today: today))
    }
}
