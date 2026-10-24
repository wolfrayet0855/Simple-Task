import SwiftUI
import SwiftData
import SimpleTaskKit

/// The task editor: autosaves every change, no Save or Cancel.
struct TaskSheet: View {
    @Bindable var task: ToDo
    let onFinish: (UUID) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Query(sort: [SortDescriptor(\Tag.order), SortDescriptor(\Tag.name)]) private var tags: [Tag]

    @State private var detent: PresentationDetent = .medium
    @State private var originalTitle = ""
    @State private var dateExpanded = false
    @State private var showNewTag = false
    @State private var newTagName = ""
    @State private var confirmDelete = false
    @State private var deleted = false
    @State private var finishing = false

    private let scheduler = Scheduler()

    var body: some View {
        NavigationStack {
            Group {
                if deleted { Color.clear } else { content }
            }
            .toolbar { toolbar }
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { if !deleted { finishBar } }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .confirmationDialog("Delete “\(task.isDeleted ? "" : task.item)”?", isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteTask() }
        } message: { Text("This can't be undone.") }
        .alert("New tag", isPresented: $showNewTag) {
            TextField("Name", text: $newTagName)
            Button("Add") { addTag() }
            Button("Cancel", role: .cancel) { newTagName = "" }
        }
        .onAppear { originalTitle = task.item }
        .onDisappear { saveAndSchedule() }
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleField
                WhereItSitsStrip(current: TaskEdits.stop(of: task), onSelect: moveTo)
                WhenSection(task: task, dateExpanded: $dateExpanded, edit: edit, remindChanged: remindChanged)
                section("Weight") {
                    WeightRow(current: Weight(raw: task.weightRaw)) { weight in
                        edit { try TaskEdits.setWeight(weight, on: task, in: context) }
                    }
                }
                section("Tag") {
                    TagRow(tags: tags, selected: task.tag,
                           onSelect: { tag in edit { try TaskEdits.setTag(tag, on: task, in: context) } },
                           onNew: { newTagName = ""; showNewTag = true })
                }
                StepsSection(task: task, edit: edit)
                section("Notes") {
                    SheetGroup {
                        TextField("Notes", text: $task.notes, axis: .vertical)
                            .font(.body).lineLimit(3...12)
                            .padding(16)
                            .onChange(of: task.notes) { task.modifiedAt = .now }
                    }
                }
                pledgeGroup
                trailLine
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 8).padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func section<C: View>(_ label: String, @ViewBuilder _ body: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) { SheetLabel(label); body() }
    }

    private var titleField: some View {
        TextField("Task", text: $task.item, axis: .vertical)
            .font(.title2.weight(.semibold))
            .lineLimit(1...4)
            .submitLabel(.done)
            .onChange(of: task.item) { task.modifiedAt = .now }
    }

    // MARK: Pledge, trail, footer

    private var pledgeGroup: some View {
        let witness = task.pledge?.witness?.displayName
        let by = task.pledge?.byDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return SheetGroup {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Tokens.witness.opacity(0.2)).frame(width: 20, height: 20)
                    Circle().fill(Tokens.witness).frame(width: 10, height: 10)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    if let witness {
                        (Text("Promised to ") + Text(witness).bold()).foregroundStyle(SheetTokens.witnessText)
                        if let by { Text("by \(by)").font(.subheadline).foregroundStyle(SheetTokens.witnessText) }
                    } else {
                        Text("Promise this to someone").foregroundStyle(SheetTokens.inkSecondary)
                    }
                    Text("Witnesses and receipts arrive in a later update.")
                        .font(.footnote).foregroundStyle(SheetTokens.inkTertiary)
                }
            }
            .font(.body)
            .padding(16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(witness.map { "Pledge. Promised to \($0)\(by.map { " by \($0)" } ?? ""). Witness tools arrive in a later update." }
                            ?? "Pledge. Promise this to someone. Witness tools arrive in a later update.")
    }

    @ViewBuilder
    private var trailLine: some View {
        if let landmark = task.landmark {
            let t = task.offsetDays.map { " · T-\($0)" } ?? ""
            Text("▲ On the way to \(landmark.title)\(t)")
                .font(.subheadline).foregroundStyle(Tokens.landmark)
        }
    }

    private var footer: some View {
        let added = task.createdAt.formatted(.dateTime.day().month(.abbreviated))
        let edited = task.modifiedAt.formatted(.dateTime.hour().minute())
        return Text("Added \(added) · Edited \(edited)")
            .font(.caption).foregroundStyle(SheetTokens.inkTertiary)
    }

    // MARK: Toolbar and finish bar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .close) { dismiss() }
        }
        if TaskEdits.canDelete(task) && !deleted {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Delete task", role: .destructive) { confirmDelete = true }
                } label: { Image(systemName: "ellipsis") }
                .accessibilityLabel("More")
            }
        }
    }

    @ViewBuilder
    private var finishBar: some View {
        if task.isCompleted {
            Button { reopen() } label: {
                Text("Reopen").font(.headline).frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.bordered).tint(Tokens.ember)
            .padding(.horizontal, 20).padding(.bottom, 8)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "circle.dotted")
                Text(reduceMotion || voiceOver ? "Finish" : "Hold to finish")
            }
            .font(.headline).foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .glassEffect(.regular.tint(Tokens.ember.opacity(0.25)).interactive(), in: .capsule)
            .holdToComplete(cornerRadius: 28, onComplete: finish, onOpen: { if voiceOver { finish() } })
            .padding(.horizontal, 20).padding(.bottom, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(reduceMotion || voiceOver ? "Finish" : "Hold to finish")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { finish() }
        }
    }

    // MARK: Actions

    /// Runs one edit, swallowing store errors (the next autosave retries).
    private func edit(_ change: () throws -> Void) {
        try? change()
    }

    private func remindChanged() {
        // The scheduler asks for notification permission the first time a reminder is wanted.
        Task { await scheduler.schedule(task) }
    }

    private func moveTo(_ stop: TaskEdits.Stop) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : SheetTokens.reflow) {
            edit { try TaskEdits.move(task, to: stop, in: context) }
            if stop == .beyond { dateExpanded = true }
        }
        Haptics.capture()
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        newTagName = ""
        guard !name.isEmpty else { return }
        edit { try TaskEdits.createTag(name, on: task, in: context) }
    }

    private func finish() {
        guard !finishing else { return }
        finishing = true
        dismiss()
        onFinish(task.id)
    }

    private func reopen() {
        if (try? Completion.undo(task, in: context)) != true {
            edit { try TaskEdits.reopen(task, in: context) }
        }
        Task { await scheduler.schedule(task) }
        Widgets.reload()
    }

    private func deleteTask() {
        let id = task.notificationID
        deleted = true
        do {
            try TaskEdits.delete(task, in: context)
        } catch {
            deleted = false
            return
        }
        scheduler.cancel(notificationID: id)
        Widgets.reload()
        AccessibilityNotification.Announcement("Deleted.").post()
        dismiss()
    }

    private func saveAndSchedule() {
        guard !deleted, !task.isDeleted else { return }
        let trimmed = task.item.trimmingCharacters(in: .whitespacesAndNewlines)
        task.item = trimmed.isEmpty ? originalTitle : trimmed
        for step in TaskEdits.orderedSteps(task) where step.name.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(step)
        }
        try? context.save()
        let scheduler = scheduler
        let task = task
        Task { await scheduler.schedule(task) }
        Widgets.reload()
    }
}
