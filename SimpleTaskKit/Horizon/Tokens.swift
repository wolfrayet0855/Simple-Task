import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

public enum Tokens {
    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    private static func dynamic(_ pair: Palette.Pair) -> Color { dynamic(pair.light, pair.dark) }
    private static func dynamic(_ light: UInt32, _ dark: UInt32, alpha lightAlpha: Double, _ darkAlpha: Double,
                                darkBase: UInt32? = nil) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: darkBase ?? dark).withAlphaComponent(darkAlpha)
            : UIColor(hex: light).withAlphaComponent(lightAlpha) })
    }
    public static let inkSecondary = dynamic(Palette.inkSecondary)
    public static let inkTertiary = dynamic(Palette.inkTertiary)
    public static let emberText = dynamic(Palette.emberText)
    public static let witnessText = dynamic(Palette.witnessText)
    public static let slippedText = dynamic(Palette.slippedText)
    public static let card = dynamic(Palette.card)
    public static let threshold = dynamic(Palette.threshold)
    public static let cardEdge = dynamic(0x1C1E22, 0xFFFFFF, alpha: 0.08, 0.07)
    public static let contour = dynamic(0x1C1E22, 0xEDEBE6, alpha: 0.10, 0.10)
    public static func tag(_ index: Int) -> Color { dynamic(Palette.tags[((index % 8) + 8) % 8]) }
    public static func skyTop(_ key: SkyKey) -> Color { dynamic(key.top) }
    public static func skyGlow(_ key: SkyKey) -> Color { dynamic(key.glow) }

    public static let ink = dynamic(0x1C1E22, 0xEDEBE6)
    public static let ground = dynamic(0xFBF8F3, 0x17150F)
    public static let skyDay = dynamic(0xE6EDF6, 0x0E1420)
    public static let skyDusk = dynamic(0xF2E4DA, 0x1D1626)
    public static let ember = dynamic(0xD9712B, 0xF29A55)
    public static let landmark = dynamic(0x4B4FA8, 0x9A9DF2)
    public static let witness = dynamic(0x2F8F8A, 0x5CC2BC)
    public static let slipped = dynamic(0x8A93A6, 0x6E7689)
    public static let stone = dynamic(0xB9B2A6, 0x4F493F)

    /// 0 in daylight, 1 deep in the evening; the sky follows local time.
    public static func duskAmount(at date: Date, calendar: Calendar = .current) -> Double {
        let h = Double(calendar.component(.hour, from: date)) + Double(calendar.component(.minute, from: date)) / 60
        switch h {
        case ..<5: return 1
        case ..<6.5: return 1 - (h - 5) / 1.5
        case ..<17: return 0
        case ..<20: return (h - 17) / 3
        default: return 1
        }
    }
}

extension CardTint {
    public var color: Color {
        switch self {
        case .ember: Tokens.ember
        case .landmark: Tokens.landmark
        case .witness: Tokens.witness
        case .slipped: Tokens.slipped
        case .ink: Tokens.ink
        }
    }
}

public enum Motion {
    public static let settle = Animation.spring(response: 0.42, dampingFraction: 0.82)
    public static let lift = Animation.spring(response: 0.28, dampingFraction: 0.7)
    public static let drift = Animation.easeInOut(duration: 1.2)
    public static let trailDraw = 0.6
    public static let hold = 0.55
}
