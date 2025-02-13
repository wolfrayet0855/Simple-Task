//
//  DetailView.swift
//  Simple Task
//
//  Redesigned: Due Date is required and now includes an integrated "All Day" toggle.
//  Reminder uses the selected due date for notifications.
//

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
                
                // Due Date section now includes the All Day option.
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
                
                Section(header: Text("Category").font(.headline)) {
                    Picker("Category", selection: $toDo.category) {
                        Text("Work").tag("Work")
                        Text("Personal").tag("Personal")
                        Text("Fitness").tag("Fitness")
                        Text("Shopping").tag("Shopping")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Reminder").font(.headline)) {
                    Toggle("Enable Reminder", isOn: $toDo.reminderIsOn)
                    if toDo.reminderIsOn {
                        Text("Reminder will be set for the selected due date.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Notes").font(.headline)) {
                    TextEditor(text: $toDo.notes)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3)))
                }
                
                Section {
                    Toggle("Completed", isOn: $toDo.isCompleted)
                }
                
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

