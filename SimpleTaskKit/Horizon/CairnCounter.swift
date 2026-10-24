import Foundation

/// Stones that stay in the Cairn after their finished task is deleted.
public enum CairnCounter {
    static let key = "cairn.removed"

    public static func removed(defaults: UserDefaults = Store.groupDefaults) -> Int { defaults.integer(forKey: key) }

    public static func recordRemoval(defaults: UserDefaults = Store.groupDefaults) {
        defaults.set(removed(defaults: defaults) + 1, forKey: key)
    }
}
