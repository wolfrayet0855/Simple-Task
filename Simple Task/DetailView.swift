//
//  DetailView.swift
//  ToDoList
//
//  Created by user on 9/13/24.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var toDo: ToDo
    @Environment(\.modelContext) var modelContext

    func scheduleNotification(for todo: ToDo) {
        guard todo.reminderIsOn else { return }
        let content = UNMutableNotificationContent()
        content.title = todo.item
        content.body = "Reminder: \(todo.item) is due!"
        content.sound = UNNotificationSound.default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: todo.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: todo.item, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    var body: some View { // Correctly defined body property
        List {
            TextField("Input task here..", text: $toDo.item)
                .font(.title)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical)
                .listRowSeparator(.hidden)

            Toggle("Set Reminder:", isOn: $toDo.reminderIsOn )
                .padding(.top)
                .listRowSeparator(.hidden)

            DatePicker("Date", selection: $toDo.dueDate)
                .listRowSeparator(.hidden)
                .padding(.bottom)
                .disabled(!toDo.reminderIsOn)

            Text("Notes:")
                .padding(.top)

            TextField("Notes", text: $toDo.notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .listRowSeparator(.hidden)

            Toggle("Completed", isOn: $toDo.isCompleted)
                .padding(.top)
                .listRowSeparator(.hidden)
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
                    print("Saving Task: \(toDo.item), Reminder: \(toDo.reminderIsOn), Due Date: \(toDo.dueDate)")
                    modelContext.insert(toDo)
                    scheduleNotification(for: toDo) // Schedule notification when saving
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
            .modelContainer(for: ToDo.self)
    }
}
