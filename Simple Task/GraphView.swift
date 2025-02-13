//
//  GraphView.swift
//  Simple Task
//

import SwiftUI
import SwiftData
import Charts

// Helper model for aggregating task data per month
struct TaskData: Identifiable {
    let id = UUID()
    let month: Date
    let open: Int
    let closed: Int
}

// A reusable card view for modern styling
struct CardView<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        content()
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct GraphView: View {
    @Query var tasks: [ToDo]

    // Aggregate tasks by month (using the first day of each month)
    var aggregatedData: [TaskData] {
        let grouped = Dictionary(grouping: tasks) { task in
            let components = Calendar.current.dateComponents([.year, .month], from: task.dueDate)
            return Calendar.current.date(from: components)!
        }
        return grouped.map { (month, tasks) in
            let closedCount = tasks.filter { $0.isCompleted }.count
            let openCount = tasks.count - closedCount
            return TaskData(month: month, open: openCount, closed: closedCount)
        }
        .sorted { $0.month < $1.month }
    }
    
    // Formatter for displaying the month in the ledger
    var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if aggregatedData.isEmpty {
                    Text("No tasks available for graph.")
                        .font(.headline)
                        .padding()
                } else {
                    Text("Monthly Task Overview")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Chart Card
                    CardView {
                        Chart {
                            ForEach(aggregatedData) { data in
                                BarMark(
                                    x: .value("Month", data.month, unit: .month),
                                    y: .value("Open", data.open)
                                )
                                .foregroundStyle(.blue)
                                
                                BarMark(
                                    x: .value("Month", data.month, unit: .month),
                                    y: .value("Closed", data.closed)
                                )
                                .foregroundStyle(.green)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Ledger Card
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ledger")
                                .font(.headline)
                            ForEach(aggregatedData) { data in
                                HStack {
                                    Text(data.month, formatter: monthFormatter)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Label("\(data.open)", systemImage: "circle.fill")
                                            .foregroundColor(.blue)
                                        Label("\(data.closed)", systemImage: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
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

