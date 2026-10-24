import AppIntents
import SimpleTaskKit

struct SimpleTaskAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [SimpleTaskKitPackage.self] }
}

struct SimpleTaskShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: ["Finish \(\.$task) in \(.applicationName)"],
            shortTitle: "Finish Task",
            systemImageName: "checkmark.circle")
        AppShortcut(
            intent: WhatsNextIntent(),
            phrases: ["What's next in \(.applicationName)"],
            shortTitle: "What's Next",
            systemImageName: "flame")
    }
}
