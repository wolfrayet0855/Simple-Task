# Simple Task Redesign: Charter

Owner: wolfayet0855. PM. Research: Researcher (`research.md`). Design: Designer (`design.md`). Draft v1, 2026-10-23.

## 1. Intent and why

Simple Task today is 605 lines of SwiftUI: a `ToDo` with a unique title, due and reminder dates, a string category, subtasks, a four-way segmented filter, local notifications, and a monthly open/closed bar chart. It works, and it is indistinguishable from a thousand other list apps.

The owner's brief is not "add features." It is: build what a human actually needs for **task mastering** (finishing what matters, not collecting items), **event planning** (work that converges on a date, often with other people), and **accountability** (keeping a promise to yourself or someone else, visibly). No shipping app treats these as one problem. Lists treat accountability as a red badge; calendars treat tasks as 15-minute blocks; neither treats an event as a plan that unfolds backwards from a moment.

Platform (decided): native SwiftUI, SwiftData with CloudKit sync, targeting iOS, iPadOS, macOS, watchOS. The required integrations (Watch, widgets, Siri, App Intents, Apple Intelligence) are only first-class here.

## 2. Goals, non-goals, anti-goals

**Goals (v1.0)**
1. One data model representing a task, an event plan, and a commitment to a person, on one primary surface.
2. A main view a stranger cannot mistake for Reminders, Things, or Todoist in a five-second glance (test in section 3).
3. Every required integration live: watchOS app, WidgetKit (home, lock, Watch), App Intents driving Siri and Shortcuts, Apple Intelligence where available, notifications that reach iPad and Mac.
4. Interoperability: EventKit two-way for events, Reminders import, JSON and `.ics` export/import, documented URL scheme, outbound webhooks, local MCP server on macOS.
5. One or two paid features passing section 6.
6. Existing users' data survives migration with zero loss.

**Non-goals**
- Team backends or accounts. Accountability is person-to-person via CloudKit sharing, share sheets, or exported artifacts.
- Android, web, Windows.
- A generic chatbot inside the app.
- Gamification (points, streak flames, leaderboards).

**Anti-goals (ways to fail even if it works)**
- It compiles, syncs, and looks like Reminders with a different accent color.
- Accountability becomes shame: red everywhere, guilt copy, loss-aversion nags.
- The paid tier gates the core promise.
- Integrations are checkboxes: a Siri intent that only adds, a widget that only counts.
- So novel that a new user cannot add a task in ten seconds.
- Mac and iPad are scaled-up phone layouts.

## 3. Design principles

1. **Time has a shape.** Tasks have distance-to-deadline, weight, and direction (toward an event, toward a person). The UI encodes at least two of these spatially, not as metadata text.
2. **Plan backwards.** An event is a date you work toward; the default way to plan one is from the moment, backwards.
3. **Accountability is a witness, not a whip.** Show who you promised and what you did; let them see it. Never punish.
4. **Finishing is the hero action.** Completing must be more satisfying and visible than adding. The app gets calmer as you master it.
5. **Native, but not default.** System materials, Dynamic Type, SF Symbols, platform idioms; but no stock `List` as the primary surface and no `Form` as the primary editor.
6. **Every surface closes a loop.** Watch, widget, Siri, Shortcuts, and MCP each support capture, act, and confirm, not capture alone.
7. **Data leaves freely.** Everything exportable in open formats, free tier included.

**The "looks and feels different" test:** show five people unfamiliar with the app a muted five-second recording of the main view, name removed. Pass if at least four cannot name an existing app it resembles *and* all five can say what the screen is for. Second test: after one minute of use, a user can name, unprompted, something it does that no list app does. Either failure sends the Designer back for one iteration.

## 4. Research questions for the Researcher

1. Current SwiftData + CloudKit requirements (`ModelConfiguration(cloudKitDatabase:)`): unique constraints, optional relationships, defaults, and the migration path for a store that already has `@Attribute(.unique)`.
2. Which Apple Intelligence surfaces third-party apps can use today (App Intents with Siri, Foundation Models, Writing Tools, Visual Intelligence), on which OS versions and devices, and the correct fallback when unavailable.
3. How a reminder set on iPhone fires on iPad and Mac with no server of ours: local scheduling per device, CloudKit subscriptions, silent push.
4. Current App Intents, WidgetKit (interactive, Watch complications), and watchOS 26 patterns for a SwiftData store shared via App Groups.
5. How the best non-conventional planning tools and analog methods (timeline-first, spatial, backward-planning, commitment-based) represent time, events, and promises; what users say works and fails.
6. Shipping a local MCP server inside a sandboxed Mac app: stdio vs. HTTP transport, how MCP clients discover it, which task operations agents realistically need.
7. EventKit, EKReminder, `.ics`, URL scheme, and webhook patterns peer apps use; required entitlements and privacy strings.
8. Which indie productivity pricing models users and reviewers consider fair, and which patterns Apple guidelines or public sentiment treat as dark.

## 5. Brief to the Designer

**Fixed**
- Platform and stack. Swift 6 language mode; OS 26 minimum unless research question 2 forces lower.
- The three jobs, served by one model and one primary surface.
- Integration and interoperability lists (goals 3 and 4).
- Principles and tests in section 3; guardrails in section 6.
- CloudKit-compatible model from day one: UUID identity, optional relationships, defaults everywhere. Existing fields (`item`, `dueDate`, `reminderDate`, `reminderIsOn`, `isCompleted`, `isAllDay`, `category`, `subtasks`) map losslessly.
- No accounts, no server of ours.

**Free to invent**
- The core metaphor and primary visualization (timeline, map, orbit, ledger, something new). The bar chart and segmented filter are not sacred.
- Information architecture, navigation, naming, iconography, motion, sound, haptics.
- How "a person you promised" is modeled, shown, shared, and witnessed.
- How backward planning from an event works and what it generates (milestones, buffers, prep tasks).
- What Watch, widgets, Siri, and MCP do beyond capture, provided each closes a loop.
- Which one or two features are paid, within section 6.
- Whether categories survive, become richer, or disappear.

**Deliverable:** `docs/redesign/design.md` covering model, primary surface, per-platform surfaces, integration behaviors, paid proposal, and a written argument for passing the section 3 tests. Include one rejected alternative and why.

## 6. Paid-tier guardrails

- Free completes every job end to end: create, plan, commit, finish, sync, export, notifications, one widget, one Siri intent.
- Paid adds power or delight; never removes or throttles. No task caps, sync caps, export locks, or watermarks.
- One-time purchase, or subscription with a one-time option; Family Sharing on; no trial that silently converts.
- Ethics test: would a never-paying user still recommend the app, and would a paying user feel the money bought something real? Both must be yes.
- Allowed: planning automation, extra integrations (webhooks, MCP), deep history and insight, themes.
- No upsell during capture or completion. One place in Settings, one tasteful mention where a paid feature would help.

## 7. Phased delivery

**[sim]** = verifiable with `xcodebuild` and simulators. **[owner]** = needs a device, signing, or App Store Connect.

**Phase 0: Foundation (week 1).** Test target, CI script, delete stray `desktop`/`dekstop` storyboard copies, raise deployment targets, entitlements file, App Group, Swift 6.
Acceptance: `xcodebuild test` passes on iOS and macOS simulators [sim].

**Phase 1: Model and migration (weeks 1-2).** `VersionedSchema` + `SchemaMigrationPlan`: UUID `id`, `item` no longer unique, optional relationships, defaults. CloudKit behind a flag.
Acceptance: migration test seeds a v1 store with subtasks, migrates, asserts zero loss [sim]. Notification identifiers become UUIDs; renaming no longer orphans a reminder [sim]. Sync between two signed-in devices [owner].

**Phase 2: Primary surface (weeks 3-5).** The Designer's design on iPhone, iPad, Mac; backward planning; the finishing interaction.
Acceptance: snapshot tests at three size classes [sim]; five-person test and ten-second test [owner].

**Phase 3: Surfaces (weeks 6-8).** App Intents (create, complete, list due, plan event), Siri phrases, Shortcuts; widgets; watchOS app with complications; Apple Intelligence with fallback.
Acceptance: intents run from Shortcuts in simulator, widget timeline snapshots, Watch app on paired simulator [sim]; Siri voice and Apple Intelligence [owner].

**Phase 4: Interop (weeks 8-10).** EventKit two-way, Reminders import, JSON and `.ics` round trip, URL scheme, webhooks, macOS MCP server.
Acceptance: round-trip tests per format; MCP server answers `tools/list` and task CRUD from a scripted client [sim]; EventKit against a real account [owner].

**Phase 5: Paid and release (weeks 10-12).** StoreKit 2, assets, privacy manifest, review.
Acceptance: StoreKit configuration tests [sim]; TestFlight and submission [owner].

Phases 3 and 4 ship independently; cut webhooks and Reminders import first if the schedule slips.

## 8. Risks

| Risk | Mitigation |
|---|---|
| `@Attribute(.unique) var item` is incompatible with CloudKit; existing stores must migrate | Phase 1 versioned migration with seeded test; local-only fallback when iCloud is off |
| Notification identifier equals the task title; duplicates and renames already break reminders | UUID identifiers; re-schedule all pending notifications once |
| `CategoryManager` is in-memory and resets on launch; tasks store category strings | Persist categories (or successor) in SwiftData; map unknown strings to "Other" |
| Apple Intelligence varies by OS, device, region, language | Capability check; identical UX with rules-based fallback; never the core pitch |
| Entitlements (iCloud, App Groups, Push, Siri, EventKit, Reminders) need the owner's team and App Store Connect | Owner provisions in Phase 0; development proceeds on simulator with CloudKit flag off |
| Completion conflicts across four synced platforms | Last-writer-wins with `completedAt` timestamp; two-simulator plus device test |
| Cross-device notification delivery without a server | Decided by research question 3 |
| MCP server in a sandboxed Mac app | stdio transport launched by the client; Mac-only, optional |
| Novel design fails section 3 tests | Tested at Phase 2 before later phases depend on it |
| `UIColor` in `GraphView` breaks the Mac build; no tests exist today | Semantic SwiftUI colors in Phase 2; Phase 0 test target is a hard gate |

## Research questions (short list)

1. SwiftData + CloudKit constraints and migration from `@Attribute(.unique)`.
2. Apple Intelligence surfaces for third-party apps: versions, devices, fallbacks.
3. Cross-device notifications (iPad, Mac) without our own server.
4. App Intents, WidgetKit, watchOS 26 patterns for a shared SwiftData store.
5. How non-conventional planning tools represent time, events, promises.
6. Local MCP server in a sandboxed Mac app: transport, discovery, operations.
7. EventKit, Reminders, `.ics`, URL scheme, webhook patterns and entitlements.
8. Fair indie pricing versus dark patterns.
