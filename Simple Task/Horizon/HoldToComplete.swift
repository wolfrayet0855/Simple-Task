import SwiftUI

/// Hold 0.55 s to finish; a ring fills while you hold. Swipes never complete a task.
/// With Reduce Motion on, a tap completes instead (the caller shows an Undo toast).
struct HoldToComplete: ViewModifier {
    let cornerRadius: CGFloat
    let onComplete: () -> Void
    let onOpen: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .trim(from: 0, to: pressing ? 1 : 0)
                    .stroke(Tokens.ember, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .animation(pressing ? .linear(duration: Motion.hold) : .easeOut(duration: 0.15), value: pressing)
                    .allowsHitTesting(false)
            }
            .scaleEffect(pressing && !reduceMotion ? 0.98 : 1)
            .animation(Motion.lift, value: pressing)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture { reduceMotion ? onComplete() : onOpen() }
            .onLongPressGesture(minimumDuration: reduceMotion ? 10 : Motion.hold, maximumDistance: 30) {
                pressing = false
                Haptics.settle()
                onComplete()
            } onPressingChanged: { isDown in
                guard !reduceMotion else { return }
                pressing = isDown
                if isDown { Haptics.holdBegan() }
            }
    }
}

extension View {
    func holdToComplete(cornerRadius: CGFloat = 16, onComplete: @escaping () -> Void,
                        onOpen: @escaping () -> Void) -> some View {
        modifier(HoldToComplete(cornerRadius: cornerRadius, onComplete: onComplete, onOpen: onOpen))
    }
}
