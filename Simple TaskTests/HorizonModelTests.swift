import Testing
import Foundation
@testable import SimpleTaskKit

struct HorizonModelTests {
    func snap(_ title: String, due: Date?, done: Bool = false) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: title, due: due, weight: .M, isDone: done)
    }
    func build(_ tasks: [TaskSnapshot], cairn: Int = 0) -> HorizonModel {
        HorizonModel.build(tasks, cairnTotal: cairn, now: Fixed.now, calendar: Fixed.calendar)
    }

    @Test func emptyStoreIsEmptyWithNoEmber() {
        let m = build([])
        #expect(m.isEmpty)
        #expect(m.ember == nil)
        #expect(m.groups.values.allSatisfy { $0.visible.isEmpty })
    }

    @Test func onlyDoneTasksStillCountsAsEmptyField() {
        #expect(build([snap("a", due: nil, done: true)], cairn: 1).isEmpty)
    }

    @Test func inHandCapsAtFiveAndFoldsTheRest() throws {
        let tasks = (0..<8).map { snap("t\($0)", due: Fixed.days(0, hour: 9 + $0 % 8)) }
        let g = try #require(build(tasks).groups[.inHand])
        #expect(g.visible.count == 5)
        #expect(g.overflow == 3)
    }

    @Test func emberIsEarliestDatedInHand() {
        let early = snap("early", due: Fixed.days(0, hour: 11))
        let late = snap("late", due: Fixed.days(0, hour: 17))
        let undated = snap("undated", due: nil)
        #expect(build([undated, late, early]).ember?.title == "early")
    }

    @Test func emberFallsBackToUndatedWhenNothingIsTimed() {
        #expect(build([snap("undated", due: nil)]).ember?.title == "undated")
    }

    @Test func slippedLandsInSlippedGroupNotInHand() throws {
        let m = build([snap("old", due: Fixed.days(-2))])
        #expect(m.groups[.slipped]?.visible.map(\.title) == ["old"])
        #expect(m.groups[.inHand]?.visible.isEmpty == true)
        #expect(m.ember == nil)
        #expect(!m.isEmpty)
    }

    @Test func cairnTotalPassesThrough() { #expect(build([], cairn: 1284).cairnTotal == 1284) }

    @Test func slippedCardIsNeverRed() {
        #expect(CardTint.tint(band: .slipped, isEmber: false) == .slipped)
        #expect(CardTint.tint(band: .inHand, isEmber: true) == .ember)
        #expect(!CardTint.allCases.contains(where: { $0.isRed }))
    }
}
