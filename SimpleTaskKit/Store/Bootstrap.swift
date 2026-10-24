import Foundation
import SwiftData

public enum BootFailure: Equatable {
    case relocationMismatch(expected: Int, got: Int)
    case outOfSpace
    case other(code: String)

    /// Safe to read aloud to support: domain, code and counts only, never task text.
    public var diagnosticCode: String {
        switch self {
        case .relocationMismatch(let expected, let got): "WM-R1 \(expected)/\(got)"
        case .outOfSpace: "WM-S1"
        case .other(let code): "WM-X \(code)"
        }
    }

    static func classify(_ error: Error) -> BootFailure {
        if let reloc = error as? RelocationError, case .rowCountMismatch(let expected, let got) = reloc {
            return .relocationMismatch(expected: expected, got: got)
        }
        var current: NSError? = error as NSError
        while let ns = current {
            if (ns.domain == NSCocoaErrorDomain && ns.code == NSFileWriteOutOfSpaceError)
                || (ns.domain == NSPOSIXErrorDomain && ns.code == Int(ENOSPC)) { return .outOfSpace }
            current = ns.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        let ns = error as NSError
        return .other(code: "\(ns.domain)#\(ns.code)")
    }
}

public enum Bootstrap {
    case ready(ModelContainer, RelocationResult)
    case failed(BootFailure)
}

extension Bootstrap: @unchecked Sendable {}

extension Store {
    /// Test and debug hook: replaces the counts read back from the staged copy so a mismatch can be forced.
    public nonisolated(unsafe) static var relocationCountsOverride: (tasks: Int, subtasks: Int)?

    /// App entry point: relocate, open (migrating if needed), reconcile. Never deletes legacy files on failure.
    public static func tryBootstrap(
        legacyURL: URL = Store.legacyStoreURL, groupURL: URL = Store.defaultStoreURL,
        defaults: UserDefaults = Store.groupDefaults
    ) -> Bootstrap {
        do {
            let result = try relocateIfNeeded(legacyURL: legacyURL, groupURL: groupURL, defaults: defaults)
            let container = try makeContainer(storeURL: groupURL)
            try reconcile(context: ModelContext(container))
            return .ready(container, result)
        } catch {
            return .failed(BootFailure.classify(error))
        }
    }
}
