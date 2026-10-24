import SwiftUI
import UIKit
import SimpleTaskKit

/// Tokens the task sheet needs that the shared token file does not carry yet (ui-spec-phase2 A.1).
enum SheetTokens {
    private static func dynamic(_ light: UInt32, _ dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        func ui(_ hex: UInt32, _ alpha: CGFloat) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
        }
        return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark, darkAlpha) : ui(light, lightAlpha) })
    }

    static let card = dynamic(0xFFFDF9, 0x221F18)
    static let cardEdge = dynamic(0x1C1E22, 0xFFFFFF, lightAlpha: 0.08, darkAlpha: 0.07)
    static let contour = dynamic(0x1C1E22, 0xEDEBE6, lightAlpha: 0.10, darkAlpha: 0.10)
    static let inkSecondary = dynamic(0x5C5F68, 0xA8A49B)
    static let inkTertiary = dynamic(0x6E717A, 0x8C887F)
    static let witnessText = dynamic(0x22706C, 0x5CC2BC)

    static let tagColors: [String: Color] = [
        "tag.1": dynamic(0xB5654A, 0xD98E73), "tag.2": dynamic(0xA07A2C, 0xD1AE5E),
        "tag.3": dynamic(0x5F8A4E, 0x8DBB7B), "tag.4": dynamic(0x3E8A85, 0x6EC0BA),
        "tag.5": dynamic(0x4F6FA8, 0x8DA8DD), "tag.6": dynamic(0x7A5DA6, 0xB19ADB),
        "tag.7": dynamic(0xA3577F, 0xD58BB2), "tag.8": dynamic(0x6F6A62, 0xA9A398),
    ]

    static func tagColor(_ token: String) -> Color { tagColors[token] ?? tagColors["tag.8"]! }

    static let groupRadius: CGFloat = 20
    static let reflow = Animation.spring(response: 0.38, dampingFraction: 0.86)
}

/// A rounded `card` surface that groups rows.
struct SheetGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SheetTokens.card, in: RoundedRectangle(cornerRadius: SheetTokens.groupRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: SheetTokens.groupRadius, style: .continuous)
                .strokeBorder(SheetTokens.cardEdge, lineWidth: 1))
    }
}

/// Small section label above a group.
struct SheetLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).tracking(0.6)
            .foregroundStyle(SheetTokens.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A 48 pt row: symbol, label, trailing value.
struct SheetRow<Trailing: View>: View {
    let symbol: String
    let label: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 28).foregroundStyle(SheetTokens.inkSecondary)
                .accessibilityHidden(true)
            Text(label).font(.body).foregroundStyle(Tokens.ink)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
    }
}
