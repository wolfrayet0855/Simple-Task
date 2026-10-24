# Simple Task Redesign: Design

The Designer's response to the PM's charter. Inputs: `charter.md`, the Researcher's `research.md`, and `apple-verification.md`, whose corrections override the research. Draft v1, 2026-10-23.

## 1. The idea: Horizon

**The primary surface is a landscape of time, not a list.** You stand in the foreground, and the future recedes toward a horizon at the top of the screen.

Today's work is near, large and **In Hand** (at most 5); later work is smaller and higher. Events stand on the horizon as **Landmarks**, each with a **Trail** of work walking backward toward you. A promise is a **Pledge**; the person is a **Witness**, a lantern tethered to it. Finished work drops into the **Cairn**, a pile of stones that only grows. Overdue is **Slipped** (dusk grey, never red); parked work sits on the **Shelf**; **Dusk** is an optional 30-second evening review; categories survive as persisted **Tags**. "Task" stays a plain word.

Why it is not a list:

- **Vertical position is distance in time** on a compressed scale, not sort order.
- **Size is weight** (S/M/L).
- **Lines are direction.** A trail ties a task to its event. A tether ties a promise to a person.
- **It is finite.** Each band shows a few items and folds the rest into a numbered stone.
- **It gets calmer as you master it.** Finished work leaves the field, the ground widens, and the sky desaturates.

This answers charter principles 1 to 4: three spatial encodings, trails drawn backward from the landmark, lanterns instead of badges, and finishing as a physical act with a permanent result.

### Rejected alternative: Orbit

Tasks circle a central "you"; a smaller orbit means sooner. Striking in a clip, but rejected: a circle wastes the phone's tall shape, labels on a ring rotate or truncate under Dynamic Type, reading order is ambiguous for VoiceOver and people, and events have no natural place.

Horizon keeps the drama, reads top to bottom like the rest of iOS, and gives events a home.

## 2. Visual language

**Type.** Use Dynamic Type styles only.

| Token | Style | Used for |
|---|---|---|
| `type.landmark` | `.title2`, serif design (New York), semibold | Landmarks and Cairn totals |
| `type.task.near` | `.title3`, medium | In Hand cards |
| `type.task.far` | `.footnote` | Distant bands |
| `type.countdown` | `.headline`, monospaced design, `.monospacedDigit()` | "T-12d" and "2h 10m" |
| `type.meta` | `.caption`, secondary | Tags and initials |

**Colour tokens** live in the asset catalog.

| Token | Light | Dark | Use |
|---|---|---|---|
| `ink` | #1C1E22 | #EDEBE6 | text |
| `ground` | #FBF8F3 | #17150F | foreground |
| `sky.day` / `sky.dusk` | #E6EDF6 / #F2E4DA | #0E1420 / #1D1626 | gradient top, follows local time |
| `ember` | #D9712B | #F29A55 | the single next action |
| `landmark` | #4B4FA8 | #9A9DF2 | landmarks, trails |
| `witness` | #2F8F8A | #5CC2BC | lanterns, pledges |
| `slipped` | #8A93A6 | #6E7689 | overdue (never red) |
| `stone` | #B9B2A6 | #4F493F | Cairn |
| `tag.1`–`tag.8` | muted set | muted set | tag notch |

Red appears only on destructive confirmations. Every token reaches 4.5:1 on `ground` (Increase Contrast swaps darker variants). The sky loses 30% saturation when In Hand is empty.

**Motion tokens** (`Motion.swift`):

| Token | Value | Use |
|---|---|---|
| `settle` | `.spring(response: 0.42, dampingFraction: 0.82)` | card lands in the Cairn |
| `lift` | `.spring(response: 0.28, dampingFraction: 0.7)` | picking up a card |
| `drift` | `.easeInOut(duration: 1.2)` | bands shift at midnight or after a reschedule |
| `trailDraw` | 0.6 s trim | drawing a trail |
| `hold` | 0.55 s | hold-to-complete |

With Reduce Motion on, every animation becomes a 0.2 s crossfade, and hold-to-complete becomes a tap with an Undo toast.

**Haptic grammar.** iPhone uses Core Haptics, given here as intensity/sharpness. Watch uses `WKHapticType`.

| Moment | iPhone | Watch |
|---|---|---|
| Capture | transient 0.4/0.8 | `.click` |
| Hold | continuous ramp, 0.2 to 0.8 over `hold` | — |
| Complete ("settle") | transient 1.0/0.2, then a continuous 0.3 decaying over 0.25 s | `.success` |
| Witness saw it | two transients 0.5/0.3, 120 ms apart | `.notification` |
| Slipped | none, deliberately | none |

**Sound.** None in v1. Haptics carry the feel; owner decided to cut the sound pack. Revisit only if testers ask.

## 3. Core screens

### 3.1 Horizon (signature screen, iPhone portrait)

```
┌───────────────────────────────────┐
│  ▲ Sam's 40th   ▲ Launch    +4    │ Horizon  >31d, landmarks only
│ ───────────────────────────────── │
│   · renew passport  · book venue ╲│ Month 8–31d (trail bends to ▲)
│   ▫ draft toast  ◉S  ▫ order cake ╲ Week 2–7d (◉S = witness Sam)
│ ───────────────────────────────── │
│   ▭ call caterer      ▭ gym       │ Tomorrow
│ ═════════════════════════════════ │
│ ┌──────────────────────────────┐  │ In Hand (today, ≤5)
│ │● Send deck to Priya   ◉P 2:00│  │ ● ember = next action
│ └──────────────────────────────┘  │
│ ┌───────────────┐ ┌────────────┐  │ size = weight
│ │ Pay rent      │ │ Groceries  │  │
│ └───────────────┘ └────────────┘  │
│   ◌ 3 slipped (dusk, left edge)   │
│ ▪▪▪▪▪▪▫ Cairn 1,284 · today 6    │
│ [ Drop a thought…           ⊕ ]   │ capture bar, always visible
└───────────────────────────────────┘
```

**Layout**

- **Bands**, as fractions of height measured from the bottom: Cairn 0–0.06, In Hand 0.06–0.46, Tomorrow 0.46–0.60, Week 0.60–0.76, Month 0.76–0.92, Horizon 0.92–1.0.
- **Vertical position** within a band is linear in time. Today's band uses time of day, and undated In Hand items sit at the band floor.
- **Scale:** `s = max(0.45, 1 − 0.6·depth)`. Card heights at s = 1 are 56, 72, and 96 pt for S, M, and L.
- **Caps per band:** 5, 4, 6, and 6 items, plus 4 landmarks. Overflow becomes a `+n` stone that fans out on tap.
- **Horizontal position:** trail tasks sit on a quadratic Bézier from the landmark to its nearest open waypoint; others take a stable lane (`id.hashValue % lanes`, then a collision pass); the ember is centred.

**Interactions**

- **Hold to complete.** Hold for 0.55 s: a ring fills as the haptic ramps. On release the card falls into the Cairn (`settle`), and Undo stays available for 5 s. Swipes never complete a task.
- **Drag** a card to another band to reschedule. It snaps to Tomorrow 9:00, Week next Monday, or the Shelf (undated).
- **Tap** a card to open the Task sheet, or a landmark to open the Landmark screen. **Pinch out** to reveal the Shelf.
- **Slipped items** move to the left edge, show "slipped 2d", and go to the Shelf quietly after 7 days.

**Accessibility.** `accessibilityRepresentation` provides a VoiceOver rotor grouped by band and ordered by time, with actions Complete, Tomorrow, Shelf, and Open. It is snapshot-tested.

**iPad and Mac.** The field turns sideways: now is on the left, the horizon on the right, and a Landmark inspector docks on the trailing edge. On Mac: hold Space 0.55 s to complete, ⌘N captures, arrow keys walk the field, and the focus Live Activity sits in the menu bar.

### 3.2 Capture (ten-second test)

```
[ dinner w/ Sam fri 7pm #home @Sam ⊕ ]
   ↳ Fri 19:00 · home · pledge to Sam       (live, tappable chips)
```

Return commits. A task with no date lands In Hand, undated. The parser is rules-based: `NSDataDetector` plus a token grammar.

`#tag` sets the tag, `@name` creates a pledge (with a one-time "Tell?"), and `^Landmark` joins that trail.

### 3.3 Task sheet (a card with detents, not a Form)

Inline-editable rows, top to bottom: title with weight (S/M/L), When and Remind, If-then cue ("After standup, I will open the deck and send it."; the cue can be a time, a RelevanceKit place category, or another task), Steps with a **Smaller** button, Pledge (witness, date, [Tell]), Trail and Tag, Notes, and a **Hold to finish** bar.

### 3.4 Landmark (backward planning)

```
┌ ▲ Sam's 40th · Sat 14 Dec · T-52d ───┐
│  buffer ░░░ 3d                        │
│  T-0   ● party                        │
│  T-1   ○ pick up cake      ◉Ana       │
│  T-7   ○ final headcount              │
│  T-14  ○ order cake                   │
│  T-21  ○ book venue  ← next           │
│  T-30  ✓ send invites                 │
│ [+ waypoint] [Template ▾] [Draft ✦]   │
│ Day-of ▸ run-of-show 18:00 … 23:30    │
└───────────────────────────────────────┘
```

Waypoints store `offsetDays`, so moving the date slides the whole trail (`drift`). The buffer (default 10% of span, 1–7 days) moves every waypoint earlier. Templates: Trip, Party, Launch, Move, Exam, Custom. A waypoint owner (a Witness) makes it that person's pledge. The run-of-show (timed segments) feeds the Countdown Live Activity.

### 3.5 Witnesses and Pledges

One row per witness: "Priya: 2 open, 14 kept, 3 renegotiated". "Me" holds future-me pledges. A pledge is open, then kept, renegotiated or released, never "failed". **Renegotiating early** (a new date, an optional note to the witness) counts as honest. A **receipt** is a rendered card sent through the share sheet: "I promised X by Y. Done at Z." Nothing is sent automatically.

### 3.6 Dusk (optional, off by default)

A card stack of today's leftovers and slipped items: swipe up for Tomorrow, left for Shelf, down to Let go; tap to keep In Hand. The final card shows today's stones and one sentence. There are no failure counts, and skipping Dusk has no consequence.

### 3.7 Cairn (replaces GraphView)

One stone per completed task, coloured by tag and sized by weight, in daily rows. The all-time total can never decrease. The free tier shows the last 90 days plus the total. Colours are semantic SwiftUI colours, which also fixes the `UIColor` break on the Mac.

## 4. Data model (SwiftData, CloudKit-safe)

The model follows these rules:

- Every model has a UUID `id`.
- No `.unique` attributes.
- Every stored property has a default.
- Every relationship is optional and has an inverse.
- Enums are stored as raw `String`.
- Entity names `ToDo` and `SubTask` and every existing stored property name stay unchanged, because renaming them adds risk and buys nothing.

```swift
enum SchemaV1: VersionedSchema {   // verbatim copy of today's model
  static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
  static var models: [any PersistentModel.Type] { [ToDo.self, SubTask.self] }
  @Model final class ToDo {
    @Attribute(.unique) var item = ""
    var reminderIsOn = false; var dueDate = Date(); var reminderDate = Date()
    var isCompleted = false; var isAllDay = false; var category = "Work"
    @Relationship(inverse: \SubTask.parent) var subtasks: [SubTask] = []
  }
  @Model final class SubTask { var name: String; var isCompleted: Bool; var parent: ToDo? }
}

enum SchemaV2: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
  static var models: [any PersistentModel.Type] {
    [ToDo.self, SubTask.self, Tag.self, Landmark.self, Witness.self, Pledge.self] }
  @Model final class ToDo {
    var id = UUID(); var item = ""; var notes = ""
    var dueDate = Date(); var isDated = true; var isAllDay = false
    var reminderIsOn = false; var reminderDate = Date()
    var isCompleted = false; var completedAt: Date? = nil
    var createdAt = Date(); var modifiedAt = Date()
    var stateRaw = "active"          // active|inHand|shelved|done
    var weightRaw = "M"              // S|M|L
    var estimateMinutes: Int? = nil; var actualMinutes: Int? = nil
    var cueKindRaw = "none"          // none|time|place|after
    var cueText = ""; var cuePlaceCategory: String? = nil
    var offsetDays: Int? = nil       // T-minus on a trail
    var recurrenceRaw: String? = nil // RRULE subset
    var category = "Work"            // legacy, kept for lossless round-trip
    var calendarItemID: String? = nil
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent) var subtasks: [SubTask]? = []
    var tag: Tag? = nil; var landmark: Landmark? = nil; var pledge: Pledge? = nil
    var notificationID: String { "task.\(id.uuidString).reminder" }
  }
  @Model final class SubTask {
    var id = UUID(); var name = ""; var isCompleted = false; var order = 0
    var parent: ToDo? = nil
  }
  @Model final class Tag {
    var id = UUID(); var name = ""; var colorToken = "tag.1"; var order = 0
    @Relationship(deleteRule: .nullify, inverse: \ToDo.tag) var tasks: [ToDo]? = []
  }
  @Model final class Landmark {
    var id = UUID(); var title = ""; var date = Date(); var endDate: Date? = nil
    var isAllDay = true; var location = ""; var bufferDays = 1
    var templateRaw = "custom"; var runOfShowJSON: Data? = nil
    var calendarEventID: String? = nil
    @Relationship(deleteRule: .nullify, inverse: \ToDo.landmark) var tasks: [ToDo]? = []
  }
  @Model final class Witness {
    var id = UUID(); var displayName = ""; var contactID: String? = nil
    var isSelf = false
    @Relationship(deleteRule: .nullify, inverse: \Pledge.witness) var pledges: [Pledge]? = []
  }
  @Model final class Pledge {
    var id = UUID(); var statement = ""; var byDate = Date()
    var stateRaw = "open"            // open|kept|renegotiated|released
    var toldAt: Date? = nil; var resolvedAt: Date? = nil; var note = ""
    var witness: Witness? = nil
    @Relationship(inverse: \ToDo.pledge) var task: ToDo? = nil
  }
}
```

**Migration** (`SimpleTaskMigrationPlan`): a single `.custom` stage from V1 to V2.

1. **willMigrate (V1 context).** Snapshot `item → (category, subtask order)`, because array order does not survive the change to an optional relationship.
2. **Schema change.** Drop `.unique`, add the defaulted attributes and the new entities, and make `subtasks` optional.
3. **didMigrate (V2 context).** Per task: a fresh `UUID()` (never trust a shared default); `createdAt`/`modifiedAt` = now; `completedAt = isCompleted ? dueDate : nil` (best evidence, stated in release notes); `stateRaw`; link a Tag (one per distinct `category` string plus the 5 defaults, so nothing collapses into "Other"); restore `SubTask.order` and assign subtask `id`s.
4. **Relocation** (first launch). Copy the migrated legacy `default.store` into the App Group with `NSPersistentStoreCoordinator.replacePersistentStore(at:withPersistentStoreFrom:…)`, which is WAL-safe. Verify row counts, then delete the legacy files and record `storeLocation = "group"`.
5. **Notifications** (once, behind flag `notif.v2`). Remove pending requests whose identifier equals an old title, then reschedule each one under `notificationID`.
6. **Every launch.** Dedupe by `id`, keeping the latest `modifiedAt`. A task with `completedAt` set is never reopened by an older write.

**Container.** `Store.makeContainer()` is shared by the app, widgets, intents, and the MCP helper:

```swift
ModelConfiguration(
    schema: Schema(versionedSchema: SchemaV2.self),
    groupContainer: .identifier(AppGroup.id),
    cloudKitDatabase: Features.cloudSync ? .private(CloudID.container) : .none
)
```

`cloudSync` stays false until the owner provisions iCloud.

## 5. Notifications

Each platform's app schedules its own local notifications from synced data, as correction 5 requires.

Reconcile at launch, on `.NSPersistentStoreRemoteChange`, and in a `BGAppRefreshTask`. Category `TASK` actions: Done (runs `CompleteTaskIntent`), +1 hour, Tomorrow. "Remind me here" is per device (default on for iPhone, Mac, Watch). Time Sensitive only for tasks marked "Must start"; AlarmKit opt-in per task. Copy never shames: "Ready when you are: Send deck to Priya."

## 6. Surfaces, intents, entities

**Entities** live in the shared framework `SimpleTaskKit`:

- `TaskEntity: AppEntity, IndexedEntity` with `id: UUID`, `title`, `due: Date?`, `isDone`, and `landmarkName?`. Queried by `TaskQuery: EntityStringQuery`, whose suggestions are the In Hand items.
- `LandmarkEntity: AppEntity, IndexedEntity`.
- `WitnessEntity` and `TagEntity`.
- `AppEnum WhenChoice { today, tomorrow, thisWeek, shelf }`.

**Intents**

| Intent | Parameters | Returns | Used by |
|---|---|---|---|
| `AddTaskIntent` | title, when?, landmark?, witness? | `TaskEntity` + snippet | Siri, Shortcuts, Control, Watch |
| `CompleteTaskIntent` | task | "Stone #1,285." | widget, notification, Watch, Siri |
| `DeferTaskIntent` | task, when | dialog | widget, notification, Dusk |
| `WhatsNextIntent` | none | ember `TaskEntity` + snippet | Siri, Action button |
| `StartFocusIntent: LiveActivityIntent` | task?, minutes = 25 | Hourglass | Control, Shortcuts |
| `PlanLandmarkIntent` | title, date, template? | `LandmarkEntity` + trail | Siri, Shortcuts |
| `PledgeIntent` | task, witness | share sheet with receipt | Shortcuts |
| `ListDueIntent` | when | `[TaskEntity]` | Shortcuts |
| `OpenHorizonIntent: OpenIntent` | task or landmark | n/a | Spotlight, widgets |

**Phrases** (`AppShortcutsProvider`): "Add to \(.applicationName)", "What's next in \(.applicationName)", "Finish \(\.$task) in \(.applicationName)", "Plan \(\.$landmark) in \(.applicationName)".

**OS 27** (behind `#available`; take exact identifiers from Apple's docs): add/complete/delete adopt the App Schemas `.reminders` domain so Siri understands natural language without phrases; View Annotations let "push this to tomorrow" act on the card on screen; the App Intents Testing framework covers the intents.

**Widgets**

- **Next** (small and medium): the ember task, its countdown, and `Button(intent: CompleteTaskIntent)`. A locked device asks for authentication first (correction 6).
- **Horizon** (large; iPad and Mac): a miniature field.
- **Landmark**: accessoryCircular shows a done/total ring with T-minus; accessoryRectangular shows the next task.
- **Watch**: the same accessories (not interactive), plus RelevanceKit cards for place and time cues ("At the grocery store: 3 errands").

**Controls** (iOS 18, macOS 26, watchOS 26): **Capture** (`OpenIntent` into the capture bar) and **Focus next** (`StartFocusIntent`). iPhone controls appear on Watch before a Watch app exists.

**Live Activities:** **Hourglass** (focus; draining arc, Stop, Done; capped at 8 h; shows in the Watch Smart Stack and Mac menu bar) and **Countdown** (a landmark's day-of run-of-show; starts from the app, a Control, or a scheduled start with an `AlertConfiguration`, whose availability needs verifying).

**watchOS app:** a vertical Horizon scrubbed with the Digital Crown, hold to complete (`.success`), dictation capture, read-only pledges, its own notifications. No `WKExtendedRuntimeSession` (correction 4); focus runs on the iPhone Live Activity.


## 7. Apple Intelligence (an enhancement, never the pitch)

Gate on `SystemLanguageModel.default.availability == .available`. Budget with `contextSize`/`tokenCount(for:)` on 26.4+, assume 4,096 tokens below, chunk long input. On-device only: Private Cloud Compute and third-party models are off (corrections 2, 3). Output is always an editable draft, never written on its own.

| Feature | AI path (`@Generable`) | Fallback (same UI) |
|---|---|---|
| Brain-dump → tasks | `[ParsedTask{title, dueHint, weight, witnessName?}]` | newline/bullet split, `NSDataDetector`, `@`/`#`/`^` grammar |
| Smaller | 3–5 `Step{title, minutes}` | "What's the first physical action?" plus tag templates |
| Draft trail | `[Waypoint{title, offsetDays, ownerHint?}]` | template trails |
| Dusk sentence | one sentence from today's titles | `"You finished \(n). Next: \(ember)."` |
| Photo of a paper list (27) | image input → `[ParsedTask]` | Vision `RecognizeTextRequest` + line split |

Writing Tools work in Notes by default. On 27, regression-test the model features with the Evaluations framework.

## 8. Event planning and accountability

- **Backward planning.** Landmarks have offsets, a buffer, templates, owners, and a run-of-show. A waypoint is "on track" while now is before its date minus the buffer. Otherwise it turns grey, never red.
- **If-then cues.** Every task can carry one. Place cues surface through Watch relevance. "After" cues fire when the preceding task completes.
- **Honest estimates.** On completion, an optional one-tap "about how long?" stores `actualMinutes`. The personal multiplier is the median of actual ÷ estimate over the last 30 tasks.
- **Pledges** (section 3.5): opt-in, user-sent receipts, ledger counts never lost.
- **Never:** streaks, money at risk (App Review 5.3 and 3.1.1, correction 10), points, leaderboards, guilt copy, red, "you missed" banners, or automatic posting.

## 9. Interoperability and MCP

- **Calendar:** free EventKitUI "Add to Calendar" (no prompt); two-way landmark sync via `calendarEventID` needs full access. **Reminders import:** one-shot, full access (correction 8), cut first if late.
- **JSON** `simpletask.v2.json` (all models, import idempotent by `id`); **.ics** VEVENT for landmarks, VTODO for tasks, `UID` = uuid, round-trip tested.
- **URL scheme.** `simpletask://add?title=&due=ISO8601&landmark=`, plus `simpletask://task/<uuid>`, `simpletask://landmark/<uuid>`, and `simpletask://capture`.
- **Webhooks (paid).** A POST on each of `task.completed`, `task.added`, `pledge.resolved`, and `landmark.reached`, signed with HMAC-SHA256 and queued on the device. Our own servers are never involved.
- **MCP stance.** App Intents with App Schemas are the main agent surface (correction 11). The optional **Mac MCP helper** (paid) is a signed, sandboxed stdio binary at `Contents/Helpers/simpletask-mcp`. It shares the App Group, and Settings offers a "Copy client config" snippet.
Tools: `get_horizon`, `list_tasks(when)`, `add_task`, `complete_task`, `defer_task`, `list_landmarks`, `draft_trail` (confirmed in-app). No delete; task text returned as quoted untrusted data; writes capped at 20/min.

## 10. Free vs paid

**Free forever:** Horizon, capture, Landmarks with manual trails and three templates, pledges, Dusk, notifications, iCloud sync, Watch, every widget, Control, Live Activity and intent, AI where supported, all exports, URL scheme, Add to Calendar, and a 90-day Cairn with the all-time total.

**Simple Task Plus** is one non-consumable purchase, suggested at $19.99. There is no subscription, no trial, and no feature is ever removed. It contains two paid features:

1. **Trailmaker** (planning automation): custom templates, AI Draft trail, automatic re-spacing when a landmark moves (shown as a diff to accept), the personal estimate multiplier and day-load warnings ("In Hand is about 5h for you"), recurring landmarks.
2. **Workbench** (reach and memory): webhooks, the Mac MCP helper, two-way Calendar sync, full Cairn history with exportable yearly prints and time-of-day patterns, themes.

**Ethics test.** Would a never-paying user still recommend it? Yes: every job works end to end and the signature experience is free. Would a payer feel the money bought something real? Yes: Trailmaker saves planning time on every event; Workbench adds integrations and memory. Placement: one Settings row plus one dismissible line on the Landmark screen, never during capture or completion. No paid feature requires check-ins, posting or extra data access.

## 11. The charter's tests

- **Five seconds:** depth, perspective, landmarks, lines to people, stones piling up. Reminders, Things and Todoist have no depth; Structured and Tiimo are linear day strips. Size-for-distance says what the screen is for.
- **One minute:** expected answers are "events plan themselves backward", "you hold to finish and it drops on a pile", "it shows who I promised".
- **On failure**, raise landmark scale and trail contrast before touching the metaphor.

## 12. Owner decisions

1. App name: keep "Simple Task" or rename to fit Horizon.
2. The Plus price. Whether to enable Family Sharing, which can't be undone per product (correction 9). The Designer recommends enabling it.
3. Later live-shared pledges: either a hand-built CloudKit `CKShare` zone that mirrors only Pledges (SwiftData does not handle shares), or receipts only.
4. Sound pack: cut by the owner (decided).
5. Default reminder devices. iPad opt-in is recommended.
6. A universal-link domain for receipts, or `simpletask://` only.
7. Team ID, App Group `group.<team>.simpletask`, and the CloudKit container ID.
8. Confirm OS 26 as the minimum. Features that need 27 are gated.

## 13. Milestones: first vertical slice (all verifiable in the simulator)

| Step | Files | Acceptance |
|---|---|---|
| 0. Hygiene | Delete `desktop` and `dekstop`; add `Simple TaskTests`; Swift 6; deployment targets 26; App Group entitlement (placeholder) | `xcodebuild test -scheme "Simple Task" -destination 'platform=iOS Simulator,name=iPhone 17'` passes |
| 1. Schema | `Model/SchemaV1.swift`, `SchemaV2.swift`, `MigrationPlan.swift`, `Store.swift`; typealiases such as `ToDo = SchemaV2.ToDo`; delete `CategoryManager` | `MigrationTests`: seed V1 with 3 tasks (one with 3 subtasks, categories "Work" and "Errands", one completed). After migration, assert: same counts, titles, dates and flags; subtask order kept; 6 Tags; unique ids; `completedAt` set |
| 2. Relocation + notifications | `Store.relocateIfNeeded()`, `Notifications/Scheduler.swift` | Counts match after relocation. Renaming a task leaves exactly one pending request, `task.<uuid>.reminder` |
| 3. Horizon (iPhone) | `Horizon/TimeBands.swift` (pure), `HorizonLayout.swift` (custom `Layout`), `HorizonView.swift`, `TaskCard.swift`, `HoldToComplete.swift`, `CaptureBar.swift`, `CaptureParser.swift`, `Cairn/CairnStrip.swift` | Unit tests for `TimeBands` and 10 parser phrases; snapshots on iPhone SE, on 17 Pro Max, and at AX5. Manually: add a task in under 10 s, hold to complete, Cairn shows +1, Undo works |
| 4. Intent | `SimpleTaskKit/TaskEntity.swift`, `CompleteTaskIntent.swift`, `AppShortcuts.swift` | "Finish task" in the simulator's Shortcuts app completes the task, and the Cairn updates |
| 5. Widget | `SimpleTaskWidgets/NextWidget.swift`, using `Store.makeContainer()` | Timeline snapshot test. Tapping Done on the home-screen widget completes the task and the widget reloads |

Old `DetailView`/`GraphView`/`SettingsView` stay behind a debug menu until Phase 2.

**Later:** Phase 2 Task sheet, Landmark, Dusk, sideways iPad/Mac field; Phase 3 remaining intents, Controls, Live Activities, Watch, AI, OS 27 Schemas; Phase 4 interop and MCP; Phase 5 StoreKit Plus. Cut webhooks and Reminders import first.
