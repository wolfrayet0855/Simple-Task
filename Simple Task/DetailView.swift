import SwiftUI
import SwiftData
import UserNotifications

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext

    @State var toDo: ToDo
    @State private var newSubTaskName = ""
    @State private var showAlert = false

    // Ensure the due date is today or later.
    private var isDueDateValid: Bool {
        return toDo.dueDate >= Calendar.current.startOfDay(for: Date())
    }

    func scheduleNotification(for todo: ToDo) {
        guard todo.reminderIsOn && !todo.isCompleted else { return }
        let content = UNMutableNotificationContent()
        content.title = todo.item
        content.body = "Reminder: \(todo.item) is due!"
        content.sound = .default

        // Use the custom reminder date instead of the due date.
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: todo.reminderDate
        )
        let request = UNNotificationRequest(
            identifier: todo.item,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details").font(.headline)) {
                    TextField("Enter task name...", text: $toDo.item)
                        .font(.title2)
                }
                
                // Due Date section remains (with All Day toggle).
                Section(header: Text("Due Date *").font(.headline)) {
                    DatePicker(
                        "Select Due Date",
                        selection: $toDo.dueDate,
                        displayedComponents: toDo.isAllDay ? .date : [.date, .hourAndMinute]
                    )
                    .accentColor(isDueDateValid ? .primary : .red)
                    
                    Toggle("All Day", isOn: $toDo.isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Reminder section with custom reminder date.
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
                
                // Subtasks section.
                Section(header: Text("Subtasks").font(.headline)) {
                    ForEach(toDo.subtasks) { subtask in
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
                            let removedSubTask = toDo.subtasks[index]
                            modelContext.delete(removedSubTask)
                        }
                    }
                    
                    HStack {
                        TextField("Add new subtask", text: $newSubTaskName)
                        Button(action: {
                            guard !newSubTaskName.isEmpty else { return }
                            let newSubTask = SubTask(name: newSubTaskName, isCompleted: false, parent: toDo)
                            toDo.subtasks.append(newSubTask)
                            newSubTaskName = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
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
                        guard isDueDateValid else {
                            showAlert = true
                            return
                        }
                        if toDo.modelContext == nil {
                            modelContext.insert(toDo)
                        }
                        do {
                            try modelContext.save()
                            scheduleNotification(for: toDo)
                        } catch {
                            print("Error saving: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(!isDueDateValid)
                }
            }
            .alert("Invalid Due Date", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please select a due date that is today or later.")
            }
        }
    }
}

