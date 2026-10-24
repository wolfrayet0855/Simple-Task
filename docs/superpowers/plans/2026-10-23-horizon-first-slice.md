# Horizon First Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the list UI with the Horizon screen on a CloudKit-safe, migrated data model, plus one App Intent and one widget, all verifiable in the iOS simulator.

**Architecture:** Shared code lives in a `SimpleTaskKit` framework target (models, migration, store, notifications, entities, intents). The app, widget extension and tests link it. Pure logic (`TimeBands`, `CaptureParser`, migration) is unit-tested; views are snapshot-checked and manually exercised. Old screens stay behind a debug menu.

**Tech Stack:** Swift 6, SwiftUI, SwiftData (VersionedSchema + custom migration), App Intents, WidgetKit, XcodeGen (`project.yml`), Swift Testing, iOS 26 deployment target.

**Spec:** `docs/redesign/design.md` (sections 3.1, 3.2, 4, 5, 6, 13). Charter: `docs/redesign/charter.md`. Corrections: `docs/redesign/apple-verification.md`.

## Global Constraints

- Minimum OS iOS 26; simulator `iPhone 17`, runtime iOS 26.5. Features needing iOS 27 are out of this slice.
- Bundle id stays `beta.SimpleTask`. App Group id is the placeholder `group.beta.SimpleTask` in one constant `AppGroup.id`; CloudKit stays off (`Features.cloudSync = false`).
- Models: every model has `var id = UUID()`; no `.unique`; every stored property has a default; every relationship optional with inverse; enums stored as raw `String`. Entity names `ToDo` and `SubTask` and all existing stored property names are unchanged.
- No red for overdue (token `slipped` #8A93A6 light / #6E7689 dark). Red only on destructive confirmations.
- Swipes never complete a task. Hold to complete is 0.55 s. Undo stays available 5 s.
- Band fractions from the bottom: Cairn 0–0.06, In Hand 0.06–0.46, Tomorrow 0.46–0.60, Week 0.60–0.76, Month 0.76–0.92, Horizon 0.92–1.0. Caps per band 5, 4, 6, 6, plus 4 landmarks. Scale `s = max(0.45, 1 − 0.6·depth)`; card heights at s=1: S 56, M 72, L 96 pt.
- Reduce Motion: every animation becomes a 0.2 s crossfade and hold becomes a tap with an Undo toast.
- Copy never shames. No streaks, points or guilt text.
- Commit messages are plain, with no tool or model attribution lines of any kind.
- Run tests with: `xcodebuild test -scheme "Simple Task" -destination 'platform=iOS Simulator,name=iPhone 17'`.

## Review Focus

- Two tasks with identical titles after migration: both survive with distinct `id`s (V1 forbade duplicates but a merge must never drop data).
- Empty store, and a V1 store with zero tasks: migration and relocation succeed and the Horizon shows an empty-state, not a crash.
- A task whose due date is in the past: appears as slipped at the left edge, not In Hand and not red.
- Capture input that is empty, whitespace, 500 characters, or only `#`/`@`: no task or a clean title, never a crash.
- Relocation interrupted or run twice: no duplicated or lost rows; legacy files deleted only after counts match.

---

## File Structure

- `project.yml` (create): XcodeGen spec; targets `Simple Task` (app), `SimpleTaskKit` (framework), `SimpleTaskWidgets` (extension), `Simple TaskTests`.
- `SimpleTaskKit/Model/SchemaV1.swift`, `SchemaV2.swift`, `MigrationPlan.swift`, `Aliases.swift`
- `SimpleTaskKit/Store/Store.swift`, `AppGroup.swift`, `Features.swift`
- `SimpleTaskKit/Notifications/Scheduler.swift`
- `SimpleTaskKit/Intents/TaskEntity.swift`, `CompleteTaskIntent.swift`, `AppShortcuts.swift`
- `Simple Task/Horizon/TimeBands.swift`, `HorizonLayout.swift`, `HorizonView.swift`, `TaskCard.swift`, `HoldToComplete.swift`, `CaptureBar.swift`, `CaptureParser.swift`, `CairnStrip.swift`, `Tokens.swift`
- `SimpleTaskWidgets/NextWidget.swift`, `NextTimeline.swift`
- `Simple TaskTests/` one file per area below.
- Move existing app sources unchanged into `Simple Task/Legacy/` (DetailView, GraphView, SettingsView, Simple TaskView) behind `#if DEBUG` menu.

---

### Task 0: Hygiene and project regeneration

**Files:**
- Create: `project.yml`, `Simple TaskTests/SmokeTests.swift`
- Delete: `Simple Task/desktop`, `Simple Task/dekstop` (byte-identical stray storyboard copies)
- Modify: move `Simple Task.swift`, `DetailView.swift`, `GraphView.swift`, `SettingsView.swift`, `Simple TaskView.swift` into `Simple Task/Legacy/`

**Interfaces:**
- Produces: schemes `Simple Task` (tests attached), frameworks linkable as `SimpleTaskKit`, empty-but-building widget extension.

- [ ] **Step 1:** Write `SmokeTests.swift` with `@Test func appBundleLoads()` asserting `Bundle(identifier: "beta.SimpleTask") != nil`.
- [ ] **Step 2:** Run the test command. Expected: FAIL (no test target).
- [ ] **Step 3:** Write `project.yml` preserving bundle id `beta.SimpleTask`, `TARGETED_DEVICE_FAMILY 1,2`, Swift 6, deployment target iOS 26.0, Info.plist and Launch Screen, an App Group entitlement for app, framework and widget (`AppGroup.id`). Run `xcodegen generate`; keep the old `.xcodeproj` out of git history by replacing it.
- [ ] **Step 4:** Run the test command. Expected: PASS and the app builds.
- [ ] **Step 5:** Commit: `chore: regenerate project with xcodegen, add test target, drop stray storyboards`.

### Task 1: Schema V1/V2 and migration

**Files:**
- Create: `SimpleTaskKit/Model/SchemaV1.swift`, `SchemaV2.swift`, `MigrationPlan.swift`, `Aliases.swift`, `Store/Store.swift`, `Store/AppGroup.swift`, `Store/Features.swift`
- Test: `Simple TaskTests/MigrationTests.swift`
- Modify: delete `CategoryManager` and its `environmentObject` use.

**Interfaces:**
- Produces: `enum SchemaV1/SchemaV2: VersionedSchema` exactly as `design.md` section 4; `enum SimpleTaskMigrationPlan: SchemaMigrationPlan`; `typealias ToDo = SchemaV2.ToDo` (also `SubTask`, `Tag`, `Landmark`, `Witness`, `Pledge`); `enum Store { static func makeContainer(inMemory: Bool = false) throws -> ModelContainer }`; `enum AppGroup { static let id: String }`; `enum Features { static let cloudSync: Bool }`.

- [ ] **Step 1: Write failing test** `migratesV1ToV2LosslessAndStable`: build an on-disk V1 store in a temp dir with 3 tasks (one completed; categories "Work" and "Errands"; one task with subtasks "a","b","c" in that order); reopen with `SimpleTaskMigrationPlan`; assert 3 tasks and 3 subtasks, titles/dates/flags equal, subtask `order` 0,1,2 matching names, all `ToDo.id` distinct, completed task has `completedAt != nil`, exactly 6 Tags (5 defaults plus "Errands").
- [ ] **Step 2: Run it.** Expected: FAIL (types undefined).
- [ ] **Step 3: Implement** schemas and the single `.custom` stage per design section 4 migration steps 1–3 (snapshot in `willMigrate`, fresh UUIDs, Tag linking, `completedAt = isCompleted ? dueDate : nil`, `stateRaw`), and `Store.makeContainer` per the container snippet there (CloudKit `.none` while `Features.cloudSync` is false). Dedupe-on-launch (step 6) lives in `Store.reconcile(context:)`; keep latest `modifiedAt`, never reopen a completed task.
- [ ] **Step 4:** Add tests `duplicateTitlesKeepBothRows` and `emptyV1StoreMigrates`; run all. Expected: PASS.
- [ ] **Step 5: Commit** `feat: CloudKit-safe schema v2 with lossless migration from v1`.

### Task 2: Store relocation and notification scheduler

**Files:**
- Create: `SimpleTaskKit/Notifications/Scheduler.swift`; extend `Store.swift` with `relocateIfNeeded()`
- Test: `Simple TaskTests/RelocationTests.swift`, `SchedulerTests.swift`

**Interfaces:**
- Consumes: `Store`, `ToDo.notificationID`.
- Produces: `Store.relocateIfNeeded(legacyURL: URL, groupURL: URL) throws -> RelocationResult` (`.alreadyDone`, `.moved(rows: Int)`, `.nothingToMove`); `protocol NotificationCenterProtocol` (add, remove, pending) with `UNUserNotificationCenter` conformance; `struct Scheduler { init(center: NotificationCenterProtocol); func reconcile(tasks: [ToDo]) async; func schedule(_ task: ToDo) async }`.

- [ ] **Step 1: Failing tests:** `relocationPreservesRowCountsAndDeletesLegacyOnlyAfterVerify`, `relocationTwiceIsNoOp`, `renamingTaskLeavesExactlyOnePendingRequest` (fake center; identifier `task.<uuid>.reminder`), `legacyTitleKeyedRequestsAreRemovedOnce` (flag `notif.v2`).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** relocation with `NSPersistentStoreCoordinator.replacePersistentStore(at:withPersistentStoreFrom:)`, verify counts, record `storeLocation = "group"` in `UserDefaults(suiteName: AppGroup.id)`; scheduler per design section 5 (category `TASK`: Done, +1 hour, Tomorrow; shame-free copy "Ready when you are: <title>").
- [ ] **Step 4: Run all tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: relocate store to app group, uuid-keyed notifications`.

### Task 3: Pure Horizon logic (TimeBands, CaptureParser)

**Files:**
- Create: `Simple Task/Horizon/TimeBands.swift`, `CaptureParser.swift`
- Test: `Simple TaskTests/TimeBandsTests.swift`, `CaptureParserTests.swift`

**Interfaces:**
- Produces: `enum Band: CaseIterable { case cairn, inHand, tomorrow, week, month, horizon }` with `static let fractions: [Band: ClosedRange<Double>]` per Global Constraints; `enum TimeBands { static func band(for task: TaskSnapshot, now: Date, calendar: Calendar) -> Band; static func isSlipped(_ t: TaskSnapshot, now: Date) -> Bool; static func scale(depth: Double) -> Double; static func caps(_ b: Band) -> Int }`; `struct TaskSnapshot: Sendable, Identifiable { id: UUID; title: String; due: Date?; weight: Weight; isDone: Bool }`; `enum Weight: String { case S, M, L; var height: CGFloat }`; `struct ParsedCapture: Equatable { title: String; due: Date?; tag: String?; witness: String?; landmark: String? }`; `enum CaptureParser { static func parse(_ input: String, now: Date, calendar: Calendar) -> ParsedCapture? }` (nil for empty/whitespace/only-sigils).

- [ ] **Step 1: Failing tests** with a fixed `now` (Wed 2026-10-21 10:00) and Gregorian UTC calendar: due today → `.inHand`; undated → `.inHand`; +1 day → `.tomorrow`; +5 d → `.week`; +20 d → `.month`; +60 d → `.horizon`; yesterday → slipped and not `.inHand`; `scale(depth: 1) == 0.45`, `scale(depth: 0) == 1`; parser: `"dinner w/ Sam fri 7pm #home @Sam"` → title "dinner w/ Sam", due next Friday 19:00, tag "home", witness "Sam"; `"   "` → nil; `"#"` → nil; `"buy milk ^Party"` → landmark "Party"; a 500-char title parses with title intact.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** with `NSDataDetector` for dates and a token grammar for `#`, `@`, `^`; sigil words are removed from the title.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: time bands and capture parser`.

### Task 4: Horizon screen (iPhone)

**Files:**
- Create: `Horizon/HorizonLayout.swift` (custom `Layout`), `HorizonView.swift`, `TaskCard.swift`, `HoldToComplete.swift`, `CaptureBar.swift`, `CairnStrip.swift`, `Tokens.swift` (colour tokens from design section 2 in the asset catalog, `Motion` constants `settle`, `lift`, `drift`, `hold = 0.55`)
- Modify: `Simple TaskApp.swift` (root is `HorizonView`; container from `Store.makeContainer()`; `Store.relocateIfNeeded` and `Scheduler.reconcile` on launch; `#if DEBUG` menu opens Legacy screens)
- Test: `Simple TaskTests/HorizonSnapshotTests.swift`, `CompleteTests.swift`

**Interfaces:**
- Consumes: `TimeBands`, `CaptureParser`, `ToDo`, `Scheduler`.
- Produces: `func complete(_ task: ToDo, in context: ModelContext, now: Date) -> Int` (sets `isCompleted`, `completedAt`, `stateRaw="done"`, returns the new Cairn total); `func undoComplete(_ task: ToDo, in context: ModelContext)` (valid only within 5 s of `completedAt`).

- [ ] **Step 1: Failing tests:** `completeIncrementsCairnAndIsUndoableWithin5s`, `undoAfter5sIsRejected`, `slippedTaskRendersAtLeftEdgeNotRed` (snapshot asserts the `slipped` token and no red), `emptyStoreShowsEmptyState`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** the layout, caps with `+n` overflow stone, drag-to-band rescheduling (Tomorrow 9:00, next Monday, Shelf), hold-to-complete ring with Core Haptics grammar and Reduce Motion fallback, capture bar (Return commits, live chips), accessibility representation grouped by band with actions Complete, Tomorrow, Shelf, Open.
- [ ] **Step 4: Run tests; build for iPhone SE (3rd gen), iPhone 17 Pro Max, and AX5 Dynamic Type snapshots.** Expected: PASS, no clipped text.
- [ ] **Step 5: Manual check in the simulator:** add a task in under 10 s, hold to complete, Cairn shows +1, Undo works; record outcome in the commit body.
- [ ] **Step 6: Commit** `feat: horizon screen with hold-to-complete and cairn`.

### Task 5: CompleteTaskIntent and Next widget

**Files:**
- Create: `SimpleTaskKit/Intents/TaskEntity.swift`, `CompleteTaskIntent.swift`, `AppShortcuts.swift`; `SimpleTaskWidgets/NextWidget.swift`, `NextTimeline.swift`
- Test: `Simple TaskTests/IntentTests.swift`, `NextTimelineTests.swift`

**Interfaces:**
- Consumes: `Store.makeContainer()`, `complete(_:in:now:)`.
- Produces: `struct TaskEntity: AppEntity, IndexedEntity { id: UUID; title: String; due: Date?; isDone: Bool }`; `struct TaskQuery: EntityStringQuery` (suggested = In Hand); `struct CompleteTaskIntent: AppIntent { @Parameter var task: TaskEntity; func perform() async throws -> some IntentResult & ProvidesDialog }` with dialog "Stone #<n>."; `struct NextEntry: TimelineEntry { date: Date; task: TaskSnapshot? }`; `func nextEntry(from tasks: [TaskSnapshot], now: Date) -> NextEntry` (the ember = earliest not-done In Hand item).

- [ ] **Step 1: Failing tests:** `completeIntentMarksTaskDoneAndReportsStoneNumber`, `completeIntentOnMissingTaskThrowsFriendlyError`, `nextEntryPicksEarliestInHand`, `nextEntryEmptyWhenNothingInHand`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** entity, intent (opens the shared container, no UI), `AppShortcutsProvider` with phrases "Finish \(\.$task) in \(.applicationName)" and "What's next in \(.applicationName)" (the latter may open the app until `WhatsNextIntent` ships), and the small/medium Next widget with `Button(intent: CompleteTaskIntent(task:))`, reloading timelines after completion.
- [ ] **Step 4: Run all tests.** Expected: PASS.
- [ ] **Step 5: Manual check:** run the intent from the Shortcuts app in the simulator and tap Done on the home-screen widget; the task completes and the widget reloads. Note result in the commit body.
- [ ] **Step 6: Commit** `feat: complete-task intent and next widget`.

### Task 6: Slice wrap-up

**Files:** Modify `README.md`; create `docs/superpowers/specs/2026-10-23-horizon-owner-decisions.md`.

- [ ] **Step 1:** Update README with the Horizon description and build/test commands.
- [ ] **Step 2:** Record in the decisions file the calls made by the builder (app name unchanged, App Group placeholder, CloudKit off, OS 26 minimum, Family Sharing undecided) so the owner can confirm or change them.
- [ ] **Step 3:** Run the full test command. Expected: PASS.
- [ ] **Step 4:** Commit `docs: readme and owner decision log`.
