import Testing
import UserNotifications
import Foundation
@testable import SimpleTaskKit

final class FakeCenter: NotificationCenterProtocol {
    var requests: [String: UNNotificationRequest] = [:]
    func schedule(_ request: UNNotificationRequest) async throws { requests[request.identifier] = request }
    func removePending(_ identifiers: [String]) { identifiers.forEach { requests[$0] = nil } }
    func pendingIDs() async -> [String] { Array(requests.keys) }
}

struct SchedulerTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func task(_ title: String, in hours: Double = 2) -> ToDo {
        let t = ToDo(item: title, reminderIsOn: true,
                     reminderDate: now.addingTimeInterval(hours * 3600))
        return t
    }

    @Test func renamingTaskLeavesExactlyOnePendingRequest() async throws {
        let center = FakeCenter()
        let scheduler = Scheduler(center: center)
        let t = task("Send deck")
        await scheduler.schedule(t, now: now)
        t.item = "Send deck to Priya"
        await scheduler.schedule(t, now: now)

        let ids = await center.pendingIDs()
        #expect(ids == ["task.\(t.id.uuidString).reminder"])
        #expect(center.requests[ids[0]]?.content.body == "Send deck to Priya")
    }

    @Test func legacyTitleKeyedRequestsAreRemovedByReconcile() async throws {
        let center = FakeCenter()
        let scheduler = Scheduler(center: center)
        let t = task("Pay rent")
        center.requests["Pay rent"] = UNNotificationRequest(
            identifier: "Pay rent", content: UNMutableNotificationContent(), trigger: nil)

        await scheduler.reconcile(tasks: [t], now: now)

        #expect(await center.pendingIDs() == ["task.\(t.id.uuidString).reminder"])
    }

    @Test func completedPastOrDisabledTasksGetNoRequest() async throws {
        let center = FakeCenter()
        let scheduler = Scheduler(center: center)
        let done = task("done"); done.isCompleted = true
        let past = task("past", in: -1)
        let off = task("off"); off.reminderIsOn = false

        await scheduler.reconcile(tasks: [done, past, off], now: now)

        #expect(await center.pendingIDs().isEmpty)
    }

    @Test func copyNeverShames() async throws {
        let center = FakeCenter()
        let t = task("Send deck")
        await Scheduler(center: center).schedule(t, now: now)
        let content = try #require(center.requests.values.first).content
        #expect(content.title == "Ready when you are")
        #expect(content.body == "Send deck")
        #expect(content.categoryIdentifier == "TASK")
    }
}
