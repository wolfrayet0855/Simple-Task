///
//  ToDoListView.swift
//  ToDoList
//
//  Created by user on 9/13/24.
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
              let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: today)!)
              _toDos = Query(filter: #Predicate {
                  $0.dueDate >= today && $0.dueDate < tomorrow
              })
        case .alphabetical:
            _toDos = Query(sort: \.item, animation: .default)
        case .chronological:
            _toDos = Query(sort: \.dueDate)
       case .completed:
            _toDos = Query(filter: #Predicate {$0.isCompleted == false})

        }
    }
    
    var body: some View{
        List {
            ForEach(toDos) {toDo in
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: toDo.isCompleted ? "checkmark.rectangle": "rectangle")
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
                    HStack {
                        Text(toDo.dueDate.formatted(date: .abbreviated, time:
                                .shortened))
                        .foregroundStyle(.secondary)
                        if(toDo.reminderIsOn) {
                            Image(systemName: "calendar.badge.clock")
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                }
                .swipeActions{
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
                            ForEach(SortOption.allCases, id: \.self) {sortOrder in
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
    }
}
