import SwiftUI
import SimpleTaskKit

/// Date, time and reminder rows. Each tap expands its editor inline.
struct WhenSection: View {
    @Bindable var task: ToDo
    @Binding var dateExpanded: Bool
    let edit: (() throws -> Void) -> Void
    let remindChanged: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var customReminder = false

    private var calendar: Calendar { .current }
    private var anim: Animation { reduceMotion ? .easeInOut(duration: 0.2) : SheetTokens.reflow }

    var body: some View {
        SheetGroup {
            dateRow
            if dateExpanded { dateEditor }
            divider
            timeRow
            divider
            remindRow
            if task.reminderIsOn { remindEditor }
        }
        .tint(Tokens.ember)
    }

    private var divider: some View {
        Rectangle().fill(SheetTokens.contour).frame(height: 1).padding(.leading, 56)
    }

    // MARK: Date

    private var dateValue: String {
        guard task.isDated else { return "No date" }
        let day = task.dueDate
        let rel: String
        if calendar.isDateInToday(day) { rel = "Today" }
        else if calendar.isDateInTomorrow(day) { rel = "Tomorrow" }
        else { return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) }
        return rel + ", " + day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var dateRow: some View {
        Button { withAnimation(anim) { dateExpanded.toggle() } } label: {
            SheetRow(symbol: "calendar", label: "Date") {
                Text(dateValue).font(.body).foregroundStyle(SheetTokens.inkSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(dateValue)
        .accessibilityHint(dateExpanded ? "Collapse the calendar" : "Expand the calendar")
    }

    private var dateEditor: some View {
        VStack(spacing: 4) {
            DatePicker("Date", selection: Binding(
                get: { task.dueDate },
                set: { newValue in edit { try TaskEdits.setWhen(.at(newValue, allDay: task.isAllDay), on: task, in: context) } }
            ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Tokens.ember)
            if task.isDated {
                Button("Clear date") {
                    edit { try TaskEdits.setWhen(.undated, on: task, in: context) }
                    withAnimation(anim) { dateExpanded = false }
                }
                .font(.body).foregroundStyle(Tokens.ink)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 12).padding(.bottom, 8)
        .transition(.opacity)
    }

    // MARK: Time

    private var timeRow: some View {
        SheetRow(symbol: "clock", label: "Time") {
            if task.isDated && !task.isAllDay {
                DatePicker("Time", selection: Binding(
                    get: { task.dueDate },
                    set: { newValue in edit { try TaskEdits.setWhen(.at(newValue, allDay: false), on: task, in: context) } }
                ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            Toggle("Time", isOn: Binding(
                get: { task.isDated && !task.isAllDay },
                set: { on in edit { try TaskEdits.setWhen(.at(task.dueDate, allDay: !on), on: task, in: context) } }
            ))
            .labelsHidden()
            .disabled(!task.isDated)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Remind

    private var remindRow: some View {
        SheetRow(symbol: "bell", label: "Remind") {
            Toggle("Remind", isOn: Binding(
                get: { task.reminderIsOn },
                set: { on in
                    withAnimation(anim) {
                        let fallback = task.isDated && task.dueDate > .now ? task.dueDate : Date.now.addingTimeInterval(3600)
                        edit { try TaskEdits.setReminder(on: on, at: on && task.reminderDate <= .now ? fallback : nil, on: task, in: context) }
                    }
                    remindChanged()
                }
            ))
            .labelsHidden()
        }
    }

    private struct Chip: Identifiable {
        let id: String
        let title: String
        let offset: TaskEdits.ReminderOffset?
    }

    private let chips = [
        Chip(id: "at", title: "At time", offset: .atTime),
        Chip(id: "10", title: "10 min before", offset: .tenMinutesBefore),
        Chip(id: "60", title: "1 hr before", offset: .oneHourBefore),
        Chip(id: "morning", title: "Morning of (9:00)", offset: .morningOf),
        Chip(id: "custom", title: "Custom…", offset: nil),
    ]

    private func isSelected(_ chip: Chip) -> Bool {
        if let offset = chip.offset {
            guard task.isDated, !customReminder else { return false }
            return TaskEdits.reminderDate(offset, due: task.dueDate) == task.reminderDate
        }
        let matchesAny = task.isDated && TaskEdits.ReminderOffset.allCases.contains {
            TaskEdits.reminderDate($0, due: task.dueDate) == task.reminderDate
        }
        return customReminder || !matchesAny
    }

    private var remindEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(chips) { chip in
                        let selected = isSelected(chip)
                        Button {
                            if let offset = chip.offset {
                                customReminder = false
                                edit { try TaskEdits.setReminder(on: true, at: TaskEdits.reminderDate(offset, due: task.dueDate), on: task, in: context) }
                            } else {
                                customReminder = true
                            }
                            remindChanged()
                        } label: {
                            Text(chip.title).font(.subheadline)
                                .foregroundStyle(selected ? Color.white : Tokens.ink)
                                .padding(.horizontal, 12).frame(minHeight: 36)
                                .background(Capsule().fill(selected ? Tokens.ember : SheetTokens.contour))
                        }
                        .buttonStyle(.plain)
                        .disabled(chip.offset != nil && !task.isDated)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            if isSelected(chips[4]) {
                DatePicker("Remind at", selection: Binding(
                    get: { task.reminderDate },
                    set: { newValue in
                        edit { try TaskEdits.setReminder(on: true, at: newValue, on: task, in: context) }
                        remindChanged()
                    }
                ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .font(.body)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
        .transition(.opacity)
    }
}
