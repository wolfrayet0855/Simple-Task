import SwiftUI
import SimpleTaskKit

/// Subtasks in order: check, rename, reorder through the context menu, add at the bottom.
struct StepsSection: View {
    @Bindable var task: ToDo
    let edit: (() throws -> Void) -> Void

    @Environment(\.modelContext) private var context
    @State private var newStep = ""
    @FocusState private var addFocused: Bool

    var body: some View {
        let steps = TaskEdits.orderedSteps(task)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SheetLabel("Steps")
                Spacer()
                Button { addFocused = true } label: {
                    Label("Smaller", systemImage: "scissors").font(.subheadline)
                        .foregroundStyle(Tokens.ink)
                }
                .accessibilityHint("Break this task into a smaller step")
            }
            SheetGroup {
                ForEach(steps) { step in
                    StepRow(step: step, edit: edit,
                            moveUp: { edit { try TaskEdits.moveStep(step, by: -1, in: context) } },
                            moveDown: { edit { try TaskEdits.moveStep(step, by: 1, in: context) } },
                            remove: { edit { try TaskEdits.removeStep(step, in: context) } })
                    Rectangle().fill(SheetTokens.contour).frame(height: 1).padding(.leading, 50)
                }
                HStack(spacing: 12) {
                    Image(systemName: "plus").frame(width: 22).foregroundStyle(SheetTokens.inkSecondary)
                        .accessibilityHidden(true)
                    TextField("Add a step", text: $newStep)
                        .font(.body)
                        .focused($addFocused)
                        .submitLabel(.next)
                        .onSubmit {
                            let text = newStep
                            newStep = ""
                            edit { try TaskEdits.addStep(text, to: task, in: context) }
                            addFocused = true
                        }
                }
                .padding(.horizontal, 16).frame(minHeight: 48)
            }
        }
    }
}

private struct StepRow: View {
    @Bindable var step: SubTask
    let edit: (() throws -> Void) -> Void
    let moveUp: () -> Void
    let moveDown: () -> Void
    let remove: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 12) {
            Button { edit { try TaskEdits.toggleStep(step, in: context) } } label: {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(step.isCompleted ? Tokens.ember : SheetTokens.inkSecondary)
                    .frame(width: 22, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.isCompleted ? "Done" : "Not done")
            TextField("Step", text: $step.name)
                .font(.body)
                .strikethrough(step.isCompleted)
                .foregroundStyle(step.isCompleted ? SheetTokens.inkTertiary : Tokens.ink)
        }
        .padding(.horizontal, 16).frame(minHeight: 48)
        .contextMenu {
            Button("Move up", systemImage: "arrow.up", action: moveUp)
            Button("Move down", systemImage: "arrow.down", action: moveDown)
            Button("Delete step", systemImage: "trash", action: remove)
        }
        .accessibilityAction(named: "Move up", moveUp)
        .accessibilityAction(named: "Move down", moveDown)
        .accessibilityAction(named: "Delete step", remove)
    }
}
