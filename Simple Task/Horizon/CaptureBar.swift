import SwiftUI
import SimpleTaskKit

struct CaptureBar: View {
    let onCommit: (ParsedCapture) -> Void
    @Binding var text: String
    @FocusState private var focused: Bool

    private var parsed: ParsedCapture? { CaptureParser.parse(text, now: .now, calendar: .current) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let p = parsed, p.due != nil || p.tag != nil || p.witness != nil || p.landmark != nil {
                HStack(spacing: 6) {
                    if let due = p.due { chip(due.formatted(.dateTime.weekday(.abbreviated).hour().minute()), Tokens.ember) }
                    if let tag = p.tag { chip("#\(tag)", Tokens.ink.opacity(0.7)) }
                    if let w = p.witness { chip("pledge to \(w)", Tokens.witness) }
                    if let l = p.landmark { chip(l, Tokens.landmark) }
                }
                .padding(.leading, 4)
                .transition(.opacity)
            }
            HStack(spacing: 10) {
                TextField(text: $text, prompt: Text("Drop a thought…").foregroundStyle(Tokens.inkTertiary), axis: .vertical) { Text("Capture") }
                    .lineLimit(1...3)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(commit)
                    .onChange(of: text) { _, new in
                        // A vertical-axis field inserts a newline on Return instead of submitting.
                        guard new.contains("\n") else { return }
                        let endedWithReturn = new.hasSuffix("\n")
                        text = new.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
                        if endedWithReturn { commit() }
                    }
                    .accessibilityLabel("Capture")
                Button(action: commit) {
                    Image(systemName: "arrow.up").font(.body.bold()).foregroundStyle(.white)
                        .frame(width: 34, height: 34).background(Circle().fill(Tokens.ember))
                }
                .opacity(parsed == nil ? 0 : 1)
                .disabled(parsed == nil)
                .accessibilityLabel("Add")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .animation(.easeOut(duration: 0.15), value: parsed)
    }

    private func chip(_ label: String, _ color: Color) -> some View {
        Text(label).font(.caption.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .foregroundStyle(color)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private func commit() {
        guard let p = parsed else { return }
        Haptics.capture()
        onCommit(p)
        text = ""
        focused = true
    }
}
