import SwiftUI
import SimpleTaskKit

/// Shown instead of crashing when the store can't be opened or moved. Never red, never blames the user.
struct RecoveryView: View {
    let failure: BootFailure
    let retrying: Bool
    let attempts: Int
    let retry: () -> Void

    @State private var showTasks = false
    @AccessibilityFocusState private var titleFocused: Bool
    private let hasLegacy = FileManager.default.fileExists(atPath: Store.legacyStoreURL.path)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Tokens.skyDusk, Tokens.ground], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    mark
                    Text("Your tasks are safe.")
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titleFocused)
                    Text(bodyText).font(.body).foregroundStyle(Tokens.ink.opacity(0.7)).multilineTextAlignment(.center)
                    if attempts > 0 {
                        Text("Still couldn't move them. Your original copy is safe.")
                            .font(.footnote).foregroundStyle(Tokens.ink.opacity(0.7))
                    }
                    DisclosureGroup("What happened") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(explanation)
                            Text(failure.diagnosticCode).font(.footnote.monospaced()).textSelection(.enabled)
                        }
                        .font(.footnote).foregroundStyle(Tokens.ink.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                    }
                    .font(.footnote).tint(Tokens.ink.opacity(0.7))

                    VStack(spacing: 12) {
                        Button(action: retry) {
                            HStack { if retrying { ProgressView() }; Text(retrying ? "Trying…" : "Try again") }
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.glassProminent).tint(Tokens.ember).disabled(retrying)
                        if failure == .outOfSpace {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                            .buttonStyle(.glass).frame(minHeight: 50)
                        }
                        if hasLegacy {
                            Button { showTasks = true } label: { Text("View my tasks").frame(maxWidth: .infinity, minHeight: 50) }
                                .buttonStyle(.glass)
                            if let url = backupURL() {
                                ShareLink(item: url) { Text("Share a copy").frame(maxWidth: .infinity, minHeight: 50) }
                                    .buttonStyle(.glass)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 40)
                .frame(maxWidth: 560)
            }
        }
        .foregroundStyle(Tokens.ink)
        .sheet(isPresented: $showTasks) { LegacyTasksSheet() }
        .onAppear { titleFocused = true }
    }

    private var mark: some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 5).fill(Tokens.ember).frame(width: 22, height: 14)
            RoundedRectangle(cornerRadius: 6).fill(Tokens.stone).frame(width: 38, height: 16)
            RoundedRectangle(cornerRadius: 7).fill(Tokens.stone.opacity(0.8)).frame(width: 56, height: 18)
        }
        .accessibilityHidden(true)
    }

    private var bodyText: String {
        switch failure {
        case .relocationMismatch:
            "Waymark couldn't finish moving your tasks to their new home, so it stopped and left the original copy untouched on this device."
        case .outOfSpace:
            "Your device is nearly out of space, so Waymark couldn't move your tasks yet. The original copy is untouched. Free up some space and try again."
        case .other:
            "Something stopped Waymark from opening your tasks. The original copy is untouched on this device."
        }
    }

    private var explanation: String {
        if case .relocationMismatch(let expected, let got) = failure {
            return "We copy your tasks to a shared place so widgets and Siri can see them. The copy had \(got) of \(expected) tasks, so we stopped."
        }
        return "Quote this code if you contact support. It contains no task text."
    }

    private func backupURL() -> URL? {
        guard let data = try? LegacyBackup.json() else { return nil }
        let day = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("waymark-backup-\(day).json")
        return (try? data.write(to: url, options: .atomic)) == nil ? nil : url
    }
}

private struct LegacyTasksSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let rows = (try? LegacyBackup.rows()) ?? []

    var body: some View {
        NavigationStack {
            List(rows) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title).font(.body)
                    Text(row.dueDate.formatted(date: .abbreviated, time: row.isAllDay ? .omitted : .shortened))
                        .font(.footnote).foregroundStyle(.secondary)
                    if !row.subtasks.isEmpty {
                        Text(row.subtasks.joined(separator: ", ")).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay { if rows.isEmpty { Text("No tasks found.").foregroundStyle(.secondary) } }
            .navigationTitle("Your tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
