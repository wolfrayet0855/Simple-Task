//
//  TaskData.swift
//  Simple Task
//
//  Created by user on 2/13/25.
//


//
//  GraphView.swift
//  Simple Task
//

import SwiftUI
import SwiftData
import Charts

// Helper model to aggregate task data per day
struct TaskData: Identifiable {
    let id = UUID()
    let date: Date
    let open: Int
    let closed: Int
}

struct GraphView: View {
    @Query var tasks: [ToDo]

    // Aggregate tasks by the start of their due date
    var aggregatedData: [TaskData] {
        let grouped = Dictionary(grouping: tasks) { task in
            Calendar.current.startOfDay(for: task.dueDate)
        }
        return grouped.map { (date, tasks) in
            let closedCount = tasks.filter { $0.isCompleted }.count
            let openCount = tasks.count - closedCount
            return TaskData(date: date, open: openCount, closed: closedCount)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack {
            if aggregatedData.isEmpty {
                Text("No tasks available for graph.")
                    .padding()
            } else {
                Chart {
                    ForEach(aggregatedData) { data in
                        // Open tasks represented in blue
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Open", data.open)
                        )
                        .foregroundStyle(.blue)
                        
                        // Closed tasks represented in green
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Closed", data.closed)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Task Graph")
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GraphView()
                .modelContainer(for: [ToDo.self, SubTask.self])
        }
    }
}
