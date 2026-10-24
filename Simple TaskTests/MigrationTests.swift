import Testing
import SwiftData
import Foundation
@testable import SimpleTaskKit

struct MigrationTests {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("store")
    }

    func seedV1(at url: URL, _ build: (ModelContext) -> Void) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
        let context = ModelContext(container)
        build(context)
        try context.save()
    }

    @Test func migratesV1ToV2LosslessAndStable() throws {
        let url = tempURL()
        let due = Date(timeIntervalSince1970: 1_800_000_000)
        try seedV1(at: url) { ctx in
            let a = SchemaV1.ToDo(item: "Send deck", dueDate: due, category: "Work")
            let b = SchemaV1.ToDo(item: "Buy paint", dueDate: due, category: "Errands")
            let c = SchemaV1.ToDo(item: "Pay rent", dueDate: due, isCompleted: true, category: "Personal")
            [a, b, c].forEach(ctx.insert)
            for (i, n) in ["a", "b", "c"].enumerated() {
                let s = SchemaV1.SubTask(name: n, isCompleted: i == 0)
                ctx.insert(s)
                s.parent = a
                a.subtasks.append(s)
                try? ctx.save()   // users add subtasks one at a time; row order follows
            }
        }

        let container = try Store.makeContainer(storeURL: url)
        let ctx = ModelContext(container)
        let tasks = try ctx.fetch(FetchDescriptor<ToDo>(sortBy: [SortDescriptor(\.item)]))
        #expect(tasks.map(\.item) == ["Buy paint", "Pay rent", "Send deck"])
        #expect(tasks.allSatisfy { $0.dueDate == due })
        #expect(Set(tasks.map(\.id)).count == 3)

        let pay = try #require(tasks.first { $0.item == "Pay rent" })
        #expect(pay.isCompleted)
        #expect(pay.completedAt != nil)
        #expect(pay.stateRaw == "done")

        let deck = try #require(tasks.first { $0.item == "Send deck" })
        let subs = (deck.subtasks ?? []).sorted { $0.order < $1.order }
        #expect(subs.map(\.name) == ["a", "b", "c"])
        #expect(subs.map(\.order) == [0, 1, 2])
        #expect(subs.first?.isCompleted == true)
        #expect(Set(subs.map(\.id)).count == 3)

        let tags = try ctx.fetch(FetchDescriptor<SchemaV2.Tag>())
        #expect(tags.count == 6)
        #expect(Set(tags.map(\.name)) == ["Work", "Personal", "Fitness", "Shopping", "Other", "Errands"])
        #expect(deck.tag?.name == "Work")
        #expect(tasks.first { $0.item == "Buy paint" }?.tag?.name == "Errands")
    }

    @Test func emptyV1StoreMigrates() throws {
        let url = tempURL()
        try seedV1(at: url) { _ in }
        let ctx = ModelContext(try Store.makeContainer(storeURL: url))
        #expect(try ctx.fetchCount(FetchDescriptor<ToDo>()) == 0)
        #expect(try ctx.fetchCount(FetchDescriptor<SchemaV2.Tag>()) == 5)
    }

    @Test func duplicateTitlesAreAllowedInV2() throws {
        let ctx = ModelContext(try Store.makeContainer(inMemory: true))
        ctx.insert(ToDo(item: "Call mom"))
        ctx.insert(ToDo(item: "Call mom"))
        try ctx.save()
        let all = try ctx.fetch(FetchDescriptor<ToDo>())
        #expect(all.count == 2)
        #expect(Set(all.map(\.id)).count == 2)
    }

    @Test func reconcileKeepsLatestPerIdAndNeverReopensCompleted() throws {
        let ctx = ModelContext(try Store.makeContainer(inMemory: true))
        let shared = UUID()
        let old = ToDo(item: "Pay rent", isCompleted: true)
        old.id = shared
        old.completedAt = Date(timeIntervalSince1970: 100)
        old.modifiedAt = Date(timeIntervalSince1970: 100)
        let newer = ToDo(item: "Pay rent (edited)")
        newer.id = shared
        newer.modifiedAt = Date(timeIntervalSince1970: 200)
        ctx.insert(old); ctx.insert(newer)
        try ctx.save()

        try Store.reconcile(context: ctx)

        let all = try ctx.fetch(FetchDescriptor<ToDo>())
        #expect(all.count == 1)
        #expect(all[0].item == "Pay rent (edited)")
        #expect(all[0].isCompleted)
        #expect(all[0].completedAt == Date(timeIntervalSince1970: 100))
    }
}
