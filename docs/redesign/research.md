# Simple Task redesign: research brief (2026-10-23)

Confidence tags: [V] verified in a fetched/searched source this session; [S] single or secondary source; [U] unverified, from background knowledge, check before relying on it. Search results were mostly third-party blogs, so Apple-specific claims should be re-checked on developer.apple.com.

## 0. Current codebase (6 files, ~600 lines)
- SwiftData models `ToDo` (item, dueDate, reminderDate, isCompleted, isAllDay, category String, subtasks) and `SubTask`. `CategoryManager` is an in-memory ObservableObject (categories reset on relaunch). Views: list with sort picker, DetailView, GraphView (Charts), SettingsView. Local notifications only.
- **CloudKit blockers already present:** `@Attribute(.unique) var item` (unsupported by CloudKit), `ToDo.subtasks: [SubTask]` non-optional to-many, `SubTask.name`/`isCompleted` lack inline defaults. Also no stable UUID, no createdAt/completedAt, no recurrence, no estimate, no time-of-day model. Using a task's title as its identity also means two tasks cannot share a name. Fix these before any sync, widget or intent work.

## (a) Apps people love and hate; human pain points
Caveat: no neutral user-complaint data was found; vendor comparison blogs dominate results (e.g. [Morgen](https://www.morgen.so/blog-posts/adhd-productivity-apps), [Fabric](https://fabric.so/comparison/best-calendar-for-adhd)). Patterns below combine those with background knowledge [S/U].

| App | Loved for | Complaints / risk |
|---|---|---|
| Things | Calm, craft, fast capture, Today/Evening split | One-time price, no collaboration, no time-boxing, no AI; lists still grow |
| Structured | Timeline day view, tasks and events on one axis | Free tier limits; plans become a wall of blocks when the day slips |
| Sunsama | Guided daily-planning ritual, shutdown ritual | ~$16-20/mo; skip the ritual and value vanishes; planned-vs-actual can feel like guilt [S: Fabric] |
| Akiflow / Motion | Time-blocking, auto-scheduling | Price (~$19/mo Motion annual) [S]; auto-scheduling removes user control and reshuffles constantly |
| Tiimo | Visual icon timeline, countdown timers, built for time blindness; Apple's 2025 iPhone App of the Year [U] | Subscription for full features; some find it too busy [S] |
| Goblin Tools | Magic ToDo: break task into steps with a "spiciness" slider | Utility, not a system; no calendar or reminders |
| Finch / Forest | Emotional, gentle gamification (pet, tree) | Reward tied to streaks can turn to guilt when pet suffers; childish for some adults |
| Streaks | Clean habit rings, Watch/widget quality | Streak-loss anxiety is the core mechanic |
| Fantastical | Natural-language entry, calendar sets, Tasks and events together | Subscription; calendar-first |
| Todoist | Natural language, filters, cross-platform | Overdue list grows red; "karma" gamification divisive; feature creep |
| Apple Reminders | Free, system-wide, Siri, Shared lists, Today Smart List | Weak planning; overdue pile; limited time awareness |

**Human pain points to design against**
- **Overwhelm and the infinite list:** the list shows everything, so the app shows the shame of everything. Show a small, finite "today" (3 to 5 items) and hide the rest.
- **Time blindness:** durations are abstract. Show time as a physical or visual quantity (remaining sand/arc), not a number only.
- **Planning fallacy:** people underestimate by default. The app can learn the user's own estimate-to-actual ratio and silently show "usually takes you 1.6x." This is cheap and needs no AI model.
- **Abandonment:** planning-heavy apps (Sunsama-type rituals) fail when a day is missed. Re-entry must be frictionless: no "you missed 14 days" banner.
- **Overdue guilt:** red counts and rolling over unfinished tasks teach avoidance. Offer a "Declare bankruptcy / Reset" action, soft "slipped" language, and automatic drift to a "Someday / Reconsider" bucket after N days.
- **ADHD specifics:** starting is the hard part (task initiation), not listing. Needs: tiny first step, low-friction capture (widget, Action button, Siri), visible time, and reduced decisions. Avoid anything requiring daily upkeep.

## (b) Accountability research and ethics
- **Implementation intentions ("if X then I will Y")** are the best-supported cheap technique: Gollwitzer & Sheeran 2006 meta-analysis d~0.65 over 94 tests; a 2024 update (Sheeran, Listrom, Gollwitzer, 642 tests) reports d between .27 and .66, larger for if-then format, motivated people and rehearsed plans [V via [summary](https://goalsandprogress.com/implementation-intentions-research/) and [KOPS record](https://kops.uni-konstanz.de/handle/123456789/69905); read the paper itself before quoting numbers]. App translation: every task gets an optional "when/where" cue (time, place, after-event) rather than just a due date.
- **Commitment devices:** stickK-style contracts show associations with better outcomes, mainly observational/field data with stickK-affiliated authors (Karlan) [V: [FTC-hosted paper](https://www.ftc.gov/sites/default/files/documents/public_events/first-annual-microeconomics-conference/dkarlan.pdf)]. Money-at-risk is effective but ethically fraught. Safer variants: precommitment with soft costs (a message to a friend, unlocking something), or a user-chosen donation; never a platform that profits from failure.
- **Body doubling:** evidence is thin. A 12-person VR study found faster completion with a human or AI double ([arXiv 2509.12153](https://arxiv.org/abs/2509.12153)); another small poster found no effect ([CCSC 2025](https://www.ccsc.org/centralplains/2025/talks/talk-poster16/)); a 117-adult survey is from a commercial app [V]. Position it as optional "work alongside" presence, not a clinical claim.
- **Accountability partners:** mutual, opt-in, low-bandwidth (a shared "I started" and "done" ping) beats surveillance. Share a *commitment*, not the task contents, by default.
- **Streak pitfalls:** loss aversion drives compliance but also quitting after the first break ("what-the-hell effect") [U]. Prefer "weekly consistency", a forgiving streak with freezes/repairs, or counts of total days done, which can never be lost.
- **Avoid ethically:** dark patterns (guilt-tripping copy, fake urgency), selling data on mental-health state, notification spam, paywalling basic safety (reminders, export), manipulative loss-framing for ADHD users, pet-dies mechanics, shaming social leaderboards. Provide quiet hours, a one-tap snooze for everything, and data export for free.

## (c) Unconventional UI and interaction ideas
1. **Time as physical material:** a day is a vertical column or horizon line; tasks are blocks with weight proportional to estimate; unfinished tasks visibly slide toward the evening and the user drags them (spatial memory over lists). Think Timepage/Structured timelines but with mass.
2. **Hourglass / sand "now" marker:** a Live Activity and Watch complication showing remaining focus time as draining grains, with a haptic tick at thresholds.
3. **Haptic grammar:** distinct Core Haptics patterns for start, halfway, and finish; on Watch a gentle tap to begin (like a metronome), not an alert buzz. A Taptic "heartbeat" body-double mode (a slow pulse for the duration of a session).
4. **Sound:** optional ambient soundscape that evolves with progress (one layer added per completed block), ending in a resolved chord. Silence by default.
5. **Tactile completion:** swipe/hold-to-complete with resistance (spring + haptic) so finishing feels like an act, not a checkbox. A small ritual avoids accidental taps.
6. **Garden/map/world metaphors without childishness:** a map or constellation that fills in with completed commitments; strictly abstract and adult (generative art, a daily "print" you can export). Cf. Forest and Finch, but no creature to hurt.
7. **One-thing mode:** only the next action fills the screen; everything else is blurred or hidden, with "smaller" and "later" buttons that break down or defer. Combine with an on-device breakdown (Goblin-style).
8. **Evening shutdown:** a 30-second end-of-day card: drag unfinished things to tomorrow, someday, or delete. No count of failures.
9. **Event planning mode:** an event is a countdown with working-backwards milestones ("T-minus" checklists), invitees as accountable owners per item, and a shared run-of-show timeline.

## (d) Apple platform capabilities and constraints
**Foundation Models framework**
- On-device model, ~4,096-token context shared between input and output; iOS 26.4 added `SystemLanguageModel.contextSize` and `tokenCount(for:)`; `@Generable` guided generation, tool calling, streaming, `GenerationOptions` for max tokens and sampling [S: [Gubarenko Q&A](https://antongubarenko.substack.com/p/ios-26-foundation-model-framework-f6d), [InfoQ](https://infoq.com/news/2026/03/apple-foundation-models-context)]. Needs Apple Intelligence-capable hardware with the feature enabled; always check `SystemLanguageModel.default.availability` and ship a non-AI fallback. Long input must be chunked.
- WWDC26 / iOS 27 (beta 8 June 2026; GA fall 2026): Apple's iOS 27 guide says developers can use Apple's model, cloud models "like Claude and Gemini", or any provider conforming to a language-model protocol; multimodal image input; Vision tools callable by the model; Dynamic Profiles ([Apple iOS guide](https://developer.apple.com/wwdc26/guides/ios/)) [V per search snippet]. Claims of a Private Cloud Compute model with 32K context, Python SDK, and open-sourcing are from blogs only [U] ([mer.vin](https://mer.vin/2026/06/apple-wwdc26-siri-ai-and-gemini-backed-foundation-models-on-device-and-private-cloud-compute/)). Reported regional limits: developer APIs available in EU/China but not consumer Siri features at launch [U].
- Good fits: task breakdown into steps, parsing a messy brain-dump into tasks with dates (`@Generable struct ParsedTask`), rewriting a vague task into a concrete first action, summarising the day. Poor fits: long-memory coaching, anything needing more than ~3K tokens of context.

**App Intents / Siri / Apple Intelligence**
- App Intents power Siri, Spotlight, Shortcuts, widgets, controls, Action button. A third-party WWDC26 write-up claims new Siri can only act on exposed intents and that App Intents gained richer entities and streaming/multi-turn behaviour [U: [DEV post](https://dev.to/malik_chohra/wwdc-2026-app-intents-foundation-models-and-what-rn-devs-should-ship-3o8a)]. Practical rule regardless: define `AppEntity` for Task/Event/List, `EntityQuery`/`EntityStringQuery`, intents for Add, Complete, Defer, StartFocus, WhatsNext, and `AppShortcutsProvider` phrases. Make entities Spotlight-indexable (`IndexedEntity`).
- Writing Tools: standard text views/fields get them for free (select text, Rewrite/Proofread/Summarize); use `writingToolsBehavior` to tune. Good for notes fields and event invites [U on exact API names: verify].

**Widgets, Live Activities, Controls, Watch**
- Interactive widgets (iOS 17+): `Button`/`Toggle` with an App Intent can complete a task without launching. Controls (iOS 18+): Control Center / lock screen / Action button controls built with `ControlWidget`; Apple's guidance is control for an action, widget for ongoing info, Live Activity for an event with a clear start and end ([WWDC25 334](https://developer.apple.com/videos/play/wwdc2025/334/)) [V].
- Live Activities: ~8h active, up to 12h shown on the lock screen [U]; start from foreground (or push-to-start via APNs); a Live Activity from the paired iPhone appears at the top of the Watch Smart Stack [V: [Apple Watch guide](https://support.apple.com/en-mt/guide/watch/apdecf142fb9/26/watchos/26)]. A watch app cannot start one itself (forum answer, [S](https://developer.apple.com/forums/thread/766130)). Use for focus sessions and event countdowns, not an always-on task list.
- watchOS 26: widgets and controls customizable by user; Smart Stack hints (context suggestions) [V: same WWDC25 and MacStories sources]. A relevance-based widget can surface "next action" at the right moment. A native watch app with `HKWorkoutSession`-style tricks for background runtime is discouraged for non-workout use; use `WKExtendedRuntimeSession` for focus sessions (limited modes) [U].
- Notification relay: iPhone notifications mirror to Watch when the phone is locked; to iPad/Mac via the user's Apple ID if the app is installed on those devices, local notifications are per-device (not synced), so with CloudKit each device must reschedule locally from synced data, or use remote push through CloudKit subscriptions (SwiftData's CloudKit mirroring does not itself post alerts) [U on details; test on devices]. Use `UNNotificationCategory` actions (Done, +10 min, Tomorrow) and Time Sensitive sparingly.

**CloudKit with SwiftData** (Apple's [sync guide](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) and [fatbobman rules](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)) [V/S]
- No `@Attribute(.unique)` / `#Unique`. Enforce uniqueness yourself with a UUID `id` and dedupe on launch.
- All relationships optional (to-many included) with explicit inverses; `.deny` delete rule unsupported.
- Every stored property optional or with a default value; otherwise the store may fail to load (error 134060 reported).
- Enable iCloud + CloudKit capability, background modes (remote notifications). Schema changes to the Production CloudKit schema are additive only; plan the model before first release (cannot delete or rename record types/fields). Sync is not instant and conflict resolution is last-writer-wins per field.
- Widgets/extensions need an App Group to share the store; the widget should read the same `ModelContainer` configuration.

**StoreKit 2:** auto-renewable subscriptions with free trial/intro offers, non-consumable one-time unlock, and Family Sharing are all supported; `Product`, `Transaction.currentEntitlements`, `SubscriptionStoreView` (iOS 17+) give a ready paywall. Offer both a one-time "Pro for life" and a low subscription, since task-app users resent pure subscriptions [S/U]. Small Business Program: 15% commission under $1M proceeds [U, verify current terms].

## (e) MCP: what is realistic vs hype
- Apple status: reports (Sept 2025, iOS/macOS 26.1 betas) that MCP support is being built on top of App Intents ([AppleInsider](https://appleinsider.com/articles/25/09/22/ios-26-could-get-a-major-ai-boost-with-the-model-context-protocol), [heise](https://heise.de/-10670566)); I found no source confirming it shipped by October 2026 [U]. A Dec 2025 forum thread says Apple's frameworks expose no MCP endpoints ([thread](https://developer.apple.com/forums/thread/809361)). Re-check iOS 27 notes.
- **Realistic now:** (1) *Local MCP server on Mac* (stdio, a small CLI/helper bundled with the Mac app, or a separate Swift/TypeScript package) reading the same data via CloudKit or a JSON/SQLite export, so Claude Desktop/Cursor can "list today's tasks / add task / reschedule". Mac only; needs user to install and trust it. (2) *Remote MCP server* (streamable HTTP + OAuth) in front of a backend: requires you to run a server and hold user data, which conflicts with a privacy-first CloudKit design. Only worthwhile if you add a web/webhook layer anyway. (3) *App Intents bridge:* the highest-leverage, lowest-risk work; if Apple's MCP-to-intents bridge lands, well-described intents are your MCP surface for free.
- **Consuming MCP** inside an iOS app: possible for HTTP-based servers, but few users have remote MCP servers; low value for a consumer task app.
- **Hype:** "MCP everywhere on iPhone" and agents autonomously managing your life. Security issues (prompt injection through task text, over-broad write access) mean any MCP tool that writes must be scoped (read + add only; confirm deletes).

## (f) Paid-feature candidates (ranked by user value x ethics)
Principle: free forever = capture, reminders, local data, export, Siri, basic widgets, CloudKit sync of your own data (sync costs you nothing: Apple pays).
1. **One-time "Plus" unlock (or modest subscription) for deep power features** that cost nothing to host: unlimited widgets/Controls/Watch complications themes, custom focus sounds and haptics. Ethical: clean, non-recurring.
2. **Calendar & integrations pack:** two-way EventKit/Reminders sync, ICS feeds, webhooks, Shortcuts actions, CSV/JSON/Markdown export. High value for power users; no data held.
3. **On-device AI coach:** breakdown, brain-dump parsing, weekly review. Runs on Apple's model so zero marginal cost; gate only the advanced modes. Ethical caveat: basic breakdown stays free.
4. **Learning planner ("your real estimate"):** personalised duration estimates and day-load warnings from your history. High value for planning fallacy.
5. **Event planning workspace:** shared run-of-show and checklists, per-person ownership; sharing via CloudKit Sharing. Family/group value; modest recurring subscription defensible.
6. **Accountability partner pairing:** private two-person commitments via CloudKit Sharing. Costs little; keep free for 1 partner, paid for several.
7. **History & insights** (full-year reports, time-of-day patterns). Moderate value.
8. **Custom themes / app icons / sound packs.** Low value, very ethical.
9. **Priority backup/restore & Mac MCP/automation helper** for power users.
10. **Money-on-the-line commitment contracts:** only with user-chosen charities and a clear cooling-off period; ethically risky for ADHD and anxious users. Lowest rank; likely skip.

Recommended: free core + one-time Plus (items 1, 2, 4, 8) + optional subscription "Plus Together" (items 5, 6) for group features with real ongoing value.

## (g) So what: ten most actionable findings
1. **Fix the data model first:** remove `@Attribute(.unique)` on `ToDo.item`, add `id: UUID`, make `subtasks` optional (`[SubTask]?`) with explicit inverse, add defaults to `SubTask`, add `createdAt`, `completedAt`, `estimateMinutes`, `cue` (when/where), `recurrence`, `status` enum (active/slipped/someday/done). Everything else depends on this. Persist categories (currently in-memory).
2. **Put the store in an App Group** and design the CloudKit schema once (production schema is additive-only).
3. **Show a tiny finite "Today" (3-5 items) with a one-thing mode**; push the rest behind a deliberate "Later" door. This answers overwhelm and ADHD initiation.
4. **Replace red overdue with "slipped" and a nightly shutdown/reset**; auto-move stale tasks to "Reconsider". No guilt counters.
5. **Add an optional if-then cue to every task** (time, place, after-event). Best-evidenced accountability technique [V].
6. **Learn the user's estimate multiplier** for planning-fallacy correction; needs no AI.
7. **Make time physical:** sand/arc Live Activity for focus sessions, Smart Stack hints and a Watch haptic grammar. Live Activities must start from the phone; Watch gets them via Smart Stack.
8. **Ship App Intents early** (Add, Complete, Defer, WhatsNext, StartFocus; entities with Spotlight indexing): they power Siri, Shortcuts, widgets, Controls, Action button and any future MCP bridge.
9. **Use Foundation Models for narrow, structured jobs** (`@Generable` brain-dump parsing, task breakdown), mind the ~4K token window, always check availability and provide a non-AI fallback.
10. **Monetise ethically:** free core with export; one-time Plus plus optional group subscription; no streak-loss mechanics, no money-at-risk by default. MCP: defer; expose a read/add-only local Mac server later, after intents are solid.

Open verification items: Apple MCP shipping status; iOS 27 Foundation Models details (context size, PCC); Live Activity duration limits; notification relay behaviour for local notifications across devices; Small Business Program terms; Tiimo's award claim.
