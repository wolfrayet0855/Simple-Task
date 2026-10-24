import Testing
import Foundation

struct SmokeTests {
    @Test func appBundleLoads() {
        #expect(Bundle(identifier: "beta.SimpleTask") != nil)
    }
}
