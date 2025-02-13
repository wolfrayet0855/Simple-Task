//
//  Simple TaskView.swift
//  Simple Task
//

import SwiftUI
import SwiftData
import UserNotifications

enum SortOption: String, CaseIterable {
    case today = "Today"
    case chronological = "Date"
    case notCompleted = "Open"
    case completed = "Closed"
}

struct SortedToDoList: View {
    @Query var toDos: [ToDo]
    @Environment(\.modelContext) var modelContext
    let sortSelection: SortOption

    init(sortSelection: SortOption) {
        self.sortSelection = sortSelection
        switch self.sortSelection {
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: today)!
            )
            _toDos = Query(filter: #Predicate {
                $0.dueDate >= today && $0.dueDate < tomorrow
            })
        case .chronological:
            _toDos = Query(sort: \.dueDate)
        case .notCompleted:
            _toDos = Query(filter: #Predicate { !$0.isCompleted })
        case .completed:
            _toDos = Query(filter: #Predicate { $0.isCompleted })
        }
    }

    var sortedToDos: [ToDo] {
        return toDos.sorted(by: { $0.dueDate < $1.dueDate })
    }

    var body: some View {
        List {
            ForEach(sortedToDos) { toDo in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                toDo.isCompleted.toggle()
                            }) {
                                Image(systemName: toDo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(toDo.isCompleted ? .green : .primary)
                            }
                            NavigationLink(destination: DetailView(toDo: toDo)) {
                                Text(toDo.item)
                                    .font(.headline)
                            }
                        }
                        if toDo.reminderIsOn {
                            HStack(spacing: 4) {
                                if toDo.isAllDay {
                                    Text(toDo.dueDate, format: .dateTime.month().day().year())
                                } else {
                                    Text(toDo.dueDate, format: .dateTime.month().day().hour().minute())
                                }
                                Image(systemName: "calendar.badge.clock")
                                    .symbolRenderingMode(.multicolor)
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
                .swipeActions {
                    Button(role: .destructive) {
                        modelContext.delete(toDo)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ToDoListView: View {
    @State private var sheetIsPresented = false
    @State private var sortSelection: SortOption = .today

    var body: some View {
        NavigationStack {
            SortedToDoList(sortSelection: sortSelection)
                .navigationTitle("Tasks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            sheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Picker("", selection: $sortSelection) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .sheet(isPresented: $sheetIsPresented) {
                    NavigationStack {
                        DetailView(toDo: ToDo(item: ""))
                    }
                }
        }
    }
}

struct ToDoListView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoListView()
            .modelContainer(for: [ToDo.self, SubTask.self])
    }
}

