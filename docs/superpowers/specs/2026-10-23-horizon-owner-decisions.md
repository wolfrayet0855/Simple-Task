# Owner decisions (design.md section 12)

Owner delegated 1-5, supplied 6, and 7 comes from the Xcode project. Items marked (call) are the builder's and open to change.

1. App name (call): **Waymark**, a waymark is a trail marker, which fits landmarks and trails. Not yet checked for App Store availability or trademark. Display name changes at the end of the slice; bundle id stays `beta.SimpleTask`.
2. Plus price (call): one-time **$14.99**, Family Sharing **on** (cannot be undone per product).
3. Shared pledges (call): **receipts only** for v1; no live CKShare.
4. Sound pack: **cut** (owner).
5. Reminders by default (call): iPhone, Mac and Watch on; iPad opt-in.
6. Universal-link domain (owner): `task.shapehaveninnovations.com`. Receipts link to `https://task.shapehaveninnovations.com/p/<id>`. Owner must host an `apple-app-site-association` file there.
7. IDs: Team `P9Z5QB8965` (from the existing project). App Group `group.beta.SimpleTask`. CloudKit container `iCloud.beta.SimpleTask` (needs creating in the developer portal; `Features.cloudSync` stays false until then).
8. Minimum OS: **iOS 26.0** (confirmed in Xcode).

## Builder calls made while implementing the first slice

- Swift 5 language mode kept (legacy SwiftData code); revisit Swift 6 when Legacy is deleted.
- `SimpleTaskKit` is a static library so App Intents metadata merges into the app and widget.
- Colour tokens live in code, not the asset catalog. UIKit haptic generators stand in for the Core Haptics grammar.
- Drag-to-band rescheduling is deferred (it fights hold-to-complete). Context menu and VoiceOver actions cover Tomorrow, Next week and Shelf.
- Notification permission is still requested at launch (inherited behaviour). Better: ask when the first reminder is set.
- Tapping a card opens the old detail form until the new task sheet ships.

## Not verified in the simulator (needs your device)

Hold-to-complete feel and haptics, the Undo toast, running "Finish task" from Shortcuts, tapping Done on the home-screen widget, iPad and Mac layouts, and a real upgrade from a store created by the shipped 1.2 app.
