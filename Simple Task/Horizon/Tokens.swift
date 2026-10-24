import SwiftUI
import UIKit
import SimpleTaskKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

enum Tokens {
    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let ink = dynamic(0x1C1E22, 0xEDEBE6)
    static let ground = dynamic(0xFBF8F3, 0x17150F)
    static let skyDay = dynamic(0xE6EDF6, 0x0E1420)
    static let skyDusk = dynamic(0xF2E4DA, 0x1D1626)
    static let ember = dynamic(0xD9712B, 0xF29A55)
    static let landmark = dynamic(0x4B4FA8, 0x9A9DF2)
    static let witness = dynamic(0x2F8F8A, 0x5CC2BC)
    static let slipped = dynamic(0x8A93A6, 0x6E7689)
    static let stone = dynamic(0xB9B2A6, 0x4F493F)

    /// 0 in daylight, 1 deep in the evening; the sky follows local time.
    static func duskAmount(at date: Date, calendar: Calendar = .current) -> Double {
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
    var color: Color {
        switch self {
        case .ember: Tokens.ember
        case .landmark: Tokens.landmark
        case .witness: Tokens.witness
        case .slipped: Tokens.slipped
        case .ink: Tokens.ink
        }
    }
}

enum Motion {
    static let settle = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let lift = Animation.spring(response: 0.28, dampingFraction: 0.7)
    static let drift = Animation.easeInOut(duration: 1.2)
    static let trailDraw = 0.6
    static let hold = 0.55
}
