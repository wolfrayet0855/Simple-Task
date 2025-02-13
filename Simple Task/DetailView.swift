//
//  DetailView.swift
//  Simple Task
//
//  Redesigned for a modern, clean look using Form and grouped sections.
//  Updated to hide the default back button.
//

import SwiftUI
import SwiftData
import UserNotifications

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext

    @State var toDo: ToDo

    // For adding new subtasks
    @State private var newSubTaskName = ""

    func scheduleNotification(for todo: ToDo) {
        // Only schedule if reminder is on and the task isn’t already completed
        guard todo.reminderIsOn && !todo.isCompleted else { return }
        let content = UNMutableNotificationContent()
        content.title = todo.item
        content.body = "Reminder: \(todo.item) is due!"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: todo.dueDate
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
                
                Section(header: Text("Reminder").font(.headline)) {
                    Toggle("Enable Reminder", isOn: $toDo.reminderIsOn)
                    if toDo.reminderIsOn {
                        Toggle("All Day", isOn: $toDo.isAllDay)
                        DatePicker(
                            "Due Date",
                            selection: $toDo.dueDate,
                            displayedComponents: toDo.isAllDay ? .date : [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section(header: Text("Notes").font(.headline)) {
                    TextEditor(text: $toDo.notes)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }
                
                Section {
                    Toggle("Completed", isOn: $toDo.isCompleted)
                }
                
                Section(header: Text("Subtasks").font(.headline)) {
                    ForEach(toDo.subtasks) { subtask in
                        HStack {
                            Button(action: { subtask.isCompleted.toggle() }) {
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
            .navigationBarBackButtonHidden(true)  // Hides the default back button
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
                        do {
                            try modelContext.save()
                            scheduleNotification(for: toDo)
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

#Preview {
    NavigationStack {
        DetailView(toDo: ToDo(item: "Sample Task"))
            .modelContainer(for: [ToDo.self, SubTask.self])
    }
}

