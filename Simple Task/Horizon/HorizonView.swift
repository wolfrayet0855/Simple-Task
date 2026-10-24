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
    @State private var showShelf = false
    @State private var showSettings = false
    @State private var captureText = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
    }

    // MARK: - Field

    private struct FieldLayout {
        let header: CGFloat = 56
        let cairn: CGFloat = 40
        let capture: CGFloat = 64
        let slipped: CGFloat
        let inHand: CGFloat
        let field: CGFloat

        init(height: CGFloat, model: HorizonModel) {
            slipped = (model.groups[.slipped]?.visible.isEmpty ?? true) ? 0 : 36
            let avail = height - header - capture
            let ember = model.ember == nil ? 0 : 124.0
            let rest = max(0, (model.groups[.inHand]?.visible.count ?? 0) - (model.ember == nil ? 0 : 1))
            let est = model.isEmpty ? 220 : 54 + ember + CGFloat((rest + 1) / 2) * 96
            let counts = Dictionary(uniqueKeysWithValues: BandHeights.farBands.map { ($0, model.groups[$0]?.visible.count ?? 0) })
            let needed = BandHeights.allocate(total: 0, counts: counts).values.reduce(0, +)
            let wanted = min(max(est, 0.34 * avail), 0.52 * avail)
            let room = avail - slipped - cairn
            // Far bands never clip: In Hand gives up space down to a quarter of the screen, then it scrolls.
            let nearHeight = max(min(wanted, room - needed), 0.25 * avail)
            inHand = nearHeight
            field = max(0, room - nearHeight)
        }
    }

    private func wayfinding(_ now: Date, _ model: HorizonModel) -> String {
        let next = [Band.tomorrow, .week, .month, .horizon].lazy.compactMap { model.groups[$0]?.visible.first }.first
        if let next, let due = next.due {
            let when = calendar.isDateInTomorrow(due) ? "tomorrow" : due.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
            return "Next: \(next.title), \(when)"
        }
        return "Week \(calendar.component(.weekOfYear, from: now))"
    }

    @ViewBuilder
    private func field(now: Date) -> some View {
        let model = HorizonModel.build(todos.map(TaskSnapshot.init), cairnTotal: cairnTotal, now: now, calendar: calendar)
        let byID = Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let calm = model.isEmpty && model.cairnTotal > 0
        let shelfCount = model.groups[.shelf]?.visible.count ?? 0

        GeometryReader { geo in
            let layout = FieldLayout(height: geo.size.height, model: model)
            let counts = Dictionary(uniqueKeysWithValues: BandHeights.farBands.map { ($0, model.groups[$0]?.visible.count ?? 0) })
            let heights = BandHeights.allocate(total: layout.field, counts: counts)
            let stack = BandHeights.farBands.reduce(0) { $0 + (heights[$1] ?? 0) }
            let stackTop = max(0, layout.field - stack)
            let horizonY = layout.header + stackTop
            let thresholdY = layout.header + layout.field
            let floors = floorYs(heights: heights, from: horizonY)

            ZStack(alignment: .top) {
                SkyBackground(date: now, calm: calm, size: geo.size, insets: geo.safeAreaInsets,
                              horizonY: horizonY, thresholdY: thresholdY, contourYs: Array(floors.dropLast()))
                VStack(spacing: 0) {
                    HorizonHeader(now: now, wayfinding: wayfinding(now, model), shelfCount: shelfCount,
                                  onShelf: { showShelf = true }, onSettings: { showSettings = true })
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : layout.header)
                    if dynamicTypeSize.isAccessibilitySize {
                        itinerary(model, byID, now)
                    } else {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0).frame(height: stackTop)
                            ForEach(BandHeights.farBands, id: \.self) { b in
                                let mid = (floors[BandHeights.farBands.firstIndex(of: b) ?? 0]) - (heights[b] ?? 0) / 2
                                BandField(band: b, group: model.groups[b], now: now,
                                          horizontalInset: SkyBackground.inset(at: mid, width: geo.size.width, horizonY: horizonY, thresholdY: thresholdY),
                                          onOpen: open, label: BandLabel.text(b, now: now, calendar: calendar))
                                    .frame(height: heights[b] ?? 0)
                            }
                        }
                        .frame(height: layout.field, alignment: .top).clipped()
                    }
                    inHand(model, byID, now).frame(height: dynamicTypeSize.isAccessibilitySize ? nil : layout.inHand)
                    slippedRow(model, byID).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    CairnStrip(total: model.cairnTotal, today: completedToday(now))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    CaptureBar(onCommit: { parsed in capture(parsed) }, text: $captureText)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .frame(height: layout.capture, alignment: .bottom)
                }
                if let toast {
                    toastView(toast, byID)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, layout.capture + 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
        }
    }

    private func floorYs(heights: [Band: CGFloat], from top: CGFloat) -> [CGFloat] {
        var y = top
        return BandHeights.farBands.map { b in y += heights[b] ?? 0; return y }
    }

    /// Accessibility sizes swap the perspective field for a plain itinerary of sections.
    private func itinerary(_ model: HorizonModel, _ byID: [UUID: ToDo], _ now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach([Band.tomorrow, .week, .month, .horizon], id: \.self) { b in
                    if let tasks = model.groups[b]?.visible, !tasks.isEmpty {
                        Text(BandLabel.text(b, now: now, calendar: calendar)).font(.headline).foregroundStyle(Tokens.inkSecondary)
                        ForEach(tasks) { t in
                            Button { open(t.id) } label: {
                                HStack {
                                    Text(t.title).font(.body.weight(.medium))
                                    Spacer()
                                    if let due = t.due {
                                        Text(BandLabel.stamp(for: due, band: b)).font(.caption.monospacedDigit()).foregroundStyle(Tokens.inkSecondary)
                                    }
                                }
                                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Tokens.card))
                            }
                            .foregroundStyle(Tokens.ink)
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .frame(maxHeight: 220)
    }

    // MARK: - In Hand

    @ViewBuilder
    private func inHand(_ model: HorizonModel, _ byID: [UUID: ToDo], _ now: Date) -> some View {
        let group = model.groups[.inHand]
        let held = group?.visible.count ?? 0
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Today").font(.caption.weight(.semibold)).tracking(0.6).foregroundStyle(Tokens.inkSecondary)
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            Circle().fill(i < held ? Tokens.ink : Color.clear).frame(width: 7, height: 7)
                                .overlay(Circle().strokeBorder(Tokens.contour, lineWidth: i < held ? 0 : 1))
                        }
                    }
                    Spacer()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Today, \(held) of 5 in hand")
                if held == 0 {
                    emptyState(model, byID)
                } else if let group {
                    if let ember = model.ember { card(ember, isEmber: true, byID, now) }
                    let rest = group.visible.filter { $0.id != model.ember?.id }
                    let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        ForEach(Array(stride(from: 0, to: rest.count, by: columns)), id: \.self) { i in
                            GridRow {
                                ForEach(rest[i..<min(i + columns, rest.count)]) { t in
                                    card(t, isEmber: false, byID, now)
                                        .gridCellColumns(rest.count - i == 1 ? columns : 1)
                                }
                            }
                        }
                    }
                    if group.overflow > 0 {
                        Text("+\(group.overflow) more in hand").font(.footnote).foregroundStyle(Tokens.inkSecondary)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("In hand")
        .accessibilitySortPriority(100)
    }

    private func card(_ task: TaskSnapshot, isEmber: Bool, _ byID: [UUID: ToDo], _ now: Date) -> some View {
        TaskCard(task: task, isEmber: isEmber, now: now)
            .holdToComplete(cornerRadius: Radius.card, onComplete: { complete(task.id, byID) }, onOpen: { open(task.id) })
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .opacity, removal: AnyTransition(SinkTransition())))
            .accessibilityHint("Hold to finish. Double-tap to open.")
            .accessibilityAction(named: "Complete") { complete(task.id, byID) }
            .accessibilityAction(named: "Tomorrow") { reschedule(task.id, byID, .tomorrow) }
            .accessibilityAction(named: "Shelf") { reschedule(task.id, byID, .shelf) }
            .accessibilityAction(named: "Open") { open(task.id) }
    }

    @ViewBuilder
    private func emptyState(_ model: HorizonModel, _ byID: [UUID: ToDo]) -> some View {
        let nearest = [Band.tomorrow, .week, .month, .horizon].lazy.compactMap { model.groups[$0]?.visible.first }.first
        if model.isEmpty && model.cairnTotal == 0 {
            VStack(spacing: 10) {
                Text("Start with one thing.").font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(Tokens.ink)
                Text("Type it below. Add a day like *fri* and it walks up the path.")
                    .font(.subheadline).foregroundStyle(Tokens.inkSecondary).multilineTextAlignment(.center)
                VStack(spacing: 6) {
                    ForEach(["call mum sun 5pm", "pay rent on the 1st", "dentist in 3 weeks"], id: \.self) { example in
                        Button(example) { captureText = example }
                            .font(.caption).buttonStyle(.glass).foregroundStyle(Tokens.ink)
                            .accessibilityLabel("Example: \(example). Fills the capture field.")
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        } else if model.isEmpty {
            VStack(spacing: 8) {
                Text("Clear skies.").font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(Tokens.ink)
                Text("\(model.cairnTotal.formatted()) stones laid.").font(.subheadline).foregroundStyle(Tokens.inkSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24).accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 10) {
                Text("Today's clear.").font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(Tokens.ink)
                if let nearest, let due = nearest.due {
                    Text("Next on the path: \(nearest.title) · \(due.formatted(.dateTime.weekday(.abbreviated).hour().minute()))")
                        .font(.subheadline).foregroundStyle(Tokens.inkSecondary).multilineTextAlignment(.center)
                    Button("Bring it to today") { reschedule(nearest.id, byID, .today) }
                        .buttonStyle(.bordered).tint(Tokens.ember)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24)
        }
    }

    // MARK: - Slipped

    @ViewBuilder
    private func slippedRow(_ model: HorizonModel, _ byID: [UUID: ToDo]) -> some View {
        let slipped = model.groups[.slipped]?.visible ?? []
        if !slipped.isEmpty {
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
            Button("Undo") { undo(toast, byID) }.font(.subheadline.weight(.semibold)).foregroundStyle(Tokens.emberText).frame(minHeight: 44)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .foregroundStyle(Tokens.ink)
    }

    // MARK: - Actions

    /// VoiceOver users need longer to find Undo.
    private var undoWindow: TimeInterval { UIAccessibility.isVoiceOverRunning ? 15 : Completion.undoWindow }

    private var cairnTotal: Int { todos.lazy.filter(\.isCompleted).count + CairnCounter.removed() }

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
