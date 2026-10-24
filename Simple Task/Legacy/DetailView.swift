import SimpleTaskKit
import SwiftUI
import SwiftData
import UserNotifications

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var categoryManager: CategoryManager  // Shared category manager

    @State var toDo: ToDo
    @State private var newSubTaskName = ""

    func scheduleNotification(for todo: ToDo) {
        Task { await Scheduler().schedule(todo) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details").font(.headline)) {
                    TextField("Enter task name...", text: $toDo.item)
                        .font(.title2)
                }
                
                Section(header: Text("Due Date").font(.headline)) {
                    Toggle("Has a date", isOn: $toDo.isDated)
                    if toDo.isDated {
                        DatePicker(
                            "Select Due Date",
                            selection: $toDo.dueDate,
                            displayedComponents: toDo.isAllDay ? .date : [.date, .hourAndMinute]
                        )
                        .accentColor(.primary)

                        Toggle("All Day", isOn: $toDo.isAllDay)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                
                Section(header: Text("Reminder").font(.headline)) {
                    Toggle("Enable Reminder", isOn: $toDo.reminderIsOn)
                    if toDo.reminderIsOn {
                        DatePicker(
                            "Select Reminder Date",
                            selection: $toDo.reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accentColor(.primary)
                    }
                }
                
                Section(header: Text("Category").font(.headline)) {
                    Picker("Select Category", selection: $toDo.category) {
                        ForEach(categoryManager.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Subtasks").font(.headline)) {
                    ForEach(toDo.subtasks ?? []) { subtask in
                        HStack {
                            Button(action: {
                                subtask.isCompleted.toggle()
                            }) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .green : .primary)
                            }
                            Text(subtask.name)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let removedSubTask = (toDo.subtasks ?? [])[index]
                            modelContext.delete(removedSubTask)
                        }
                    }
                    
                    HStack {
                        TextField("Add new subtask", text: $newSubTaskName)
                        Button(action: {
                            guard !newSubTaskName.isEmpty else { return }
                            let newSubTask = SubTask(name: newSubTaskName, isCompleted: false, parent: toDo)
                            toDo.subtasks = (toDo.subtasks ?? []) + [newSubTask]
                            newSubTaskName = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // New Completion section to manually mark the task complete.
                Section(header: Text("Completion").font(.headline)) {
                    Toggle("Mark as Complete", isOn: Binding(
                        get: { toDo.isCompleted },
                        set: { done in
                            if done {
                                _ = try? Completion.complete(toDo, in: modelContext)
                            } else {
                                toDo.isCompleted = false
                                toDo.completedAt = nil
                                toDo.stateRaw = "active"
                            }
                        }))
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if toDo.modelContext == nil {
                            modelContext.insert(toDo)
                        }
                        toDo.modifiedAt = .now
                        if !toDo.isCompleted, toDo.isDated, toDo.stateRaw == "shelved" { toDo.stateRaw = "active" }
                        do {
                            try Capture.setTag(toDo.category, on: toDo, in: modelContext)
                            try modelContext.save()
                            scheduleNotification(for: toDo)
                            Widgets.reload()
                        } catch {
                            print("Error saving: \(error)")
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}



