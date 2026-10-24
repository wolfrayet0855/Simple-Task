# Waymark Phase 2: plan and backlog

PM, 2026-10-24. Inputs: `charter.md`, `design.md`, `research.md`, `apple-verification.md`, the owner decisions (`docs/superpowers/specs/2026-10-23-horizon-owner-decisions.md`), the Phase 1 ledger (`.superpowers/sdd/2026-10-23-horizon-first-slice/progress.md`), the code on `horizon-slice`, and the owner's first run on a device.

Two roles: the **Implementer** builds and tests; the **Design Director** writes specs, signs off screenshots, and owns the charter's section 3 tests. Section 5 says who does what first.

## 1. Where Phase 1 left us

Shipped and green: schema V2 with lossless migration, store relocation into the App Group, UUID-keyed notifications with Done / +1 hour / Tomorrow actions, the Horizon screen with hold-to-complete and a 5 s Undo, the capture bar and parser, the Next widget, `CompleteTaskIntent` and `WhatsNextIntent`, 82 unit tests. No UI test target exists; every interaction (hold, undo, toast, menu, widget Done, Shortcuts) was logic-tested only.

Owner verdict after the first device run: "the UI needs a lot of work and still a lot of feature testing." The screenshot (`iPhone 17 Pro, 06:34`) shows why, and the code confirms it:

| # | What the owner sees | Cause in code | Fixed by |
|---|---|---|---|
| 1 | Four far bands take 54% of the screen and are empty; the field reads as blank space with labels | `HorizonView.field` gives far bands fixed heights (0.08 + 0.16 + 0.16 + 0.14 of `h`) regardless of content | WP5 |
| 2 | Cards are plain white boxes: a dot, a title; weight, tag, time, pledge and trail are invisible | `TaskCard` renders title and time only; every task is weight M because nothing can set weight; `TaskSnapshot` carries no tag, witness or landmark | WP4, WP6 |
| 3 | Cairn strip reads "0  today 0" | `CairnStrip` prints two bare numbers; there is no "Cairn" label and no zero state | WP1 |
| 4 | Tapping a card opens the old form (Save/Cancel, category picker, blue toggles) | `HorizonView.sheet(item: $editing)` presents `Legacy/DetailView` | WP4 |
| 5 | A ladybug icon floats top-right | `#if DEBUG` overlay button in `HorizonView.field`; the owner runs Debug builds on device | WP1 |
| 6 | Notification permission dialog at first launch, before the user has done anything | `ToDoListApp.init` calls `requestNotificationPermission()` | WP1 |
| 7 | A failed relocation or migration crashes at launch with no way out | `ToDoListApp.init` wraps `Store.bootstrap()` in `fatalError` | WP2 |
| 8 | Landmarks and pledges created by `^Name` and `@Name` never show up anywhere | `Capture.insert` creates `Landmark`, `Witness` and `Pledge` rows; no view renders them; `Completion.complete` never resolves a pledge | WP7, WP8 |
| 9 | No settings, no export, no way to see notification status | Legacy settings sit behind the debug menu | WP9 |

The first-run experience with two undated tasks is therefore a list of two cards under a large empty gradient. The spatial encodings the charter demands (position, size, lines) are one-third implemented: position works for dated tasks; size and lines do not exist yet.

**Phase 2 goal:** the Horizon screen passes the charter's five-second and one-minute tests on a real device, every Phase 1 feature is verified by a driver or by the owner, and nothing crashes without a recovery path.

## 2. Work packages (ordered)

Each package is sized for one sitting of the Implementer. "Needs" names the Design Director spec it depends on (section 5). Every package ends with `xcodebuild test` green on both test targets and a plain commit message with no tool attribution. Packages with a design dependency are not started until that spec is in `docs/redesign/specs/`.

Test commands (from `README.md`):

```bash
xcodegen generate
xcodebuild test -scheme "Simple Task" -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

### WP1. Launch hygiene and the Cairn label

Needs: nothing. Files: `Simple Task/Simple TaskApp.swift`, `Horizon/HorizonView.swift`, `Horizon/CairnStrip.swift`, new `Simple Task/Permissions.swift`.

Scope:
- Remove the notification request from `App.init`. Add `Permissions.requestNotificationsIfNeeded()` (async, returns the authorisation status). Call it from exactly two places: when a reminder is switched on in the task sheet (WP4), and from `Scheduler.schedule` when a task wants a reminder and status is `.notDetermined`. Keep the `-skipPermission` launch argument.
- Remove the ladybug overlay. In DEBUG builds the debug menu opens by a 1.5 s long press on the Cairn strip; nothing is drawn for it.
- `CairnStrip`: text becomes "Cairn · 1,284 stones · 6 today" (plurals handled), and "Cairn · no stones yet" when the total is 0 with the stones row replaced by a faint ground line. Put the string in a pure `CairnStrip.label(total:today:)` so it is testable. Accessibility label matches.

Acceptance:
- Fresh install, launch: no system dialog of any kind, no ladybug, strip reads "Cairn · no stones yet".
- Complete one task: strip reads "Cairn · 1 stone · 1 today".
- Switching a reminder on (after WP4) asks for permission at that moment; denying shows no error and the toggle stays on with an inline note.

Test approach: unit test for `CairnStrip.label` (0, 1, 1284/6). Unit test that `Scheduler.schedule` calls the permission hook only when status is not determined (inject a `PermissionsProtocol` the way `NotificationCenterProtocol` is injected). UI test in WP3 asserts `app.alerts.count == 0` two seconds after launch.

### WP2. Recovery instead of `fatalError`

Needs: nothing. Files: `SimpleTaskKit/Store/Relocation.swift`, `Store.swift`, `Simple Task/Simple TaskApp.swift`, new `Simple Task/RecoveryView.swift`.

Scope:
- `Store.bootstrap()` returns `enum Bootstrap { case ready(ModelContainer); case failed(BootstrapFailure) }`. `BootstrapFailure` carries `reason` (`relocationMismatch(expected:got:)`, `migrationFailed(String)`, `openFailed(String)`) and the paths involved. Legacy files are never deleted on any failure path (already true; keep a test on it).
- `App` holds `@State var bootstrap` and shows `RecoveryView` when failed. Copy never blames the user: "Your tasks are safe, but they couldn't be moved to the new location." Three actions: **Try again**; **Keep using the old location** (opens the legacy file in place through the migration plan, records `storeLocation = "legacy"`, and `Store.isReady()` returns false so widgets and intents keep showing "Open the app once…"); **Save a copy** (share sheet with the store, `-wal` and `-shm` files).
- When the App Group store itself fails to open (`openFailed`), add **Start fresh**: the broken file is renamed `SimpleTask.broken-<timestamp>.store`, never deleted, and a new store is created.
- Add DEBUG launch arguments `-failRelocation` and `-failOpen` that force each path, so the owner and the UI tests can see the screen.

Acceptance:
- Each failure reason produces the recovery screen; the legacy store is byte-identical afterwards.
- "Keep using the old location" shows the Horizon with the right task count; the widget shows the not-ready message.
- "Try again" after the cause is removed proceeds to the Horizon and sets `storeLocation = "group"`.

Test approach: unit tests on `Store.bootstrap(legacyURL:groupURL:defaults:)` in temp directories: a count override hook (`Store.relocationCountsOverride`, DEBUG/test only) forces a mismatch; a group store file filled with random bytes forces `openFailed`; "continue in place" returns a container whose fetch count equals the legacy count; the `.broken-` rename leaves the original bytes intact. One UI test per launch argument asserts the recovery screen and its three buttons.

### WP3. UI test harness and screenshots

Needs: nothing. Files: `project.yml` (new target `Simple TaskUITests`), `Simple TaskUITests/*.swift`, `scripts/screenshots.sh`, a DEBUG `-fixedNow <ISO8601>` argument honoured by `HorizonView` (replaces `TimelineView`'s date when present).

Scope:
- Launch helpers: `-seedDemo -skipPermission -fixedNow 2026-10-24T09:00:00Z`, in-memory store via `-inMemoryStore` so tests never touch the simulator's real store.
- Tests: `captureAddsCardToInHand` (type "Pay rent", return, card exists), `holdCompletesAndUndoRestores` (`press(forDuration: 0.7)`, toast "Stone #10", tap Undo, card is back), `holdUnderThresholdDoesNotComplete` (0.3 s), `menuTomorrowMovesCardOut`, `shelfChipOpensSheet`, `noAlertsOnLaunch`, `recoveryScreenAppears` (from WP2).
- `scripts/screenshots.sh` runs the screenshot test on iPhone 17 Pro and iPhone 17 Pro Max, light and dark, default and AX3 (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL`), and writes PNGs to `docs/redesign/shots/<package>/`. Every later package attaches its shots there for the Design Director's sign-off.

Acceptance: both test targets run from the one scheme; UI tests green in under four minutes on the iPhone 17 simulator; the script produces eight PNGs.

Test approach: this package is the test approach for everything after it. Flakiness rule: a UI test that fails twice in CI-style runs gets an explicit wait, not a retry.

### WP4. Task sheet (replaces the legacy form)

Needs: **D1**. Files: new `Horizon/TaskSheet.swift`, new `SimpleTaskKit/Horizon/TaskEdits.swift`, `HorizonView.swift` (present the sheet instead of `DetailView`).

Scope (design.md 3.3):
- A card with detents `.medium` and `.large`, autosave on every change, no Save or Cancel. Rows top to bottom: Title with Weight S/M/L; When (Undated | date, time, All day); Remind (toggle and time; WP1's permission request fires here); Steps (add, toggle, delete, reorder; a **Smaller** button inserts an empty step and focuses it, no on-device model yet); Tag (persisted `Tag` rows plus "New tag"); Pledge (witness name and state, read-only until WP8); Trail (landmark title, read-only until WP7); Notes (`TextEditor`, Writing Tools left at the default); a **Hold to finish** bar reusing `holdToComplete`. A ⋯ menu holds Delete with a red destructive confirmation, the only red in the app.
- All mutation logic lives in `TaskEdits` (Kit): `setWeight`, `setWhen(.undated | .at(Date, allDay:))`, `setReminder(on:at:)`, `addStep`, `moveStep`, `removeStep`, `setTag`, `setNotes`, `delete`. Each updates `modifiedAt`, saves, and returns what the scheduler must do. The view calls `Scheduler.schedule` and `Widgets.reload` on dismiss.
- Removing the date sets `isDated = false`, `stateRaw = "inHand"`; bringing a shelved task back by setting a date sets `stateRaw = "active"` (the legacy Save button did this; keep it).

Acceptance:
- Every row round-trips: change, dismiss, reopen, value is there; the card and band update on dismiss.
- Weight changes card height on the Horizon (S 56, M 72, L 96 pt at scale 1).
- Clearing the date moves the card to In Hand; setting tomorrow 9:00 moves it to Tomorrow.
- Reminder on with permission not determined asks exactly then; after a grant, exactly one pending request with id `task.<uuid>.reminder`.
- VoiceOver reads every row with its value; at AX5 nothing clips; dark mode matches D1.

Test approach: unit tests for every `TaskEdits` function (including subtask `order` after a move and that `setReminder(on: false)` removes the pending request through the fake centre). UI tests: open from card tap, retitle, dismiss, card shows the new title; hold-to-finish bar completes and the toast appears. Screenshots for D1 sign-off.

### WP5. Field density and empty states

Needs: **D2**. Files: new `SimpleTaskKit/Horizon/HorizonLayout.swift`, `HorizonView.swift`, `BandField.swift`.

Scope:
- Pure `HorizonLayout.heights(counts: [Band: Int], landmarks: Int, available: CGFloat, minInHand: CGFloat) -> [Band: CGFloat]`: a far band with nothing in it collapses to a 24 pt rail (label and rule only, per D2); a band with content takes its design fraction; In Hand receives everything left and never drops below 40% of the field. The all-empty field shows one nudge line in the far field (D2 copy), not one label per band.
- The sky gradient and the horizon rule follow D2 exactly (D2 decides whether the rule, the perspective lines or a tinted horizon band carry the "landscape" reading; the Implementer builds whichever D2 says and nothing extra).
- Interim iPad handling: field content capped at 640 pt wide and centred. The sideways field stays in Phase 3.
- Band transitions animate with `Motion.drift`; Reduce Motion crossfades at 0.2 s.

Acceptance:
- Two undated tasks: In Hand occupies at least 70% of the field; the far field is one rail per band plus the single nudge.
- Demo seed: the layout matches D2's drawing within 8 pt per band on iPhone 17 Pro.
- Adding a task dated in 12 days expands Month with `drift`; completing it collapses Month again.
- iPad simulator: cards do not stretch past 640 pt.

Test approach: unit tests on `heights` (sums to `available`, empty bands collapse, In Hand floor holds, all-empty case). Screenshots in light, dark, AX3, iPhone 17 Pro and Pro Max, plus iPad, signed off by the Design Director.

### WP6. Card and chip anatomy

Needs: **D3**. Files: `TaskCard.swift`, `BandField.swift`, `SimpleTaskKit/Horizon/TimeBands.swift` (`TaskSnapshot`), `Tokens.swift`.

Scope:
- `TaskSnapshot` gains `tagToken: String?`, `witnessInitial: String?`, `landmarkTitle: String?`, `isAllDay`. `Tokens` gains `tag(_ n: Int) -> Color` for `tag.1`…`tag.8` with the light and dark hex values from D3.
- `TaskCard` per D3: weight visible through height and (if D3 says so) width; a 3 pt tag notch on the leading edge; time or countdown in the `type.countdown` style (monospaced digits; "2:00 pm" today, "all day", "T-12d" for trail tasks); a witness lantern (◉ with initial, `witness` colour) when a pledge exists; a landmark mark (▲ title, `landmark` colour) when on a trail; slipped tint for slipped items; the ember card centred and full width as in design.md 3.1.
- `FarChip` per D3: title plus a short relative date ("Thu", "in 12d"); the `+n` stone fans out on tap into a sheet listing that band's tasks (reuse the `ShelfSheet` pattern); far chips get the VoiceOver actions Complete, Tomorrow, Shelf and Open and a rotor grouped by band (deferred from Phase 1).

Acceptance:
- S, M and L cards differ by at least 16 pt in height side by side; a stranger can tell which of three cards is the big one.
- Tag notch, lantern and landmark mark appear on the demo seed ("Groceries #home", "Send deck to Priya @Priya", "Draft toast ^Sam40").
- Every tag colour and every text colour reaches 4.5:1 on `ground` in light and dark.
- VoiceOver on a far chip offers the four actions; the rotor lists bands in time order.

Test approach: unit test computing contrast ratios for all tokens against `ground` (both appearances); `HorizonModel` tests that snapshots carry tag, witness initial and landmark title; UI screenshot set for D3 sign-off; a UI test that performs the "Tomorrow" accessibility action on a far chip.

### WP7. Landmarks and trails

Needs: **D4**. Files: `HorizonModel.swift`, new `SimpleTaskKit/Horizon/Trails.swift`, `HorizonView.swift`, `BandField.swift`, new `Horizon/LandmarkScreen.swift`, new `SimpleTaskKit/Horizon/LandmarkEdits.swift`.

Scope:
- `HorizonModel` gains `landmarks: [LandmarkSnapshot]` (id, title, date, T-minus days, open/total tasks, isReached). The Horizon band shows up to four ▲ markers in serif `type.landmark`, placed by date along the band (pure `Trails.markerX(date:now:width:)`), overflow as `+n`.
- Trails: chip and marker frames are collected with a `PreferenceKey`; a `Canvas` overlay draws one quadratic Bézier per trail task from the marker to the chip (design.md 3.1), `landmark` colour at 0.5 opacity, drawn with `Motion.trailDraw` on first appearance; Reduce Motion crossfades.
- Tapping a marker opens `LandmarkScreen` (design.md 3.4, minimal): title, editable date, T-minus, waypoints sorted by `offsetDays` with done or open state, **+ waypoint** (creates a task on the trail with an offset). `LandmarkEdits.setDate` recomputes `dueDate` for every task with `offsetDays`, which slides the whole trail. Templates, buffer, owners and run-of-show are deferred.
- A landmark whose date has passed renders in `slipped` grey with "reached", never red.

Acceptance:
- Demo seed shows ▲ Sam40 with three trails to "Draft toast", "Order cake", "Book venue".
- Moving Sam40 forward by 7 days moves all three tasks by 7 days and the chips drift.
- Capture `^Launch in 45 days` places a marker on the horizon.
- A reached landmark is grey, not red.

Test approach: unit tests for `markerX`, `LandmarkEdits.setDate` offsets, `HorizonModel.landmarks` grouping and the four-marker cap. UI test: tap marker, change date, dismiss, chips moved (assert a chip's accessibility value changed). Screenshots for D4 sign-off.

### WP8. Pledges: lanterns, resolution, receipt

Needs: **D5**. Files: `Completion.swift`, new `SimpleTaskKit/Horizon/PledgeEdits.swift`, `TaskSheet.swift` (Pledge row becomes editable), new `Horizon/WitnessesSheet.swift`, new `Horizon/Receipt.swift`.

Scope:
- `Completion.complete` sets the task's pledge to `kept` with `resolvedAt`; `Completion.undo` reopens it. This is a correctness bug today, not a feature.
- Pledge row in the task sheet: witness name, state, **Renegotiate** (new date, optional note; counts as honest per design.md 3.5), **Release**. `PledgeEdits` in Kit.
- Witnesses sheet (reached as D5 says, default: tapping a lantern): one row per witness, "Priya: 2 open, 14 kept, 3 renegotiated"; "Me" holds self pledges. No failure counts anywhere.
- Receipt: `ImageRenderer` of a card "I promised X by Y. Done at Z." shared through `ShareLink`, with the plain text `https://task.shapehaveninnovations.com/p/<id>` appended. Nothing is sent automatically. The domain is unhosted until the owner publishes the association file; the link is text only.

Acceptance:
- Completing a pledged task marks the pledge kept; Undo reopens it; completing twice changes nothing.
- Renegotiating updates `byDate` and the task's due date together and increments the witness's renegotiated count.
- The receipt renders at 3x in light and dark and shares as an image plus text.

Test approach: unit tests on `Completion` and `PledgeEdits` state transitions and counts; a test that `Receipt.render` returns a non-nil image of the expected size; a UI screenshot of the Witnesses sheet.

### WP9. Settings, JSON export, delete the legacy screens

Needs: **D6** (one screen; can be a page in D2). Files: new `Horizon/SettingsSheet.swift`, new `SimpleTaskKit/Export/JSONExport.swift`, delete `Simple Task/Legacy/*`, `project.yml`.

Scope:
- Settings entry where D6 places it (default: a small glyph in the top-trailing corner the ladybug used to occupy). Rows: Reminders (authorisation status, a link to the system settings when denied), Remind me on this device (per-device default, iPhone on), Export (`waymark.v2.json`, every model, `ShareLink`), Dusk (off, "coming later", disabled), About (version, the MIT licence text).
- Delete `Legacy/` entirely, including `CategoryManager` and the `environmentObject`. The DEBUG menu keeps only "Seed demo" and "Reset store".
- Attempt Swift 6 language mode now that the legacy code is gone. If it takes more than this sitting, revert the mode flag and log it in the ledger.

Acceptance:
- Build has no `Legacy` folder and no `CategoryManager`; `grep -r CategoryManager` is empty.
- Export of the demo seed decodes with a Codable mirror and has matching counts and ids for tasks, subtasks, tags, landmarks, witnesses and pledges.
- Settings is reachable with VoiceOver and at AX5.

Test approach: unit round-trip of the export encoder and decoder; a UI test opens Settings and triggers Export (assert the share sheet appears); screenshots for D6 sign-off.

### WP10. Query diet and a shared container

Needs: nothing. Files: `HorizonView.swift`, `Store.swift`, `TaskActions.swift`, `CompleteTaskIntent.swift`, `NextWidget.swift`.

Scope:
- `HorizonView` queries only open tasks (`!isCompleted`); the Cairn total and today's count come from `fetchCount` with predicates, refreshed on save notifications and on the minute tick. `slippedDays` uses the timeline's `now`, not `.now`.
- `Store.shared` (lazy, one `ModelContainer` per process) replaces the per-call container in intents and the widget.
- `CompleteTaskIntent` removes the task's pending notification itself so the widget and Shortcuts paths leave no stale reminder.
- Migration plan: replace the static snapshot dictionary with an instance held for the stage's lifetime (the Swift 6 concern in the ledger).

Acceptance:
- With 2,000 completed and 40 open tasks seeded, the Horizon renders in under 100 ms per tick (signpost) and scrolls without hitches.
- Completing from the widget leaves zero pending requests for that task.

Test approach: an XCTest `measure` block building the model from a seeded in-memory container; a unit test on the intent path asserting the fake centre's pending ids; existing migration tests stay green.

## 3. Device-test checklist for the owner

Run on the iPhone with a Debug build installed from Xcode unless a step says otherwise. Mark each line pass or fail and paste the list into the ledger. Items marked **(after WPn)** wait for that package; everything else can run on `horizon-slice` today.

**A. Hold-to-complete and Undo**
1. Hold a card for under a quarter second and release: nothing happens, the card does not open.
2. Tap a card: the editor opens (the legacy form today; the task sheet after WP4).
3. Hold a card: the ember ring draws around the edge while the haptic ramps; release after the ring closes. Expected: the card drops out with a spring, the strip's total and today counts rise by one, a toast "Stone #n · Undo" appears.
4. Tap Undo within 5 s: the card returns, counts fall by one.
5. Let the toast expire: the task stays done; reopening the app does not resurrect it.
6. Settings → Accessibility → Motion → Reduce Motion on: a single tap completes, with the Undo toast; a hold does nothing extra.
7. VoiceOver on: swipe to a card, hear "Hold to finish"; use the actions rotor: Complete, Tomorrow, Shelf, Open all work; the undo window is 15 s.

**B. Capture**
8. Type `dinner w/ Sam fri 7pm #home @Sam` and return in under ten seconds from a cold start. Expected: chips show the parsed date, tag and pledge before you commit; the card lands in the right band; the title reads "dinner w/ Sam".
9. Type `#` alone, then whitespace only, then 500 characters: never a crash; empty input never adds a task.
10. Type `Call mum tomorrow 10am`: lands in Tomorrow; `in 45 days`: lands on the Far horizon; `on wed 3pm`: lands in This week.

**C. Widget Done**
11. Add the Next widget (small and medium) to the Home Screen. Expected: it shows the ember task with its time and a Done button; empty field shows "Clear skies."
12. Tap Done with the phone unlocked: the task completes, the widget reloads to the next task, the app's Cairn count agrees when opened.
13. Tap Done on the Lock Screen (if the widget is placed there): the system asks you to authenticate first; after unlocking, the action runs.
14. Set a reminder on the ember task (after WP4), tap Done on the widget before it fires: the reminder never arrives **(after WP10)**.

**D. Shortcuts and Siri**
15. Open Shortcuts, add "Finish task in Waymark": the task picker suggests In Hand items; run it; the task is done and the app agrees.
16. "What's next in Waymark" returns the ember task's title as a result and as a spoken snippet.
17. Say to Siri: "Finish Pay rent in Waymark" and "What's next in Waymark". Note which phrases work and which do not; this feeds Phase 3.
18. With the app force-quit, run the Shortcut: it still works (the store is read from the App Group).

**E. Upgrade from the shipped 1.2**
19. On a device (or a second device) with the App Store 1.2 build, create: "Alpha" with subtasks a, b, c in that order; "Beta" with a reminder 15 minutes ahead; "Gamma" completed; "Delta" category "Errands"; "Epsilon" all day tomorrow; and a custom category "Garden" assigned to "Zeta". Write down the six titles.
20. Install the Phase 2 build from Xcode over it (same bundle id `beta.SimpleTask`, same team). Launch. Expected: no crash, no recovery screen; Alpha, Delta, Zeta In Hand or in their bands; Gamma in the Cairn count; Epsilon in Tomorrow.
21. Open Alpha (after WP4): steps read a, b, c in order. Open Zeta: tag "Garden" is present; the tag list shows Work, Errands, Garden and the defaults, nothing collapsed into Other.
22. Beta's reminder fires once at the right minute with "Ready when you are: Beta" and the Done / +1 hour / Tomorrow buttons; it does not fire twice.
23. Force-quit and relaunch twice: no duplicated tasks, same counts.
24. Force the recovery screen with `-failRelocation` in the scheme's launch arguments **(after WP2)**: try each of the three buttons; confirm the old store still exists afterwards in the app's Application Support folder (Xcode → Devices → download container).

**F. Notifications**
25. Fresh install: no permission dialog at launch **(after WP1)**; the dialog appears the first time a reminder is switched on.
26. Deny permission, then switch a reminder on: an inline note points to Settings; nothing crashes.
27. Reminder banner while the app is open: appears as a banner with sound.
28. From the Lock Screen notification: Done completes (Cairn +1), +1 hour reschedules (check the pending time in the sheet), Tomorrow moves the task to Tomorrow 9:00.
29. Rename a task that has a reminder, then let it fire: exactly one notification, with the new title.

**G. Appearance and accessibility (after WP5 and WP6)**
30. Dark mode: sky, ground, cards and tags all legible; no pure white card on a dark field.
31. Dynamic Type at AX3 and AX5: nothing clips, the capture bar still works, far chips degrade gracefully.
32. Increase Contrast: text remains readable on `ground`.
33. iPad: cards do not stretch edge to edge; everything is reachable.

**H. The charter's tests (after WP7)**
34. Show five people a muted five-second recording of the demo-seeded Horizon with the name hidden. Record: can they name an app it resembles; can they say what the screen is for. Pass is four cannot name one and all five can say what it is for.
35. Hand the phone to one person for a minute. Ask what it does that no list app does. Expected answers are in design.md section 11.

## 4. Deferred (not in Phase 2)

Deferred means a decision, not a maybe. Each item has a home.

- **Drag a card to another band.** It fights the hold gesture. The ⋯ menu and the VoiceOver actions cover Tomorrow, Next week and Shelf. The Design Director may propose a gesture that resolves the conflict (for example, a lift after the hold threshold) as part of D3; it is built in Phase 3 only if the spec is unambiguous.
- **Dusk** (design.md 3.6). The toggle appears disabled in Settings so the owner can see it is coming.
- **Landmark templates, buffer, owners, run-of-show, Draft trail.** WP7 ships the minimal screen.
- **Sideways field for iPad and Mac, and the Mac target.** WP5 caps width on iPad; that is all.
- **Remaining intents** (`AddTask`, `DeferTask`, `PlanLandmark`, `Pledge`, `ListDue`, `OpenHorizon`, `StartFocus`), Controls, Live Activities, the Watch app, OS 27 App Schemas and View Annotations. Phase 3.
- **On-device model features** (brain-dump parsing, Smaller, Draft trail, Dusk sentence). The **Smaller** button ships in WP4 with the manual fallback only.
- **Interop**: EventKit, Reminders import, `.ics`, the URL scheme, webhooks, the Mac helper. Phase 4. JSON **export** is the one exception (WP9) because "data leaves freely" is a charter principle and it costs one sitting.
- **CloudKit sync on.** Code is ready; `Features.cloudSync` stays false until the owner creates `iCloud.beta.SimpleTask` in the developer portal and runs a two-device test. Owner action, not a package.
- **Universal links for receipts.** The owner hosts the association file on `task.shapehaveninnovations.com`; until then the receipt carries plain text.
- **Core Haptics grammar.** UIKit generators stay; revisit when the owner reports the feel.
- **Estimates, actual minutes, recurrence, if-then cues, StoreKit Plus.** Phases 3 to 5 as chartered.
- **Snapshot-test library.** Screenshots from the UI test target serve as snapshots; no third-party dependency.

## 5. Division of labour

### Design Director: specs, in this order

Each spec is a markdown file in `docs/redesign/specs/` with an ASCII layout, exact Dynamic Type styles, spacing in points, copy strings, every state (empty, one item, many, slipped, dark, AX3, Reduce Motion), and the existing tokens from design.md section 2. New colour values appear only for the eight tag tokens (D3). No Swift. Each spec is sized so the Implementer can build it in one sitting; if it is not, split it before handing it over.

| Spec | Unblocks | What it must decide |
|---|---|---|
| **D1 Task sheet** | WP4 | Row order and heights at both detents, weight control (segmented or three cards), the When row's undated state, the Remind row with the permission moment, how Steps reorder, where Delete lives, the Hold-to-finish bar, copy for every label and empty state |
| **D2 Field density and the empty field** | WP5, WP9 | Collapsed-rail height, which element carries the landscape reading when bands are empty, the single nudge line, the horizon rule and gradient stops, the iPad width cap, the Settings glyph position (D6 folds in here) |
| **D3 Card and chip anatomy** | WP6 | S/M/L dimensions and whether width varies, ember treatment, tag notch and the eight tag colours with contrast proof, countdown formats, lantern and landmark marks, far chip content, the `+n` stone fan-out, and a verdict on drag-to-band |
| **D4 Landmarks and trails** | WP7 | Marker shape and type, placement along the band, trail curve and stroke, the reached state, the minimal Landmark screen |
| **D5 Pledges** | WP8 | Lantern tap target, the Witnesses sheet, the Renegotiate and Release flows, the receipt card at 3x in both appearances |

After the specs, the Design Director reviews each package's screenshot set in `docs/redesign/shots/` and either signs off in the ledger or returns one list of deltas. The Director also prepares and scores the five-second and one-minute tests (checklist H) and, per design.md section 11, raises landmark scale and trail contrast before anyone touches the metaphor.

### Implementer: packages, in this order

WP1 → WP2 → WP3 → WP4 (D1) → WP5 (D2) → WP6 (D3) → WP7 (D4) → WP8 (D5) → WP9 (D6) → WP10.

WP1 to WP3 need no design and take three sittings; D1 must be ready by the time WP3 lands, D2 by the end of WP4, D3 by the end of WP5, and so on. If a spec is late, the Implementer pulls WP10 forward rather than guessing at design.

Rules for every package: tests first where there is logic; logic in `SimpleTaskKit`, views in the app; one commit per package with a plain message; update the ledger `.superpowers/sdd/2026-10-24-horizon-phase2/progress.md` with rulings and the test count; never widen scope into a deferred item. If a package will not fit one sitting, stop, split it in the ledger, and continue.

### Owner

- Run checklist sections A to F now on `horizon-slice`; G and H when the plan says.
- Provide the 1.2 upgrade device for E.
- Provision the CloudKit container and the association file when convenient; neither blocks Phase 2.

## 6. Calls made in this plan

Recorded so nobody reopens them without a reason.

1. Permission is asked when the first reminder is switched on, nowhere else.
2. The debug menu is a hidden long press on the Cairn strip in DEBUG builds; nothing is drawn.
3. The task sheet autosaves; there is no Save or Cancel.
4. Red appears once: the Delete confirmation.
5. Far bands collapse when empty; In Hand is the screen's centre of mass on a quiet day.
6. The ⋯ menu stays as the reschedule control through Phase 2.
7. JSON export is in scope; import is not.
8. Legacy screens are deleted in WP9, not kept behind a flag.
9. Swift 6 is attempted once, in WP9, and reverted if it costs more than the sitting.
10. Screenshots from the UI test target are the snapshot mechanism.

**Phase 2 is done when:** WP1 to WP10 are merged, the owner's checklist A to G is all pass, and checklist H passes or the Director has delivered one iteration in response.
