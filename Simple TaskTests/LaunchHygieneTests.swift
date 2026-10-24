import Testing
import Foundation
@testable import SimpleTaskKit

final class FakePermission: NotificationPermission {
    var undetermined: Bool
    var requests = 0
    init(undetermined: Bool) { self.undetermined = undetermined }
    func isUndetermined() async -> Bool { undetermined }
    func request() async { requests += 1; undetermined = false }
}

struct LaunchHygieneTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func cairnLabelHandlesEmptySingularAndPlural() {
        #expect(CairnLabel.text(total: 0, today: 0) == "Cairn · no stones yet")
        #expect(CairnLabel.text(total: 1, today: 1) == "Cairn · 1 stone · 1 today")
        #expect(CairnLabel.text(total: 1284, today: 6) == "Cairn · 1,284 stones · 6 today")
    }

    @Test func schedulingAReminderAsksForPermissionOnlyWhenUndetermined() async {
        let permission = FakePermission(undetermined: true)
        let scheduler = Scheduler(center: FakeCenter(), permission: permission)
        let t = ToDo(item: "Call", reminderIsOn: true, reminderDate: now.addingTimeInterval(3600))
        await scheduler.schedule(t, now: now)
        await scheduler.schedule(t, now: now)
        #expect(permission.requests == 1)
    }

    @Test func schedulingWithoutAReminderNeverAsks() async {
        let permission = FakePermission(undetermined: true)
        let scheduler = Scheduler(center: FakeCenter(), permission: permission)
        await scheduler.schedule(ToDo(item: "No reminder"), now: now)
        #expect(permission.requests == 0)
    }
}
