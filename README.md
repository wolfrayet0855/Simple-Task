# Waymark (formerly Simple Task)

A task, event and accountability app built around **Horizon**: a landscape of time instead of a list.

- **Distance is height.** Today's work (at most five) is near and large. Later work climbs toward the horizon, smaller and fainter.
- **Size is weight.** Tasks are small, medium or large.
- **Hold to finish.** Hold a card for 0.55 s and it drops into the **Cairn**, a pile of stones that only grows. Undo is there for five seconds.
- **No red.** Overdue work turns dusk grey ("slipped") and moves quietly to the Shelf after a week.
- **Capture in one line.** `dinner w/ Sam fri 7pm #home @Sam` sets the time, tag and a pledge. `^Party` joins a trail.
- **Siri, Shortcuts and a widget.** "Finish *task* in Waymark", "What's next in Waymark", and a Next widget with a Done button.

Design and plan live in `docs/redesign/` (charter, research, Apple-docs verification, design) and `docs/superpowers/` (plan, owner decisions).

## Build and test

Requires Xcode 26 and the iOS 26 simulator. The Xcode project is generated from `project.yml` ([XcodeGen](https://github.com/yonaskolb/XcodeGen)):

```bash
xcodegen generate
xcodebuild test -scheme "Simple Task" -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

Debug builds accept `-seedDemo` (fill an empty store with sample tasks) and `-skipPermission` (skip the notification prompt) as launch arguments.

## Layout

- `SimpleTaskKit/`: models (SwiftData, CloudKit-safe), migration, store, notifications, intents, and the pure Horizon logic. Built as a static library so App Intents metadata reaches the app and the widget.
- `Simple Task/`: the app, `Horizon/` views, and `Legacy/` screens kept behind a debug menu until the task sheet lands.
- `SimpleTaskWidgets/`: the Next widget.
- `Simple TaskTests/`: unit tests.

## License

MIT, see `Simple Task/MIT License.md`.
