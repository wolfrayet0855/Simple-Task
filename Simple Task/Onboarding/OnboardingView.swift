import SwiftUI
import SwiftData
import SimpleTaskKit

/// Three steps at most: the path, hold to finish, drop a thought. Skippable at every step.
struct OnboardingView: View {
    let movedTasks: Int?     // set when the user upgraded from the old app
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var step = 0
    @State private var held = false
    @State private var holdKey = 0
    @State private var text = ""
    @State private var landed: String?
    @State private var askNudge: String?
    @State private var risen = 0

    private let sample = TaskSnapshot(id: UUID(), title: "Hold me to finish", due: Calendar.current.date(byAdding: .hour, value: 2, to: .now),
                                       weight: .M, isDone: false)

    var body: some View {
        ZStack {
            let k = Sky.keyframes(at: .now)
            LinearGradient(colors: [Tokens.skyTop(k.from).mix(with: Tokens.skyTop(k.to), by: k.t, in: .perceptual), Tokens.ground],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip", action: onDone).foregroundStyle(Tokens.inkSecondary).frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, Space.xl)
                content
                    .transition(reduceMotion ? .opacity : .push(from: .trailing))
                    .id(step)
                footer
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.35), value: step)
        .interactiveDismissDisabled()
        .foregroundStyle(Tokens.ink)
    }

    @ViewBuilder
    private var content: some View {
        let scroll = dynamicTypeSize.isAccessibilitySize
        let inner = VStack(spacing: 20) {
            illustration.frame(maxHeight: scroll ? 120 : .infinity)
            VStack(spacing: 10) {
                Text(headline).font(.largeTitle.weight(.semibold)).fontDesign(.serif)
                    .lineLimit(3).minimumScaleFactor(0.85).multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(bodyText).font(.body).foregroundStyle(Tokens.inkSecondary).multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
                if step == 2 { nudge }
            }
            .padding(.horizontal, 28).padding(.bottom, 20)
        }
        if scroll { ScrollView { inner } } else { inner }
    }

    private var headline: String {
        switch step {
        case 0: movedTasks.map { _ in "Your tasks made the move." } ?? "Your days, laid out ahead."
        case 1: held ? "That's a stone." : (reduceMotion ? "Tap to finish." : "Hold to finish.")
        default: landed ?? "Drop a thought."
        }
    }

    private var bodyText: String {
        switch step {
        case 0: movedTasks.map { "All \($0) are here, placed by when they're due. Nothing was lost." }
            ?? "Today is close and large. Later things wait further up the path, smaller, until they're near."
        case 1: held ? "Undo is always there for a few seconds."
            : "\(reduceMotion ? "Tap" : "Press and hold for a moment"). Finished things become stones in your cairn, and the pile only grows."
        default: "Type it like you'd say it. A day or time sends it up the path; #tag and @name work too."
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch step {
        case 0: pathIllustration
        case 1: holdPractice
        default: captureStep
        }
    }

    // MARK: - Step 1

    private var pathIllustration: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Canvas { ctx, size in
                    for (from, to) in [(CGPoint(x: 24, y: h), CGPoint(x: size.width / 2 - 70, y: 20)),
                                       (CGPoint(x: size.width - 24, y: h), CGPoint(x: size.width / 2 + 70, y: 20))] {
                        var p = Path(); p.move(to: from); p.addLine(to: to)
                        ctx.stroke(p, with: .color(Tokens.contour), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    }
                    var line = Path(); line.move(to: CGPoint(x: 0, y: 20)); line.addLine(to: CGPoint(x: size.width, y: 20))
                    ctx.stroke(line, with: .color(Tokens.contour), lineWidth: 1.5)
                    ctx.fill(Path(ellipseIn: CGRect(x: size.width / 2 - 7, y: 13, width: 14, height: 14)), with: .color(Tokens.ember.opacity(0.7)))
                }
                ForEach(Array(["Sam's 40th", "Pay rent", "Dentist"].enumerated()), id: \.offset) { i, title in
                    let home = 40 + CGFloat(i) * (h - 60) / 3.2
                    Text(title).font(i == 2 ? .subheadline : .footnote).fontWeight(.medium)
                        .padding(.horizontal, 12).frame(height: 32 - CGFloat(2 - i) * 4)
                        .background(Capsule().fill(Tokens.card)).overlay(Capsule().strokeBorder(Tokens.cardEdge))
                        .position(x: w / 2 + (i == 1 ? 40 : -30), y: risen > i || reduceMotion ? home : h - 10)
                        .opacity(risen > i || reduceMotion ? 1 : 0.0)
                        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: risen)
                }
            }
        }
        .padding(.horizontal, 24).frame(height: 240)
        .accessibilityHidden(true)
        .task {
            for _ in 0..<3 { try? await Task.sleep(for: .seconds(0.9)); risen += 1 }
        }
    }

    // MARK: - Step 2

    private var holdPractice: some View {
        VStack(spacing: 18) {
            if !held {
                TaskCard(task: sample, isEmber: true, now: .now)
                    .holdToComplete(cornerRadius: Radius.card, onComplete: { finish() }, onOpen: {})
                    .id(holdKey)
                    .transition(AnyTransition(SinkTransition()))
                    .accessibilityHint("In Waymark, hold a card to finish it. With VoiceOver, use the Finish action.")
                    .accessibilityAction(named: "Finish") { finish() }
                    .padding(.horizontal, 24)
            } else {
                Button("Try again") { withAnimation { held = false; holdKey += 1 } }
                    .foregroundStyle(Tokens.inkSecondary).frame(minHeight: 44)
            }
            HStack(spacing: 4) {
                ForEach(0..<(held ? 4 : 3), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i == 3 ? Tokens.ember.opacity(0.85) : Tokens.stone)
                        .frame(width: 14, height: 10 + CGFloat((i * 7) % 5))
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func finish() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.settle) { held = true }
        AccessibilityNotification.Announcement("Stone laid.").post()
    }

    // MARK: - Step 3

    private var captureStep: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            ForEach(["call mum sun 5pm", "pay rent on the 1st", "dentist in 3 weeks"], id: \.self) { example in
                Button(example) { text = example }.font(.caption).buttonStyle(.glass).foregroundStyle(Tokens.ink)
                    .accessibilityLabel("Example: \(example). Fills the capture field.")
            }
            CaptureBar(onCommit: commit, text: $text)
        }
    }

    private func commit(_ parsed: ParsedCapture) {
        guard let task = try? Capture.insert(parsed, in: context) else { return }
        Widgets.reload()
        if let due = parsed.due {
            landed = "Placed on \(due.formatted(.dateTime.weekday(.abbreviated))), up the path."
            Task {
                await Scheduler().schedule(task)
                if await LiveNotificationPermission().isUndetermined(),
                   !UserDefaults.standard.bool(forKey: "nudges.asked") {
                    askNudge = due.formatted(.dateTime.hour().minute().weekday(.abbreviated))
                }
            }
        } else {
            landed = "Landed in hand."
        }
    }

    @ViewBuilder
    private var nudge: some View {
        if let when = askNudge {
            VStack(spacing: 8) {
                Text("Want a nudge at \(when)?").font(.headline)
                Text("Waymark only nudges for things you give a time.").font(.footnote).foregroundStyle(Tokens.inkSecondary)
                HStack {
                    Button("Allow nudges") {
                        UserDefaults.standard.set(true, forKey: "nudges.asked"); askNudge = nil
                        Task { await LiveNotificationPermission().request() }
                    }.buttonStyle(.glassProminent).tint(Tokens.ember)
                    Button("Not now") { UserDefaults.standard.set(true, forKey: "nudges.asked"); askNudge = nil }
                        .buttonStyle(.glass)
                }
            }
            .padding(14).transition(.opacity)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == step ? Tokens.ink : Tokens.contour).frame(width: i == step ? 18 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("Step \(step + 1) of 3")
            Button { step < 2 ? (step += 1) : onDone() } label: {
                Text(step < 2 ? "Next" : "Start").frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.glassProminent).tint(Tokens.ember).controlSize(.large)
        }
        .padding(.horizontal, 28).padding(.bottom, 24)
    }
}
