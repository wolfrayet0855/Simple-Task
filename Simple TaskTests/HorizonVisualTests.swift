import Testing
import Foundation
@testable import SimpleTaskKit

struct HorizonVisualTests {
    @Test func textTokensMeetContrastOnGroundAndCard() {
        let texts: [(String, Palette.Pair)] = [
            ("ink", Palette.ink), ("inkSecondary", Palette.inkSecondary), ("inkTertiary", Palette.inkTertiary),
            ("emberText", Palette.emberText), ("witnessText", Palette.witnessText),
            ("slippedText", Palette.slippedText), ("landmark", Palette.landmark),
        ]
        for (name, pair) in texts {
            for surface in [Palette.ground, Palette.card] {
                #expect(Palette.contrast(pair.light, surface.light) >= 4.5, "\(name) light")
                #expect(Palette.contrast(pair.dark, surface.dark) >= 4.5, "\(name) dark")
            }
        }
    }

    @Test func tagColoursMeetNonTextContrastOnCard() {
        #expect(Palette.tags.count == 8)
        for (i, pair) in Palette.tags.enumerated() {
            #expect(Palette.contrast(pair.light, Palette.card.light) >= 3, "tag \(i + 1) light")
            #expect(Palette.contrast(pair.dark, Palette.card.dark) >= 3, "tag \(i + 1) dark")
        }
    }

    func date(_ h: Int, _ m: Int = 0) -> Date {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!
        return c.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: h, minute: m))!
    }
    var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    @Test func skyBlendsBetweenAnchors() {
        #expect(Sky.keyframes(at: date(2), calendar: utc).from == .night)
        let dawn = Sky.keyframes(at: date(7), calendar: utc)
        #expect(dawn.from == .dawn && dawn.to == .day && abs(dawn.t - 0.5) < 0.001)
        #expect(Sky.keyframes(at: date(12), calendar: utc).from == .day)
        let late = Sky.keyframes(at: date(23), calendar: utc)
        #expect(late.from == .night && late.to == .night)
    }

    @Test func sunOnlyShinesBetweenSixAndTwenty() {
        #expect(Sky.sunPosition(at: date(5), calendar: utc) == nil)
        #expect(Sky.sunPosition(at: date(6), calendar: utc) == 0)
        #expect(abs(Sky.sunPosition(at: date(13), calendar: utc)! - 0.5) < 0.001)
        #expect(Sky.sunPosition(at: date(21), calendar: utc) == nil)
    }

    @Test func emptyBandsCollapseAndFullBandsTakeTheRoom() {
        let h = BandHeights.allocate(total: 400, counts: [.tomorrow: 2])
        #expect(h[.horizon] == 32 && h[.month] == 32 && h[.week] == 32)
        #expect(h[.tomorrow]! > 300)
    }

    @Test func nothingPopulatedLeavesRoomAsSky() {
        let h = BandHeights.allocate(total: 400, counts: [:])
        #expect(h.values.reduce(0, +) == 128)
    }

    @Test func leftoverIsSharedByWeightAndNeverBelowMinimum() {
        let h = BandHeights.allocate(total: 500, counts: [.tomorrow: 1, .week: 1])
        #expect(h[.tomorrow]! > h[.week]!)
        #expect(h[.tomorrow]! >= 34 + 6 + 12 + 20)
        #expect(abs(h.values.reduce(0, +) - 500) < 0.01)
    }

    @Test func tooSmallAFieldKeepsMinimums() {
        let h = BandHeights.allocate(total: 100, counts: [.tomorrow: 6, .week: 6])
        #expect(h[.tomorrow]! >= 3 * 40 + 32)
    }
}
