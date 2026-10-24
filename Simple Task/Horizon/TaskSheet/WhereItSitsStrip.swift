import SwiftUI
import SimpleTaskKit

/// The signature control: a mini-path of six stops showing how far away the task sits.
struct WhereItSitsStrip: View {
    let current: TaskEdits.Stop?
    let onSelect: (TaskEdits.Stop) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ns

    private let stops = TaskEdits.Stop.allCases

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(stops) { stop in
                    let selected = stop == current
                    Button { onSelect(stop) } label: {
                        Text(stop.rawValue)
                            .font(.subheadline.weight(selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Color.white : SheetTokens.inkSecondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 36)
                            .background {
                                if selected {
                                    Capsule().fill(Tokens.ember)
                                        .matchedGeometryEffect(id: "stop", in: ns)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                }
            }
            .background {
                Rectangle().fill(.clear).frame(height: 1)
                    .overlay(Line().stroke(SheetTokens.contour, style: StrokeStyle(lineWidth: 1.5, dash: [3, 4])))
            }
            .padding(.horizontal, 4)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : SheetTokens.reflow, value: current)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Where it sits")
        .accessibilityValue(current?.rawValue ?? "Slipped")
        .accessibilityAdjustableAction { direction in
            let i = current.flatMap { stops.firstIndex(of: $0) } ?? 0
            switch direction {
            case .increment: if i + 1 < stops.count { onSelect(stops[i + 1]) }
            case .decrement: if i > 0 { onSelect(stops[i - 1]) }
            @unknown default: break
            }
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}
