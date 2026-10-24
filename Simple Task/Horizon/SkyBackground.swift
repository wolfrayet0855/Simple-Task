import SwiftUI
import SimpleTaskKit

/// Sky, horizon line, sun or moon, and the converging path. All decorative.
struct SkyBackground: View {
    let date: Date
    let calm: Bool
    let size: CGSize
    let insets: EdgeInsets
    let horizonY: CGFloat       // in safe-area coordinates
    let thresholdY: CGFloat
    let contourYs: [CGFloat]    // band floors, for the narrowing contours

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let vanishingHalfWidth: CGFloat = 120

    static func inset(at y: CGFloat, width: CGFloat, horizonY: CGFloat, thresholdY: CGFloat) -> CGFloat {
        let span = max(1, thresholdY - horizonY)
        let depth = min(1, max(0, (thresholdY - y) / span))
        return 16 + depth * (width / 2 - vanishingHalfWidth - 16)
    }

    var body: some View {
        let k = Sky.keyframes(at: date)
        let top = Tokens.skyTop(k.from).mix(with: Tokens.skyTop(k.to), by: k.t, in: .perceptual)
        let glow = Tokens.skyGlow(k.from).mix(with: Tokens.skyGlow(k.to), by: k.t, in: .perceptual)
        let total = max(1, size.height + insets.top + insets.bottom)
        let hl = min(1, max(0, (horizonY + insets.top) / total))
        let tl = min(0.999, max(hl, (thresholdY + insets.top) / total))
        ZStack {
            LinearGradient(stops: [
                .init(color: top, location: 0), .init(color: glow, location: hl),
                .init(color: Tokens.ground, location: tl), .init(color: Tokens.threshold, location: min(1, tl + 0.001)),
                .init(color: Tokens.threshold, location: 1),
            ], startPoint: .top, endPoint: .bottom)
            .saturation(calm ? 0.7 : 1)
            .animation(reduceMotion ? nil : Motion.drift, value: calm)
            .ignoresSafeArea()

            Canvas { ctx, canvasSize in
                let w = canvasSize.width
                let line = Tokens.contour
                // Horizon line, the strongest line after the threshold.
                var h = Path(); h.move(to: CGPoint(x: 0, y: horizonY)); h.addLine(to: CGPoint(x: w, y: horizonY))
                ctx.stroke(h, with: .color(line), lineWidth: 1.5)
                // Path rails.
                let vp = Self.vanishingHalfWidth
                for (from, to) in [(CGPoint(x: 16, y: thresholdY), CGPoint(x: w / 2 - vp, y: horizonY)),
                                   (CGPoint(x: w - 16, y: thresholdY), CGPoint(x: w / 2 + vp, y: horizonY))] {
                    var p = Path(); p.move(to: from); p.addLine(to: to)
                    ctx.stroke(p, with: .color(line), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                }
                // Contours narrow with depth.
                for y in contourYs {
                    let inset = Self.inset(at: y, width: w, horizonY: horizonY, thresholdY: thresholdY)
                    var p = Path(); p.move(to: CGPoint(x: inset, y: y)); p.addLine(to: CGPoint(x: w - inset, y: y))
                    ctx.stroke(p, with: .color(line), lineWidth: 1)
                }
                // Sun on the horizon, or a moon at night.
                if let pos = Sky.sunPosition(at: date) {
                    let x = 16 + pos * (w - 32)
                    if contrast != .increased {
                        let glowRect = CGRect(x: x - 20, y: horizonY - 20, width: 40, height: 40)
                        ctx.fill(Path(ellipseIn: glowRect), with: .radialGradient(
                            Gradient(colors: [Tokens.ember.opacity(0.18), .clear]),
                            center: CGPoint(x: x, y: horizonY), startRadius: 0, endRadius: 20))
                    }
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 7, y: horizonY - 7, width: 14, height: 14)),
                             with: .color(Tokens.ember.opacity(0.7)))
                } else {
                    let x = w * 2 / 3
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 5, y: horizonY - 14, width: 10, height: 10)),
                             with: .color(Tokens.stone))
                }
            }
            .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}
