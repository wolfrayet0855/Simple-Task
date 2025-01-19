//
//  Simple TaskView.swift
//  Simple Task
//

import SwiftUI
import SwiftData
import UserNotifications

enum SortOption: String, CaseIterable {
    case today = "Today"
    case alphabetical = "A-Z"
    case chronological = "Date"
    case completed = "Not Done"
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
        case .alphabetical:
            _toDos = Query(sort: \.item, animation: .default)
        case .chronological:
            _toDos = Query(sort: \.dueDate)
        case .completed:
            _toDos = Query(filter: #Predicate { $0.isCompleted == false })
        }
    }

    var sortedToDos: [ToDo] {
        switch sortSelection {
        case .today:
            return toDos.sorted(by: { $0.dueDate < $1.dueDate })
        case .alphabetical:
            return toDos.sorted(by: { $0.item < $1.item })
        case .chronological:
            return toDos.sorted(by: { $0.dueDate < $1.dueDate })
        case .completed:
            return toDos.filter { !$0.isCompleted }
        }
    }

    var body: some View {
        List {
            ForEach(sortedToDos) { toDo in
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: toDo.isCompleted ? "checkmark.rectangle" : "rectangle")
                            .onTapGesture {
                                toDo.isCompleted.toggle()
                            }
                        NavigationLink {
                            DetailView(toDo: toDo)
                        } label: {
                            Text(toDo.item)
                        }
                    }
                    .font(.title2)
                    
                    // Show date/time only if reminder is on
                    if toDo.reminderIsOn {
                        HStack {
                            // If it's all day, omit time; otherwise show time
                            if toDo.isAllDay {
                                Text(toDo.dueDate.formatted(date: .abbreviated, time: .omitted))
                            } else {
                                Text(toDo.dueDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            
                            // Calendar icon to confirm there's a reminder
                            Image(systemName: "calendar.badge.clock")
                                .symbolRenderingMode(.multicolor)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(toDo)
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
                .navigationTitle("Actions:")
                .navigationBarTitleDisplayMode(.automatic)
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
                            ForEach(SortOption.allCases, id: \.self) { sortOrder in
                                Text(sortOrder.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .sheet(isPresented: $sheetIsPresented) {
                    NavigationStack {
                        DetailView(toDo: ToDo())
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
