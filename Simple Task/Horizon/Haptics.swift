import UIKit

@MainActor
enum Haptics {
    static func capture() { UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8) }
    static func holdBegan() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4) }
    static func settle() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
