import AppIntents
import UserNotifications
import WidgetKit

public struct SimpleTaskKitPackage: AppIntentsPackage {
    public static var includedPackages: [any AppIntentsPackage.Type] { [] }
}

public struct CompleteTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Finish Task"
    public static let description = IntentDescription("Finish a task and lay a stone on your Cairn.")

    @Parameter(title: "Task") public var task: TaskEntity

    public static var parameterSummary: some ParameterSummary { Summary("Finish \(\.$task)") }

    public init() {}
    public init(task: TaskEntity) { self.task = task }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let stone = try TaskActions.complete(id: task.id, in: try TaskActions.makeContext())
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Scheduler.notificationID(for: task.id)])
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "Stone #\(stone).")
    }
}

public struct WhatsNextIntent: AppIntent {
    public static let title: LocalizedStringResource = "What's Next"
    public static let description = IntentDescription("Hear the one thing to do next.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let next = try TaskActions.inHand(in: try TaskActions.makeContext()).first
        return .result(dialog: next.map { "Next: \($0.title)." } ?? "Nothing in hand.")
    }
}
