import WidgetKit
import SwiftUI

struct PlaceholderEntry: TimelineEntry { let date: Date }

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { .init(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) { completion(.init(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [.init(date: .now)], policy: .never))
    }
}

@main
struct SimpleTaskWidgetBundle: WidgetBundle {
    var body: some Widget { NextWidget() }
}

struct NextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextWidget", provider: PlaceholderProvider()) { _ in
            Text("Next")
        }
    }
}
