import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct RelocationTests {
    func tempDir() throws -> URL {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    /// Mirrors how the shipped app created its store: unversioned, `ModelContainer(for:)`.
    func seedLegacy(at url: URL, titles: [String]) throws {
        let container = try ModelContainer(
            for: SchemaV1.ToDo.self, SchemaV1.SubTask.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let ctx = ModelContext(container)
        for t in titles { ctx.insert(SchemaV1.ToDo(item: t)) }
        try ctx.save()
    }

    func defaults() -> UserDefaults {
        UserDefaults(suiteName: "reloc.\(UUID().uuidString)")!
    }

    @Test func relocationPreservesRowCountsAndDeletesLegacyOnlyAfterVerify() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let group = dir.appendingPathComponent("group/SimpleTask.store")
        try seedLegacy(at: legacy, titles: ["a", "b", "c"])

        let result = try Store.relocateIfNeeded(legacyURL: legacy, groupURL: group, defaults: defaults())

        #expect(result == .moved(rows: 3))
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        let ctx = ModelContext(try Store.makeContainer(storeURL: group))
        #expect(try ctx.fetchCount(FetchDescriptor<ToDo>()) == 3)
    }

    @Test func relocationTwiceIsNoOp() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let group = dir.appendingPathComponent("group/SimpleTask.store")
        let d = defaults()
        try seedLegacy(at: legacy, titles: ["a", "b"])
        _ = try Store.relocateIfNeeded(legacyURL: legacy, groupURL: group, defaults: d)

        let second = try Store.relocateIfNeeded(legacyURL: legacy, groupURL: group, defaults: d)

        #expect(second == .alreadyDone)
        let ctx = ModelContext(try Store.makeContainer(storeURL: group))
        #expect(try ctx.fetchCount(FetchDescriptor<ToDo>()) == 2)
    }

    @Test func missingLegacyStoreMovesNothing() throws {
        let dir = try tempDir()
        let result = try Store.relocateIfNeeded(
            legacyURL: dir.appendingPathComponent("default.store"),
            groupURL: dir.appendingPathComponent("SimpleTask.store"),
            defaults: defaults())
        #expect(result == .nothingToMove)
    }

    @Test func interruptedCopyIsRedoneFromIntactLegacy() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let groupDir = dir.appendingPathComponent("group")
        try FileManager.default.createDirectory(at: groupDir, withIntermediateDirectories: true)
        let group = groupDir.appendingPathComponent("SimpleTask.store")
        try Data("garbage".utf8).write(to: group)   // partial copy from a crashed run, flag never set
        try seedLegacy(at: legacy, titles: ["a", "b", "c"])

        let result = try Store.relocateIfNeeded(legacyURL: legacy, groupURL: group, defaults: defaults())

        #expect(result == .moved(rows: 3))
    }

    @Test func relocationLeavesNoStagingFilesBehind() throws {
        let dir = try tempDir()
        let legacy = dir.appendingPathComponent("default.store")
        let groupDir = dir.appendingPathComponent("group")
        try seedLegacy(at: legacy, titles: ["a"])
        _ = try Store.relocateIfNeeded(legacyURL: legacy, groupURL: groupDir.appendingPathComponent("SimpleTask.store"), defaults: defaults())
        let names = try FileManager.default.contentsOfDirectory(atPath: groupDir.path)
        #expect(!names.contains { $0.contains("migrating") })
        #expect(names.contains("SimpleTask.store"))
    }
}
