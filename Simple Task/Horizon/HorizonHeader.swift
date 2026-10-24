import SwiftUI
import SimpleTaskKit

/// Date and wayfinding on the left, Shelf and Settings on the right. Never a greeting.
struct HorizonHeader: View {
    let now: Date
    let wayfinding: String
    let shelfCount: Int
    let onShelf: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.title3.weight(.semibold)).fontDesign(.serif).foregroundStyle(Tokens.ink).lineLimit(2)
                Text(wayfinding).font(.subheadline).foregroundStyle(Tokens.inkSecondary).lineLimit(2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                if shelfCount > 0 {
                    Button(action: onShelf) {
                        Image(systemName: "tray").frame(width: 30, height: 30)
                            .overlay(alignment: .topTrailing) {
                                Text("\(shelfCount)").font(.caption2.weight(.bold).monospacedDigit())
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Capsule().fill(Tokens.stone)).foregroundStyle(Tokens.ink)
                                    .offset(x: 2, y: 2)
                            }
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .accessibilityLabel("Shelf, \(shelfCount) \(shelfCount == 1 ? "item" : "items")")
                }
                Button(action: onSettings) { Image(systemName: "gearshape").frame(width: 30, height: 30) }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .accessibilityLabel("Settings")
            }
            .foregroundStyle(Tokens.ink)
        }
        .padding(.horizontal, Space.xl)
        .frame(minHeight: 52)
    }
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Waymark", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                }
                #if DEBUG
                Section("Developer") {
                    NavigationLink("Legacy list") { ToDoListView() }
                    NavigationLink("Legacy graph") { GraphView() }
                    NavigationLink("Legacy settings") { SettingsView() }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
