import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

@Suite(.serialized) struct BootstrapTests {
    func tempDir() throws -> URL {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    func seedLegacy(at url: URL, titles: [String]) throws {
        let container = try ModelContainer(
            for: SchemaV1.ToDo.self, SchemaV1.SubTask.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let ctx = ModelContext(container)
        for t in titles { ctx.insert(SchemaV1.ToDo(item: t)) }
        try ctx.save()
    }
    func defaults() -> UserDefaults { UserDefaults(suiteName: "boot.\(UUID().uuidString)")! }

    @Test func mismatchFailsWithRecoveryStateAndLeavesLegacyIntact() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let group = dir.appendingPathComponent("group/SimpleTask.store")
        try seedLegacy(at: legacy, titles: ["a", "b", "c"])
        let before = try Data(contentsOf: legacy)
        Store.relocationCountsOverride = (tasks: 2, subtasks: 0)
        defer { Store.relocationCountsOverride = nil }

        let result = Store.tryBootstrap(legacyURL: legacy, groupURL: group, defaults: defaults())

        guard case .failed(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure == .relocationMismatch(expected: 3, got: 2))
        #expect(failure.diagnosticCode == "WM-R1 3/2")
        #expect(try Data(contentsOf: legacy) == before)
    }

    @Test func retryAfterCauseIsRemovedSucceeds() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let group = dir.appendingPathComponent("group/SimpleTask.store")
        let d = defaults()
        try seedLegacy(at: legacy, titles: ["a", "b"])
        Store.relocationCountsOverride = (tasks: 0, subtasks: 0)
        _ = Store.tryBootstrap(legacyURL: legacy, groupURL: group, defaults: d)
        Store.relocationCountsOverride = nil

        guard case .ready(let container, let moved) = Store.tryBootstrap(legacyURL: legacy, groupURL: group, defaults: d)
        else { Issue.record("expected ready"); return }
        #expect(moved == .moved(rows: 2))
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ToDo>()) == 2)
        #expect(d.string(forKey: "storeLocation") == "group")
    }

    @Test func corruptGroupStoreReportsOtherWithoutTaskText() throws {
        let dir = try tempDir()
        let group = dir.appendingPathComponent("SimpleTask.store")
        try Data(repeating: 7, count: 4096).write(to: group)
        let result = Store.tryBootstrap(legacyURL: dir.appendingPathComponent("none.store"), groupURL: group, defaults: defaults())
        guard case .failed(let failure) = result, case .other(let code) = failure else { Issue.record("expected other"); return }
        #expect(!code.isEmpty)
    }

    @Test func outOfSpaceIsClassified() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)
        #expect(BootFailure.classify(error) == .outOfSpace)
        let wrapped = NSError(domain: "X", code: 1, userInfo: [NSUnderlyingErrorKey: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))])
        #expect(BootFailure.classify(wrapped) == .outOfSpace)
    }

    @Test func legacyBackupReadsRowsAndExportsJSONWithoutWriting() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        try seedLegacy(at: legacy, titles: ["Pay rent", "Call mum"])
        let rows = try LegacyBackup.rows(at: legacy)
        #expect(Set(rows.map(\.title)) == ["Pay rent", "Call mum"])
        let json = try String(decoding: LegacyBackup.json(at: legacy), as: UTF8.self)
        #expect(json.contains("Pay rent"))
        #expect(try LegacyBackup.rows(at: dir.appendingPathComponent("missing.store")).isEmpty)
    }
}
