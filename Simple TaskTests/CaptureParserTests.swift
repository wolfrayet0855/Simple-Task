import Testing
import Foundation
@testable import SimpleTaskKit

struct CaptureParserTests {
    func parse(_ s: String) -> ParsedCapture? {
        CaptureParser.parse(s, now: Fixed.now, calendar: Fixed.calendar)
    }

    @Test func fullPhrase() throws {
        let p = try #require(parse("dinner w/ Sam fri 7pm #home @Sam"))
        #expect(p.title == "dinner w/ Sam")
        #expect(p.due == Fixed.days(2, hour: 19))
        #expect(p.tag == "home")
        #expect(p.witness == "Sam")
    }
    @Test func plainTitleHasNoDate() throws {
        let p = try #require(parse("buy milk"))
        #expect(p == ParsedCapture(title: "buy milk", due: nil, tag: nil, witness: nil, landmark: nil))
    }
    @Test func tomorrowDefaultsToNine() throws {
        #expect(try #require(parse("call dentist tomorrow")).due == Fixed.days(1, hour: 9))
    }
    @Test func todayWithTime() throws {
        #expect(try #require(parse("standup today 3pm")).due == Fixed.days(0, hour: 15))
    }
    @Test func timeAlreadyPastRollsToTomorrow() throws {
        #expect(try #require(parse("stretch 8am")).due == Fixed.days(1, hour: 8))
    }
    @Test func sameWeekdayMeansNextWeek() throws {
        #expect(try #require(parse("review on wed")).due == Fixed.days(7, hour: 9))
    }
    @Test func twentyFourHourClock() throws {
        #expect(try #require(parse("deploy tomorrow 18:30")).due == Fixed.calendar.date(
            bySettingHour: 18, minute: 30, second: 0, of: Fixed.days(1))!)
    }
    @Test func relativeDays() throws {
        #expect(try #require(parse("renew passport in 3 days")).due == Fixed.days(3, hour: 9))
    }
    @Test func landmarkSigil() throws {
        let p = try #require(parse("buy milk ^Party"))
        #expect(p.title == "buy milk")
        #expect(p.landmark == "Party")
    }
    @Test func emptyAndWhitespaceAreNil() {
        #expect(parse("") == nil)
        #expect(parse("   \n ") == nil)
    }
    @Test func onlySigilsAreNil() {
        #expect(parse("#") == nil)
        #expect(parse("@ # ^") == nil)
    }
    @Test func longTitleSurvivesIntact() throws {
        let long = String(repeating: "x", count: 500)
        #expect(try #require(parse(long)).title == long)
    }
    @Test func dateWordOnlyIsNil() { #expect(parse("tomorrow") == nil) }
}
