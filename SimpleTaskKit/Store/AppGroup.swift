import Foundation

public enum AppGroup {
    public static let id = "group.beta.SimpleTask"

    /// App Group container when the entitlement is present, else Application Support
    /// (unsigned simulator builds and unit tests have no group container).
    public static func containerURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
            return url
        }
        return URL.applicationSupportDirectory
    }
}
