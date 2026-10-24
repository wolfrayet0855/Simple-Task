import SwiftUI
import SwiftData
import SimpleTaskKit

/// The signature screen: a landscape of time. Height is distance; size is weight.
struct HorizonView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\ToDo.dueDate)]) private var todos: [ToDo]

    @State private var toast: Toast?
    @State private var toastTimer: Task<Void, Never>?
    @State private var editing: ToDo?
    @State private var showDebug = false
    @State private var showShelf = false

    private let scheduler = Scheduler()
    private let calendar = Calendar.current

    struct Toast: Equatable { let taskID: UUID; let total: Int }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            field(now: timeline.date)
        }
        .task { await scheduler.reconcile(tasks: todos) }
        .sheet(item: $editing) { todo in
            TaskSheet(task: todo, onFinish: finishFromSheet)
        }
        .sheet(isPresented: $showShelf) {
            ShelfSheet(tasks: shelfTasks, onBringBack: { reschedule($0.id, Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { f, _ in f }), .today) },
                       onOpen: { showShelf = false; open($0.id) })
        }
        #if DEBUG
        .sheet(isPresented: $showDebug) { DebugMenu() }
        #endif
    }

    // MARK: - Field

    @ViewBuilder
    private func field(now: Date) -> some View {
        let model = HorizonModel.build(todos.map(TaskSnapshot.init), cairnTotal: cairnTotal, now: now, calendar: calendar)
        let byID = Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let dusk = Tokens.duskAmount(at: now)
        let calm = model.isEmpty && model.cairnTotal > 0

        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Tokens.skyDay.mix(with: Tokens.skyDusk, by: dusk), Tokens.ground],
                               startPoint: .top, endPoint: .center)
                    .saturation(calm ? 0.7 : 1)
                    .ignoresSafeArea()
                    .animation(Motion.drift, value: calm)

                VStack(spacing: 0) {
                    band(.horizon, model, now, depth: 1, height: 0.08 * h, label: "Far horizon")
                    band(.month, model, now, depth: 0.7, height: 0.16 * h, label: "Within a month")
                    band(.week, model, now, depth: 0.45, height: 0.16 * h, label: "This week")
                    band(.tomorrow, model, now, depth: 0.2, height: 0.14 * h, label: "Tomorrow")
                    Rectangle().fill(Tokens.ink.opacity(0.10)).frame(height: 1).padding(.horizontal, 16)
                    inHand(model, byID, now)
                    slippedRow(model, byID).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    CairnStrip(total: model.cairnTotal, today: completedToday(now))
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 1.5) {
                            #if DEBUG
                            showDebug = true
                            #endif
                        }
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    CaptureBar { parsed in capture(parsed) }
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .padding(.top, 4)

                if let toast { toastView(toast, byID).padding(.bottom, 130).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
        }
    }

    private func band(_ band: Band, _ model: HorizonModel, _ now: Date, depth: Double, height: CGFloat, label: String) -> some View {
        Group {
            if let group = model.groups[band] {
                BandField(group: group, depth: depth, now: now, onOpen: open, accessibilityName: label)
            }
        }
        .frame(height: height)
        .overlay(alignment: .bottomTrailing) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold)).tracking(1.4)
                .foregroundStyle(Tokens.ink.opacity(0.28))
                .padding(.trailing, 16).padding(.bottom, 4)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Tokens.ink.opacity(0.05)).frame(height: 1).padding(.horizontal, 16)
        }
    }

    // MARK: - In Hand

    @ViewBuilder
    private func inHand(_ model: HorizonModel, _ byID: [UUID: ToDo], _ now: Date) -> some View {
        let group = model.groups[.inHand]
        ScrollView {
            VStack(spacing: 12) {
                if model.isEmpty {
                    emptyState(model)
                } else if let group {
                    if let ember = model.ember { card(ember, isEmber: true, byID, now) }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(group.visible.filter { $0.id != model.ember?.id }) { card($0, isEmber: false, byID, now) }
                    }
                    if group.overflow > 0 {
                        Text("+\(group.overflow) more in hand").font(.footnote).foregroundStyle(Tokens.ink.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("In hand")
    }

    private func card(_ task: TaskSnapshot, isEmber: Bool, _ byID: [UUID: ToDo], _ now: Date) -> some View {
        TaskCard(task: task, isEmber: isEmber, now: now)
            .holdToComplete(onComplete: { complete(task.id, byID) }, onOpen: { open(task.id) })
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .opacity, removal: .move(edge: .bottom).combined(with: .opacity)))
            .overlay(alignment: .topTrailing) {
                Menu {
                    Button("Open", systemImage: "square.and.pencil") { open(task.id) }
                    Button("Tomorrow", systemImage: "sunrise") { reschedule(task.id, byID, .tomorrow) }
                    Button("Next week", systemImage: "calendar") { reschedule(task.id, byID, .nextWeek) }
                    Button("Shelf", systemImage: "tray") { reschedule(task.id, byID, .shelf) }
                } label: {
                    Image(systemName: "ellipsis").padding(12).foregroundStyle(Tokens.ink.opacity(0.35))
                }
                .accessibilityLabel("More actions")
            }
            .accessibilityHint("Hold to finish")
            .accessibilityAction(named: "Complete") { complete(task.id, byID) }
            .accessibilityAction(named: "Tomorrow") { reschedule(task.id, byID, .tomorrow) }
            .accessibilityAction(named: "Shelf") { reschedule(task.id, byID, .shelf) }
            .accessibilityAction(named: "Open") { open(task.id) }
    }

    private func emptyState(_ model: HorizonModel) -> some View {
        VStack(spacing: 8) {
            Text(model.cairnTotal > 0 ? "Clear skies." : "Nothing in hand.")
                .font(.title2.weight(.semibold).width(.expanded)).foregroundStyle(Tokens.ink)
            Text(model.cairnTotal > 0 ? "\(model.cairnTotal.formatted()) stones laid." : "Drop a thought below. It lands here.")
                .font(.subheadline).foregroundStyle(Tokens.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 36)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Slipped

    @ViewBuilder
    private func slippedRow(_ model: HorizonModel, _ byID: [UUID: ToDo]) -> some View {
        let slipped = model.groups[.slipped]?.visible ?? []
        let shelfCount = model.groups[.shelf]?.visible.count ?? 0
        if !slipped.isEmpty || shelfCount > 0 {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.haze").foregroundStyle(Tokens.slipped)
                    ForEach(slipped) { task in
                        Button { open(task.id) } label: {
                            Text("\(task.title) · slipped \(slippedDays(task))d")
                                .font(.footnote)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .foregroundStyle(Tokens.slipped)
                                .background(Capsule().fill(Tokens.slipped.opacity(0.14)))
                        }
                        .contextMenu {
                            Button("Today", systemImage: "arrow.uturn.forward") { reschedule(task.id, byID, .today) }
                            Button("Shelf", systemImage: "tray") { reschedule(task.id, byID, .shelf) }
                        }
                    }
                    if shelfCount > 0 {
                        Button { showShelf = true } label: {
                            Label("Shelf · \(shelfCount)", systemImage: "tray")
                                .font(.footnote)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .foregroundStyle(Tokens.slipped)
                                .background(Capsule().strokeBorder(Tokens.slipped.opacity(0.4)))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .frame(height: 36)
        }
    }

    private var shelfTasks: [ToDo] {
        let now = Date.now
        return todos.filter { TimeBands.band(for: TaskSnapshot($0), now: now, calendar: calendar) == .shelf }
    }

    private func slippedDays(_ task: TaskSnapshot) -> Int {
        guard let due = task.due else { return 0 }
        return max(1, -TimeBands.dayOffset(from: .now, to: due, calendar: calendar))
    }

    // MARK: - Toast

    private func toastView(_ toast: Toast, _ byID: [UUID: ToDo]) -> some View {
        HStack(spacing: 14) {
            Text("Stone #\(toast.total.formatted())").font(.subheadline.weight(.semibold))
            Button("Undo") { undo(toast, byID) }.font(.subheadline.weight(.semibold)).foregroundStyle(Tokens.ember)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(Capsule().fill(Tokens.ground).shadow(color: .black.opacity(0.15), radius: 10, y: 4))
        .foregroundStyle(Tokens.ink)
    }

    // MARK: - Actions

    /// VoiceOver users need longer to find Undo.
    private var undoWindow: TimeInterval { UIAccessibility.isVoiceOverRunning ? 15 : Completion.undoWindow }

    private var cairnTotal: Int { todos.lazy.filter(\.isCompleted).count }

    private func completedToday(_ now: Date) -> Int {
        todos.lazy.filter { $0.completedAt.map { calendar.isDate($0, inSameDayAs: now) } ?? false }.count
    }

    private func open(_ id: UUID) { editing = todos.first { $0.id == id } }

    /// The sheet has closed; complete after it settles so the sink, stone and toast play on the visible field.
    private func finishFromSheet(_ id: UUID) {
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            complete(id, Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }))
        }
    }

    private func capture(_ parsed: ParsedCapture) {
        guard let task = try? Capture.insert(parsed, in: context) else { return }
        Task { await scheduler.schedule(task) }
        Widgets.reload()
    }

    private func complete(_ id: UUID, _ byID: [UUID: ToDo]) {
        guard let task = byID[id], let total = try? Completion.complete(task, in: context) else { return }
        Task { await scheduler.schedule(task) }
        Widgets.reload()
        AccessibilityNotification.Announcement("Stone #\(total). Undo is available.").post()
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.settle) { toast = Toast(taskID: id, total: total) }
        toastTimer?.cancel()
        toastTimer = Task {
            try? await Task.sleep(for: .seconds(undoWindow))
            if !Task.isCancelled { withAnimation { toast = nil } }
        }
    }

    private func undo(_ toast: Toast, _ byID: [UUID: ToDo]) {
        guard let task = byID[toast.taskID], (try? Completion.undo(task, in: context, window: undoWindow)) == true else { return }
        Task { await scheduler.schedule(task) }
        Widgets.reload()
        toastTimer?.cancel()
        withAnimation { self.toast = nil }
    }

    private enum Move { case today, tomorrow, nextWeek, shelf }

    private func reschedule(_ id: UUID, _ byID: [UUID: ToDo], _ move: Move) {
        guard let task = byID[id] else { return }
        let start = calendar.startOfDay(for: .now)
        func at9(_ day: Date) -> Date { calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day }
        switch move {
        case .today: task.isDated = true; task.dueDate = .now; task.stateRaw = "active"
        case .tomorrow:
            task.isDated = true; task.stateRaw = "active"
            task.dueDate = at9(calendar.date(byAdding: .day, value: 1, to: start)!)
        case .nextWeek:
            task.isDated = true; task.stateRaw = "active"
            let next = calendar.nextDate(after: .now, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)!
            task.dueDate = at9(next)
        case .shelf: task.isDated = false; task.stateRaw = "shelved"
        }
        task.modifiedAt = .now
        try? context.save()
        Task { await scheduler.schedule(task) }
        Widgets.reload()
    }
}

#if DEBUG
private struct DebugMenu: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Legacy list") { ToDoListView() }
                NavigationLink("Legacy graph") { GraphView() }
                NavigationLink("Legacy settings") { SettingsView() }
            }
            .navigationTitle("Debug")
        }
    }
}
#endif

private struct ShelfSheet: View {
    let tasks: [ToDo]
    let onBringBack: (ToDo) -> Void
    let onOpen: (ToDo) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty {
                    Text("Nothing on the shelf.").foregroundStyle(.secondary)
                }
                ForEach(tasks) { task in
                    HStack {
                        Button(task.item) { onOpen(task) }.foregroundStyle(Tokens.ink)
                        Spacer()
                        Button("Bring back") { onBringBack(task) }
                            .buttonStyle(.bordered).tint(Tokens.ember)
                    }
                }
            }
            .navigationTitle("Shelf")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
