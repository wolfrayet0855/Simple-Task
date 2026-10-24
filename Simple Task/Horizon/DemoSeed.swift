#if DEBUG
import Foundation
import SwiftData
import SimpleTaskKit

/// Launch with `-seedDemo` to fill an empty store with a believable field.
enum DemoSeed {
    static func run(_ container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemo") else { return }
        let ctx = ModelContext(container)
        guard (try? ctx.fetchCount(FetchDescriptor<ToDo>())) == 0 else { return }
        let phrases = [
            "Send deck to Priya today 2pm @Priya", "Pay rent", "Groceries #home", "Water plants",
            "Call caterer tomorrow 10am", "Gym tomorrow 7am #fitness", "Draft toast in 4 days ^Sam40",
            "Order cake in 5 days ^Sam40", "Book venue in 12 days ^Sam40", "Renew passport in 20 days",
            "Plan trip in 45 days", "Annual review in 70 days",
        ]
        for p in phrases { if let parsed = CaptureParser.parse(p, now: .now, calendar: .current) { _ = try? Capture.insert(parsed, in: ctx) } }
        let slipped = ToDo(item: "Reply to landlord", dueDate: Calendar.current.date(byAdding: .day, value: -2, to: .now)!)
        ctx.insert(slipped)
        for i in 0..<9 {
            let done = ToDo(item: "Done \(i)", isCompleted: true)
            done.completedAt = i < 3 ? .now : Calendar.current.date(byAdding: .day, value: -i, to: .now)
            done.stateRaw = "done"
            ctx.insert(done)
        }
        try? ctx.save()
    }
}
#endif
