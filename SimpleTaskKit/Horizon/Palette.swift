import Foundation

/// Hex pairs behind the colour tokens, so contrast can be tested without SwiftUI.
public enum Palette {
    public typealias Pair = (light: UInt32, dark: UInt32)

    public static let ink: Pair = (0x1C1E22, 0xEDEBE6)
    public static let ground: Pair = (0xFBF8F3, 0x17150F)
    public static let card: Pair = (0xFFFDF9, 0x221F18)
    public static let inkSecondary: Pair = (0x5C5F68, 0xA8A49B)
    public static let inkTertiary: Pair = (0x6E717A, 0x8C887F)
    public static let emberText: Pair = (0xA8501A, 0xF29A55)
    public static let witnessText: Pair = (0x22706C, 0x5CC2BC)
    public static let slippedText: Pair = (0x5E6678, 0x9AA2B4)
    public static let landmark: Pair = (0x4B4FA8, 0x9A9DF2)
    public static let threshold: Pair = (0xF3EEE5, 0x1E1B14)

    /// Eight tag colours; used as dots and notches, so 3:1 against `card` is the bar.
    public static let tags: [Pair] = [
        (0xB5654A, 0xD98E73), (0xA07A2C, 0xD1AE5E), (0x5F8A4E, 0x8DBB7B), (0x3E8A85, 0x6EC0BA),
        (0x4F6FA8, 0x8DA8DD), (0x7A5DA6, 0xB19ADB), (0xA3577F, 0xD58BB2), (0x6F6A62, 0xA9A398),
    ]

    /// WCAG relative-luminance contrast ratio.
    public static func contrast(_ a: UInt32, _ b: UInt32) -> Double {
        func lum(_ hex: UInt32) -> Double {
            func lin(_ v: UInt32) -> Double {
                let c = Double(v) / 255
                return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * lin((hex >> 16) & 0xFF) + 0.7152 * lin((hex >> 8) & 0xFF) + 0.0722 * lin(hex & 0xFF)
        }
        let (x, y) = (lum(a), lum(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
}

public enum Space { public static let xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 28.0 }
public enum Radius { public static let card = 18.0, group = 20.0, chip = 10.0 }
