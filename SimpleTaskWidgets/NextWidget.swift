import WidgetKit
import SwiftUI
import AppIntents
import SimpleTaskKit

struct WidgetPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [SimpleTaskKitPackage.self] }
}

struct NextTimelineEntry: TimelineEntry {
    let next: NextEntry
    var date: Date { next.date }
}

struct NextProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTimelineEntry {
        NextTimelineEntry(next: nextEntry(from: [
            TaskSnapshot(id: UUID(), title: "Send deck to Priya", due: .now, weight: .M, isDone: false)
        ], now: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTimelineEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTimelineEntry>) -> Void) {
        let entry = load()
        completion(Timeline(entries: [entry], policy: .after(entry.next.refreshAt)))
    }

    private func load() -> NextTimelineEntry {
        let tasks = (try? TaskActions.snapshots(in: TaskActions.makeContext())) ?? []
        return NextTimelineEntry(next: nextEntry(from: tasks, now: .now))
    }
}

struct NextView: View {
    let entry: NextTimelineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let task = entry.next.task {
                HStack(spacing: 6) {
                    Circle().fill(Tokens.ember).frame(width: 8, height: 8)
                    Text("NEXT").font(.system(size: 10, weight: .semibold)).tracking(1.2)
                        .foregroundStyle(Tokens.ink.opacity(0.5))
                }
                Text(task.title)
                    .font(family == .systemSmall ? .headline : .title3.weight(.semibold))
                    .foregroundStyle(Tokens.ink)
                    .lineLimit(family == .systemSmall ? 3 : 2)
                if let due = task.due {
                    Text(due, format: .dateTime.hour().minute())
                        .font(.caption.monospacedDigit()).foregroundStyle(Tokens.ink.opacity(0.55))
                }
                Spacer(minLength: 0)
                Button(intent: CompleteTaskIntent(task: TaskEntity(task))) {
                    Label("Done", systemImage: "checkmark").font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderedProminent).tint(Tokens.ember)
            } else {
                Spacer(minLength: 0)
                Text("Clear skies.").font(.headline).foregroundStyle(Tokens.ink)
                Text("\(entry.next.stones.formatted()) stones laid.")
                    .font(.caption).foregroundStyle(Tokens.ink.opacity(0.6))
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Tokens.skyDay.mix(with: Tokens.skyDusk, by: Tokens.duskAmount(at: entry.date)), Tokens.ground],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

@main
struct SimpleTaskWidgetBundle: WidgetBundle {
    var body: some Widget { NextWidget() }
}

struct NextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextWidget", provider: NextProvider()) { entry in
            NextView(entry: entry)
        }
        .configurationDisplayName("Next")
        .description("The one thing to do next. Hold nothing; tap Done.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
