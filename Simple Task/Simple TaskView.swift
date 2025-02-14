import SwiftUI
import SwiftData
import UserNotifications

// Define the sort options.
enum SortOption: String, CaseIterable {
    case today = "Today"
    case chronological = "Date"
    case open = "Open"
    case closed = "Closed"
}

// Define the sorted list view.
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
        case .chronological:
            _toDos = Query(sort: \.dueDate)
        case .open:
            _toDos = Query(filter: #Predicate { !$0.isCompleted })
        case .closed:
            _toDos = Query(filter: #Predicate { $0.isCompleted })
        }
    }

    var sortedToDos: [ToDo] {
        return toDos.sorted { $0.dueDate < $1.dueDate }
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
                            NavigationLink(destination: DetailView(toDo: toDo)) {
                                Text(toDo.item)
                                    .font(.headline)
                            }
                        }
                        // Always show the due date (not the reminder date)
                        HStack(spacing: 4) {
                            if toDo.isAllDay {
                                Text(toDo.dueDate, format: .dateTime.month().day().year())
                            } else {
                                Text(toDo.dueDate, format: .dateTime.month().day().hour().minute())
                            }
                            Image(systemName: "calendar")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
                // Left swipe action to toggle completion.
                .swipeActions(edge: .leading) {
                    Button {
                        toDo.isCompleted.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(toDo.isCompleted ? "Undo" : "Complete", systemImage: toDo.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                    }
                    .tint(toDo.isCompleted ? .gray : .green)
                }
                // Right swipe action for deletion.
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

// Main view that wraps SortedToDoList and provides navigation.
struct ToDoListView: View {
    @State private var sheetIsPresented = false
    @State private var sortSelection: SortOption = .today
    @State private var graphIsActive = false

    var body: some View {
        NavigationStack {
            SortedToDoList(sortSelection: sortSelection)
                .navigationTitle("Tasks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            sheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        Button {
                            graphIsActive = true
                        } label: {
                            Image(systemName: "chart.bar")
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
                .navigationDestination(isPresented: $graphIsActive) {
                    GraphView()
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

