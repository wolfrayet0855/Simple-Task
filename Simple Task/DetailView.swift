//
//  DetailView.swift
//  Simple Task
//
//  Created by user on 9/13/24.
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
        // Check if the task is completed before scheduling the notification
        guard todo.reminderIsOn && !todo.isCompleted else { return }
        let content = UNMutableNotificationContent()
        content.title = todo.item
        content.body = "Reminder: \(todo.item) is due!"
        content.sound = UNNotificationSound.default

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
        List {
            // Main item fields
            TextField("Input task here..", text: $toDo.item)
                .font(.title)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.default) // Allows emojis
                .padding(.vertical)
                .listRowSeparator(.hidden)

            Toggle("Set Reminder:", isOn: $toDo.reminderIsOn)
                .padding(.top)
                .listRowSeparator(.hidden)

            Toggle("All Day", isOn: $toDo.isAllDay)
                .padding(.top)
                .listRowSeparator(.hidden)
                .disabled(!toDo.reminderIsOn)

            DatePicker(
                "Date",
                selection: $toDo.dueDate,
                displayedComponents: toDo.isAllDay ? .date : [.date, .hourAndMinute]
            )
            .listRowSeparator(.hidden)
            .padding(.bottom)
            .disabled(!toDo.reminderIsOn)

            Text("Notes:")
                .padding(.top)

            TextField("Notes", text: $toDo.notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.default) // Allows emojis
                .listRowSeparator(.hidden)

            Toggle("Completed", isOn: $toDo.isCompleted)
                .padding(.top)
                .listRowSeparator(.hidden)

            // Subtasks Section
            Section("Subtasks") {
                ForEach(toDo.subtasks) { subtask in
                    HStack {
                        Button(action: {
                            subtask.isCompleted.toggle()
                        }) {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(subtask.isCompleted ? .green : .primary)
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
                    TextField("New Subtask", text: $newSubTaskName)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.default) // Allows emojis

                    Button(action: {
                        guard !newSubTaskName.isEmpty else { return }
                        let subtask = SubTask(name: newSubTaskName, isCompleted: false, parent: toDo)
                        toDo.subtasks.append(subtask)
                        newSubTaskName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // Check if the current `toDo` is already in any context:
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
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DetailView(toDo: ToDo())
            .modelContainer(for: [ToDo.self, SubTask.self]) // Updated container
    }
}
