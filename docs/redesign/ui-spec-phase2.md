# Waymark UI spec, Phase 2

Design direction for the second pass on the iPhone UI. Inputs: `design.md` (concept "Horizon"), the first-slice code in `Simple Task/Horizon/` and `SimpleTaskKit/Horizon/Tokens.swift`, and the simulator screenshot from 2026-10-24 06:34 (iPhone 17 Pro, light mode, two tasks in hand, nothing else). Target: iOS 26 SDK and APIs only. Draft v1, 2026-10-24.

This spec covers four things:

- **A.** A revised Horizon screen.
- **B.** The Task sheet that replaces the legacy `DetailView`.
- **C.** First-run onboarding.
- **D.** A recovery screen for when moving the store fails.

Part 0 says what is wrong today. Part E lists the build order and the tests.

---

## 0. Critique of the current build

The first slice works: you can capture, hold to finish and undo. But the screen in the screenshot reads as **a settings table with four empty rows above a to-do list**. You can't see the Horizon idea in it. Specific problems, worst first:

1. **The field is 70% empty and has no depth.** Four equal-width hairlines at almost equal spacing (0.08/0.16/0.16/0.14 of the height) look like table separators. Nothing converges, nothing recedes, and there's no ground and no horizon line. The first-five-seconds test in `design.md` §11 ("depth, perspective, landmarks") fails. Empty bands take the same space as full ones, so with an ordinary small task load the screen is mostly blank sky.
2. **The band labels are in the wrong place and hard to read.** Each label is drawn at the *bottom-trailing* corner of its band, just above the next divider, so the eye reads it as the header of the section *below* it. In the screenshot, "TOMORROW" sits directly above today's cards. The labels are a fixed 9 pt that ignores Dynamic Type, and they are drawn at 28% ink, roughly 1.9:1 contrast, well under 4.5:1. In Hand, the most important band, has no label at all.
3. **There's no sense of time.** No date, no "now", no position in the day. At 06:34 the sky shows the full-day palette, because `duskAmount` treats 06:30 onward as day and has no dawn state. The gradient goes from `#E6EDF6` to `#FBF8F3`, which is close to invisible on device, and it ends at mid-screen.
4. **The cards are flat paper on paper.** The `ground` fill sits on a `ground` background with a 7% shadow. The ember card is marked only by a 1.5 pt orange outline, which is weak for "the single next action". The grey dot on other cards carries no meaning. The "Hello" card has about 40 pt of dead space under a one-line title, because content is top-aligned in a fixed-height card. A single non-ember card sits alone in a two-column grid and leaves a ragged half-row.
5. **The "…" menu on every card** competes with the title and is a second, hidden way to do things the sheet should do. It also invites a long-press context menu, which would collide with hold-to-finish.
6. **The Cairn reads "0  today 0".** With zero stones it draws no stones, a bold orphan "0", then "today 0" at 55% ink (about 4.0:1, which fails). It looks like a bug, not a promise.
7. **A debug ladybug is in the top-right corner** of every DEBUG build and every screenshot taken from one. It's the only control in the header, so it looks like a feature.
8. **There's no onboarding and no real empty state.** A new user meets hairlines and a text field. Nothing teaches hold-to-finish, the app's signature gesture and one that can't be discovered. Notification permission is still requested at launch, with no context.
9. **Far chips shrink text below legibility.** `FarChip` applies `scaleEffect(s)` with `s` down to 0.45, which turns 13 pt footnote text into about 6 pt glyphs. The Dynamic Type cap of `.xLarge` on `BandField` makes this worse for people who need large text.
10. **Several tokens fail as text colours.** They're fine as fills, but the code uses them for text:

| Token (light) | On `ground` #FBF8F3 | Used as text in |
|---|---|---|
| `ember` #D9712B | ≈ 3.1:1 | Undo button, capture chip |
| `witness` #2F8F8A | ≈ 3.6:1 | pledge chip |
| `slipped` #8A93A6 | ≈ 2.9:1 | slipped capsules, Shelf button |
| `slipped` dark #6E7689 on #17150F | ≈ 4.0:1 | same |

`design.md` §2 says every token reaches 4.5:1. They don't, so this spec adds separate text variants (§A.1).

11. **The capture bar is a generic pill**, with a low-contrast placeholder and a grey disabled arrow. It's fine to use but has no character. The parser also keeps filler such as "I need to"; that's out of scope here, so it's noted for the parser backlog.
12. **Tapping a card opens the legacy Form** (`DetailView`). It uses blue toggles, a "Category" picker and a "Mark as Complete" switch. Each of these contradicts Horizon, and the switch bypasses the Cairn and Undo entirely.

What is good and stays: the restrained palette, hold-to-finish with its ring, the Undo toast, never using red, the capture parse chips, the VoiceOver custom actions, and the Reduce Motion fallback to a tap.

---

## A. Horizon, revised

### A.1 Tokens

All tokens stay in code (`SimpleTaskKit/Horizon/Tokens.swift`), per the builder's earlier call. New and changed values are listed here. Contrast figures are computed against `ground` and must be enforced by a unit test (§E).

**Colour.** For each token: light value / dark value, then what it's for.

**Existing tokens, kept as fills:**

- `ink`: #1C1E22 / #EDEBE6. Primary text.
- `ground`: #FBF8F3 / #17150F. Foreground plane and sheet background.
- `ember`: #D9712B / #F29A55. Ember fill, rail, ring and glow. Not for text in light mode.
- `landmark`: #4B4FA8 / #9A9DF2. Landmarks and trails. Fine as text (6.6:1).
- `witness`: #2F8F8A / #5CC2BC. Lantern fill.
- `slipped`: #8A93A6 / #6E7689. Slipped fills and contours.
- `stone`: #B9B2A6 / #4F493F. Cairn stones.

**New text tokens:**

- `inkSecondary`: #5C5F68 / #A8A49B. Meta text and labels (about 6.0:1 light, 7.3:1 dark). Replaces `ink.opacity(0.55–0.6)`.
- `inkTertiary`: #6E717A / #8C887F. Placeholders and timestamps (about 4.6:1 light, 5.1:1 dark). The floor; nothing lighter is used for text.
- `emberText`: #A8501A / #F29A55. Ember-coloured text such as "NEXT" and "Undo" (about 5.2:1).
- `witnessText`: #22706C / #5CC2BC. Pledge text (about 5.4:1).
- `slippedText`: #5E6678 / #9AA2B4. Slipped labels (about 5.4:1 light, 7:1 dark).

**New surface tokens:**

- `card`: #FFFDF9 / #221F18. Card surface. It's lighter than `ground` in light mode and lifted in dark mode.
- `cardEdge`: #1C1E22 at 8% / #FFFFFF at 7%. Card hairline.
- `contour`: #1C1E22 at 10% / #EDEBE6 at 10%. Band contours and path rails.
- `threshold`: #F3EEE5 / #1E1B14. The near ground under In Hand, slightly darker than `ground`.

**Tags:**

| Token | Light | Dark |
|---|---|---|
| `tag.1` | #B5654A | #D98E73 |
| `tag.2` | #A07A2C | #D1AE5E |
| `tag.3` | #5F8A4E | #8DBB7B |
| `tag.4` | #3E8A85 | #6EC0BA |
| `tag.5` | #4F6FA8 | #8DA8DD |
| `tag.6` | #7A5DA6 | #B19ADB |
| `tag.7` | #A3577F | #D58BB2 |
| `tag.8` | #6F6A62 | #A9A398 |

Tags are always shown as a dot or notch next to text, never as text colour, so the requirement is 3:1 against `card` (non-text UI). All eight meet it.

**Increase Contrast** (`@Environment(\.colorSchemeContrast) == .increased`):

- `inkSecondary` becomes `ink`, and `inkTertiary` becomes `inkSecondary`.
- `contour` goes to 22%.
- `cardEdge` goes to 20%.
- The haze (§A.3) and the sun glow are switched off.

**Sky keyframes.** These replace `skyDay`/`skyDusk`. Each keyframe has a top colour and a horizon colour, and all values are light / dark:

| Keyframe | Local hour anchor | Top | Horizon glow |
|---|---|---|---|
| night | 21:00 → 04:30 | #CBD3E6 / #070B14 | #EDE9F0 / #141A2A |
| dawn | 06:00 | #DCE3F0 / #111A2C | #F8DCCB / #3A2A2E |
| day | 08:00 → 16:30 | #D6E6F7 / #0E1626 | #F3F6F8 / #1B2536 |
| golden | 18:00 | #E4E2EE / #15162A | #F7E1C4 / #3A2B22 |
| dusk | 19:30 | #D9D3E6 / #120F22 | #F2D6D0 / #2E1E2E |

Interpolate linearly between neighbouring anchors with `Color.mix(with:by:in: .perceptual)`. Put a pure function in Kit:

```swift
public enum Sky {
    /// t = local fractional hour. Returns keyframe pair + blend, unit-testable without SwiftUI.
    public static func keyframes(at date: Date, calendar: Calendar) -> (from: SkyKey, to: SkyKey, t: Double)
    public static func sunPosition(at date: Date, calendar: Calendar) -> Double? // 0…1 across 06:00–20:00, nil at night
}
```

When In Hand is empty, the sky keeps its existing −30% saturation rule.

**Spacing and radius:**

```swift
public enum Space { static let xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 28.0 }
public enum Radius { static let card = 18.0, group = 20.0, chip = 10.0 }  // all .continuous
```

**Type.** These extend `design.md` §2. Use Dynamic Type styles only; `.system(size:)` is not allowed anywhere.

| Token | Style |
|---|---|
| `type.date` | `.title3`, `.fontDesign(.serif)`, semibold |
| `type.wayfinding` | `.subheadline`, color `inkSecondary` |
| `type.bandLabel` | `.caption`, semibold, `tracking(0.6)`, sentence case (not ALL CAPS), `inkSecondary` |
| `type.eyebrow` | `.caption2`, bold, `tracking(0.8)`, uppercase. Used only for "NEXT" |
| `type.task.near` | ember: `.title3.weight(.semibold)`; others: `.body.weight(.medium)` |
| `type.task.far` | by depth: Tomorrow `.subheadline`, Week `.footnote`, Month `.caption`, Beyond `.caption2` |
| `type.meta` | `.caption`, `.monospacedDigit()`, `inkSecondary` |

**Motion.** These are additions to `Motion`. Every one of them becomes `.easeInOut(duration: 0.2)` opacity-only under Reduce Motion.

| Token | Value | Use |
|---|---|---|
| `reflow` | `.spring(response: 0.38, dampingFraction: 0.86)` | Bands resizing and chips moving after a change |
| `rise` | `reflow` with insertion `.offset(y: 14)` plus opacity | A new item appearing in a far band |
| `sink` | 0.45 s custom `Transition` (§A.6) | A completed card dropping into the Cairn |
| `skyShift` | `.easeInOut(duration: 1.2)` (`drift`) | Sky colour after a minute tick or a calm change |
| `page` | `.smooth(duration: 0.35)` with `.push(from: .trailing)` | Onboarding steps |

### A.2 Screen anatomy (iPhone portrait)

```
┌───────────────────────────────────────┐
│ Saturday 24 October          (▤3) (⚙) │ Header 52pt: date + wayfinding, Shelf, Settings
│ ▲ Sam's 40th · 52 days                │
│ ──────────── ☼ ───────────────────────│ horizon line, sun disc on it
│        ▲Sam's 40th   ▲Launch    +2    │ Beyond (landmarks only)
│          ╲        ·        ╱          │ path rails converge to vanishing point
│   Month   · renew passport  12 Nov    │ contour inset grows with depth
│         ╲ · book venue  5 Nov ╱       │
│  Week   ▫ draft toast Tue  ▫ order …  │
│       ╲                         ╱     │
│ Tomorrow ▭ call caterer 10:00  ▭ gym  │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ threshold (ground changes tone)
│ Today  ●●●○○                          │ In Hand header: count vs cap of 5
│ ┃ NEXT                                │
│ ┃ Send deck to Priya                  │ ember card, full width, lit
│ ┃ 2:00 PM · in 1h 26m  ● work  ◉Priya │
│ ┌────────────────┐ ┌────────────────┐ │
│ │ Pay rent     ∘∘│ │ Groceries    ∘ │ │ weight pebbles
│ └────────────────┘ └────────────────┘ │
│ ◌ Reply to landlord · slipped 2d      │
│ ▪▪▪▪▪▫ 1,284 stones · 6 today         │ Cairn
│ ( Drop a thought…                 ⬆ ) │ glass capsule, safeAreaInset
└───────────────────────────────────────┘
```

**SwiftUI structure.** No custom `Layout` is needed. Drawing goes in `Canvas`, and band heights come from a pure function.

```swift
struct HorizonView: View {
  var body: some View {
    TimelineView(.everyMinute) { tl in
      let model = …                               // unchanged HorizonModel.build
      ZStack {
        SkyBackground(date: tl.date, calm: model.isCalm, horizonY: …, thresholdY: …) // Canvas + gradient
        VStack(spacing: 0) {
          HorizonHeader(date: tl.date, wayfinding: model.wayfinding)
          if dynamicTypeSize.isAccessibilitySize { ItineraryField(model) }   // §A.8
          else { PerspectiveField(model, heights: BandHeights.allocate(…)) }
          InHandSection(model)                                               // ScrollView, sized to content
          SlippedRow(model)
          CairnStrip(total:today:)
        }
      }
      .safeAreaInset(edge: .bottom) { CaptureBar(…) }
      .overlay(alignment: .bottom) { UndoToast(…) }
    }
  }
}
```

**Vertical budget.** `H` is the safe-area height minus the header and the capture bar.

- **In Hand** takes its content height, clamped between `0.34·H` and `0.52·H`. Past the clamp it scrolls inside its own `ScrollView`.
- **Slipped** takes 36 pt if it has items, otherwise 0. **Cairn** takes 40 pt.
- **The perspective field** takes the rest, split by `BandHeights.allocate(total:counts:)`, a pure Kit function with unit tests:
  - Base weights by perspective foreshortening: Tomorrow 1.0, Week 0.8, Month 0.6, Beyond 0.45.
  - Minimums: an empty band gets 32 pt (label only). A populated band gets `rows · chipHeight(depth) + 12`, where `rows = ceil(count / lanes)`.
  - Leftover space is shared in proportion to the weights. Bands never shrink below their minimum. If the minimums don't fit, the field scrolls; this only happens at large text sizes, which normally use the Itinerary mode in §A.8.

This is the main fix for the empty screen: **empty bands collapse and full bands breathe.**

### A.3 Sky, horizon and path (depth)

`SkyBackground` draws in a single `Canvas`, plus a gradient view underneath. Everything here is decorative and has `accessibilityHidden(true)`.

1. **Gradient.** A `LinearGradient` with stops: sky top at 0, horizon glow at `horizonY`, `ground` at `thresholdY`, and `threshold` from `thresholdY + 1` to the bottom. That last step is a hard tone change, so the near ground reads as a different surface.
2. **Haze.** The far bands sit in the sky-to-ground blend, so far chips naturally have less contrast against their background. Chip *text* never goes below `inkTertiary`.
3. **Horizon line.** A 1 pt `contour` line across the full width at the bottom of the Beyond band, at 1.5× the normal contour opacity. It is the strongest line on the screen after the threshold.
4. **Sun or moon.** A 14 pt disc sits on the horizon line, with x = `16 + sunPosition·(W − 32)`. It's filled with `ember` at 70%, plus a 40 pt radial glow at 18% opacity. At night it becomes a 10 pt `stone`-coloured moon at the trailing third. The position updates each minute, with no animation (the per-minute step is invisible). With Increase Contrast on, there's no glow.
5. **Path rails.** These are the depth cue and the brand: a waymark is a trail marker. Draw two dashed lines (`[2, 6]`, 1 pt, `contour`) from `(16, thresholdY)` and `(W−16, thresholdY)` to `(W/2 ∓ 36, horizonY)`.
   - **Contours.** Each band floor is a `contour` hairline that spans only the path width at that height: `inset(y) = lerp(16, W/2 − 36, depthAt(y))`.
   - **Chip lanes.** Far-band chips are laid out inside the path width at their band's depth. Pass `horizontalInset` to `BandField`, which computes `laneWidth` from `pathWidth` rather than from `geo.size.width`.
   - **Effect.** The field visibly narrows toward the horizon, which is the perspective the screenshot lacks.
6. **Calm state.** The sky's −30% saturation and the dimmed sun animate with `skyShift`.

Reduce Transparency changes nothing here, because there is no material in the field. With Reduce Motion, sky changes snap instead of animating.

### A.4 Header: date and wayfinding, no greeting

The header is an `HStack` with `minHeight: 52` and horizontal padding of 20.

- **Leading:** a `VStack(alignment: .leading, spacing: 2)`.
  - **Line 1:** `Text(date, format: .dateTime.weekday(.wide).day().month(.wide))` in `type.date`, colour `ink`.
  - **Line 2:** a wayfinding line in `type.wayfinding`, with one line limit and tail truncation. Show the first of these that applies:
    1. The next landmark: `▲ Sam's 40th · 52 days` (the triangle is a `landmark`-tinted SF Symbol, `triangle.fill`, at `.caption`).
    2. The next dated task beyond today: `Next on the path: Call caterer, tomorrow`.
    3. `Week 43`.

   Never "Good morning", and never "You have N tasks".
- **Trailing:** two 44×44 circular buttons using `.buttonStyle(.glass)`:
  - **Shelf** (`tray`). It shows the shelf count as a `.caption2` badge overlay when the count is above 0, and opens `ShelfSheet`. This replaces the Shelf capsule that sat in the slipped row.
  - **Settings** (`gearshape`). It opens Settings. In DEBUG builds, Settings has a "Developer" section with the legacy links, the demo seed and an onboarding reset.
  - **Remove the ladybug overlay.**
- **Accessibility:** The leading block uses `.accessibilityElement(children: .combine)` and `.accessibilityAddTraits(.isHeader)`. For example: "Saturday 24 October. Next landmark, Sam's 40th, in 52 days." The buttons are labelled "Shelf, 3 items" and "Settings".

### A.5 Bands and far chips

**Band label.** Each label goes at the **top-leading** corner of its band, inside the path, in `type.bandLabel`, followed by a quiet range so the label carries information:

- `Tomorrow · Sun`
- `This week · to Sat 31`
- `This month · to 24 Nov`
- `Beyond`

Labels show even when a band is empty. The vertical order and the converging path remove any ambiguity about which band a label belongs to. In Hand gets the label `Today` (§A.6).

**FarChip** is rewritten. **Remove `scaleEffect`.** Depth is carried by the font style (`type.task.far`), the chip height and the haze, never by shrinking glyphs.

| Band | Chip height | Horizontal padding | Fill | Stroke |
|---|---|---|---|---|
| Tomorrow | 34 | 12 | `card` 92% | `cardEdge` |
| Week | 30 | 10 | `card` 80% | `cardEdge` |
| Month | 26 | 9 | `card` 64% | none |
| Beyond (landmarks) | 28 | 10 | `landmark` 12% | `landmark` 30% |

- **Content:** a `HStack(spacing: 6)` containing the tag dot (6 pt), the title (`ink` for Tomorrow and Week, `inkSecondary` for Month), then `Spacer`, then a date stamp in `type.meta`. The stamp is the time for Tomorrow, the weekday for Week, and "12 Nov" for Month. The title truncates first. Use `.layoutPriority(1)` on the date stamp so the date always shows.
- **Dynamic Type:** cap at `...DynamicTypeSize.xxxLarge` here, instead of `.xLarge`. Accessibility sizes switch to Itinerary mode (§A.8).
- **Tap:** opens the Task sheet. The 44 pt tap target is extended with `.contentShape(Rectangle().inset(by: -6))`.
- **Overflow `+n`:** a 28 pt `stone` circle with a `.caption.monospacedDigit()` count, at the trailing end of the band's last row. Tapping it opens the Shelf-style list sheet filtered to that band (`BandListSheet`). This replaces the fan-out from `design.md`, which is deferred.

### A.6 In Hand cards

**Section header:** `Today` in `type.bandLabel`, followed by capacity pebbles: five 7 pt circles, filled with `ink` for each item held and stroked with `contour` for each empty slot. This makes "finite" visible. The accessibility label is "Today, 3 of 5 in hand."

**TaskCard (non-ember):**

- **Shape:** `RoundedRectangle(cornerRadius: Radius.card, style: .continuous)`.
- **Fill:** `card`. Add a 1 pt top-edge highlight: `strokeBorder(LinearGradient([.white.opacity(0.7), .clear], top→center))` in light mode only.
- **Shadows:** two stacked shadows.
  - Light mode: contact `black 6%, r 2, y 1` and ambient `black 8%, r 16, y 8`.
  - Dark mode: one shadow, `black 45%, r 12, y 6`.
- **Border:** `cardEdge`, 1 pt.
- **Content:** a `VStack(alignment: .leading, spacing: 4)`, **centred vertically** (`frame(maxHeight: .infinity, alignment: .leading)` inside `minHeight`).
  - **Title:** `type.task.near` with a line limit of 3.
  - **Meta row:** `type.meta`. It shows the time when dated (for example "2:00 PM"), or "40m ago" in `inkSecondary` if the time has passed today; slipped only begins tomorrow. It also shows the tag dot plus tag name, and a witness lantern (an 8 pt `witness` circle plus initials) if there's a pledge.
  - **No grey dot. No "…" menu.**
- **Weight:** `minHeight` S 56, M 72, L 96 (unchanged). Add weight pebbles in the bottom-trailing corner: 1, 2 or 3 `stone` circles of 5 pt, 3 pt apart, with `accessibilityHidden`. The weight is read out in the label instead.
- **Padding:** 14 horizontal, 12 vertical.

**Ember card (the next action):**

- **Width:** always full width, and always first.
- **Fill:** `card.mix(with: ember, by: 0.06)`.
- **Leading rail:** a 4 pt-wide `ember` capsule inset 12 pt vertically, with content padding of 18 on the leading side.
- **Glow:** a third shadow, `ember 22%, r 20, y 6`. Under Increase Contrast, replace it with a 1.5 pt `ember` border.
- **Eyebrow:** `NEXT` in `type.eyebrow`, `emberText`, above the title.
- **Title:** `.title3.weight(.semibold)`.
- **Meta:** "2:00 PM · in 1h 26m" (`type.countdown`, monospaced digits, `Text(timerInterval:)` not required because the per-minute timeline is enough), plus the tag and the lantern.

**Grid:**

- **Up to `.xxxLarge`:** use `Grid(horizontalSpacing: 12, verticalSpacing: 12)` with two columns. If the number of non-ember cards is odd, the last card spans both columns (`.gridCellColumns(2)`), so there are no ragged half-rows.
- **Accessibility sizes:** one column.
- **Row height:** cards in a row share a height through `Grid`'s natural row sizing. Heavier weight wins.

**Hold to finish (existing modifier, refined):**

- While pressing: the ring trims as it does now, the card fill blends toward `ember` from 0 to 10% over `Motion.hold`, and the card scales to 0.98.
- On completion, the card leaves with the `sink` transition:

```swift
struct SinkTransition: Transition {
  func body(content: Content, phase: TransitionPhase) -> some View {
    content.scaleEffect(phase.isIdentity ? 1 : 0.3, anchor: .bottom)
           .offset(y: phase.isIdentity ? 0 : 120)
           .opacity(phase.isIdentity ? 1 : 0)
  }
}
```

- At the same moment, the newest Cairn stone pops in, scaling from 0.6 to 1 with `settle` and an ember fill that fades to `stone` over 1.5 s.
- Under Reduce Motion, the card fades out over 0.2 s and the stone appears without scaling.

**Card actions:**

- **Tap** opens the Task sheet. All rescheduling lives there (§B, "Distance").
- **VoiceOver actions are unchanged:** Complete, Tomorrow, Shelf and Open.
- **No `contextMenu` on cards.** It would fight the 0.55 s hold.
- **Accessibility label:** "Next. Send deck to Priya. 2:00 PM, in 1 hour 26 minutes. Tag work. Promised to Priya. Medium." Hint: "Hold to finish. Double-tap to open."

### A.7 Empty states

| State | Condition | What shows |
|---|---|---|
| **First light** | No open tasks, Cairn total 0 | The full field with the path and sky, all bands collapsed. In Hand shows a `.title2` serif "Start with one thing." and `inkSecondary` body text: "Type it below. Add a day like *fri* and it walks up the path." Three example chips (glass, `.caption`): `call mum sun 5pm`, `pay rent on the 1st`, `dentist in 3 weeks`. Tapping a chip **fills** the capture field without submitting it, and focuses the field. |
| **Today's clear** | In Hand is empty but future tasks exist | "Today's clear." The subline names the nearest task: "Next on the path: Call caterer · tomorrow 10:00", with a `.bordered` "Bring it to today" button tinted `ember` (it runs the existing `.today` move). |
| **Clear skies** | No open tasks and Cairn > 0 | "Clear skies." and "1,284 stones laid." The sky desaturates (calm). No button. |
| **Empty band** | A band has no items | It collapses to 32 pt and shows only its label. No ghost text. |
| **Empty Cairn** | Total is 0 | A single dashed-outline stone (14×10, `contour`) and the text "Your cairn starts with the first thing you finish." in `.footnote`, `inkSecondary`. Never "0". |
| **Cairn** | Total > 0 | `1,284 stones · 6 today` (`.footnote.monospacedDigit()`, with the number in `ink` semibold and the words in `inkSecondary`). Hide "· N today" when N is 0. |

Each empty state is a single combined accessibility element. The example chips are separate buttons labelled "Example: call mum Sunday 5 PM. Fills the capture field."

### A.8 Accessibility of the field

- **Reading order.** VoiceOver reads in this order: header, Today (In Hand), Tomorrow, This week, This month, Beyond, Slipped, Cairn, then capture. Use `.accessibilitySortPriority` with values 100, 90, 80, and so on. Today comes before the far field even though it is lower on screen.
- **Band containers.** Each band is `.accessibilityElement(children: .contain)` with a label such as "Tomorrow, 2 tasks". An empty band reads "Tomorrow, nothing yet."
- **Rotors.** Add `.accessibilityRotor("Bands")` to jump between band headers, and `.accessibilityRotor("Slipped")`.
- **Itinerary mode** (`dynamicTypeSize.isAccessibilitySize`). The perspective field gives way to a single `ScrollView` of sections: Today, then Tomorrow, then Week, and so on. Each section has full-size rows (`TaskCard` in one column, far tasks as compact cards with no scaling), and the path and contours are hidden. The sky and header stay, so the identity holds. This is an honest alternative and not a squeezed field. The capture bar keeps its `...accessibility3` cap.
- **Reduce Motion.** Every transition becomes opacity over 0.2 s, and the sky snaps. Hold-to-finish becomes a tap plus Undo (already built).
- **Hit targets.** Every tappable element is at least 44×44 pt, including the far chips (via `contentShape`), the overflow stones and the header buttons.

### A.9 Capture bar and toast

- **Capture bar:**
  - Place it with `.safeAreaInset(edge: .bottom)`, so In Hand scrolls clear of it.
  - Shape: `.glassEffect(.regular.interactive(), in: .capsule)`, with `minHeight: 52`, padding of 18 horizontal and 12 vertical, and 12 pt from the screen edges.
  - Placeholder: `TextField(text:prompt:)` with `Text("Drop a thought…").foregroundStyle(inkTertiary)`.
  - **Submit button:** a 34 pt circle. When valid, it's filled with `ember` and shows a white `arrow.up` at `.body.bold()`. When empty, it's hidden (`opacity 0`, still in the layout) instead of greyed out.
  - **Parse chips:** keep them, styled as small glass capsules (`.glassEffect(.regular, in: .capsule)`), with chip text in `emberText`, `witnessText` and `landmark`.
  - **Under Reduce Transparency:** use a solid `card` fill and a `cardEdge` stroke.
- **Undo toast:**
  - A glass capsule placed 12 pt above the capture bar, reading "Stone #1,285 laid" and an "Undo" button in `emberText` semibold (44 pt tall).
  - Keep the 5 s window, or 15 s when VoiceOver is running, and keep the announcement.
  - The toast appears with `.move(edge: .bottom).combined(with: .opacity)` and `settle` (opacity only under Reduce Motion).

---

## B. Task sheet (replaces `DetailView`)

### B.1 Presentation

```swift
.sheet(item: $editing) { todo in
  TaskSheet(task: todo, onFinish: { id in finishFromSheet(id) })
    .presentationDetents([.medium, .large], selection: $detent)
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(nil)                 // system default for iOS 26
}
```

- **Detents.** At `.medium`, iOS 26 renders the sheet with its default glass background. Keep that, because it lets the Horizon show through at the edges and keeps the sheet tied to the field. At `.large` the sheet becomes opaque by default.
- **Content.** Use a `ScrollView` with a `VStack(alignment: .leading, spacing: 24)` and 20 pt horizontal padding. **Don't use a `Form`.** The rows in §B.2 are custom groups built on `card` rounded rectangles (`Radius.group`).
- **Toolbar** (inside a `NavigationStack` with an inline, empty title):
  - Leading: `Button(role: .close) { dismiss() }`.
  - Trailing: `Menu { … } label: { Image(systemName: "ellipsis") }`, containing "Duplicate" and a divider, then `Button("Delete task", role: .destructive)`.
- **Bottom:** use `.safeAreaInset(edge: .bottom)` for the Finish bar (§B.4).

### B.2 Content, top to bottom

The medium detent must show items 1 to 4 without scrolling at the default text size on iPhone SE (3rd generation).

1. **Title.** `TextField("Task", text: $task.item, axis: .vertical)` in `.title2.weight(.semibold)` with a line limit of 1 to 4. `submitLabel(.done)` dismisses focus. If the title is empty when the sheet closes, the previous title is restored (it's captured in `@State` on appear).
2. **Where it sits (Distance).** This is the signature control, a horizontal mini-path of six stops: `Today · Tomorrow · Week · Month · Beyond · Shelf`.
   - **Look:** 36 pt tall stops in an `HStack` inside a horizontal `ScrollView` (the scroll matters for accessibility sizes). The current stop is an `ember` capsule with white text. The others are plain, in `inkSecondary` at `.subheadline`. They're joined by a dashed `contour` line drawn behind them.
   - **Tap** to move the task. Each move reuses the existing `reschedule` rules and adds two more:
     - **Today:** keep the time if it's still ahead, otherwise make the task undated In Hand.
     - **Tomorrow:** 9:00.
     - **Week:** next Monday, 9:00.
     - **Month:** the same weekday plus 14 days, 9:00.
     - **Beyond:** opens the date picker in row 3.
     - **Shelf:** undated and shelved.
   - **Motion:** the selected capsule slides with `matchedGeometryEffect` and `reflow`, and plays the capture haptic.
   - **VoiceOver:** a single element, "Where it sits, Tomorrow", using `accessibilityAdjustableAction` (swipe up or down moves one stop) and `.accessibilityValue`.
   - **Ownership:** this control replaces the card "…" menu.
3. **When.** One group of rows. Each row has a minimum height of 48, a leading 28 pt SF Symbol in `inkSecondary`, a `.body` label, and a trailing `.body` value in `inkSecondary`. Tapping a row expands its editor inline with `withAnimation(reflow)`, the same idea as a `DisclosureGroup` but with a custom style.
   - **Date** (`calendar`). The editor is `DatePicker(selection: $task.dueDate, displayedComponents: .date).datePickerStyle(.graphical)`, tinted `ember`. The row value reads "Tomorrow, Sun 25 Oct", or "No date" when undated. A "Clear date" text button inside the editor sets `isDated = false`.
   - **Time** (`clock`). A `Toggle` whose off state means `isAllDay = true`. When it's on, show `DatePicker(…, displayedComponents: .hourAndMinute).datePickerStyle(.compact)` inline in the same row. Toggles are tinted `ember`, not blue.
   - **Remind** (`bell`). A `Toggle` bound to `reminderIsOn`. When it's on, show offset chips: `At time · 10 min before · 1 hr before · Morning of (9:00) · Custom…`. Custom shows a compact `DatePicker` bound to `reminderDate`. Each chip sets `reminderDate` from `dueDate`. Turning it on goes through the permission flow in §B.5.
   - **Repeat** (`arrow.trianglehead.2.clockwise`). A `Menu` picker with these options, written to `recurrenceRaw`:

     | Option | `recurrenceRaw` |
     |---|---|
     | Never | `nil` |
     | Every day | `FREQ=DAILY` |
     | Weekdays | `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR` |
     | Every week | `FREQ=WEEKLY` |
     | Every 2 weeks | `FREQ=WEEKLY;INTERVAL=2` |
     | Every month | `FREQ=MONTHLY` |
     | Every year | `FREQ=YEARLY` |

     A caption under the row previews the next occurrence: "Next: Mon 2 Nov". The row is disabled when the task is undated, with the footnote "Give it a date to repeat." **Gate:** ship this row only together with `Recurrence.next(after:rule:calendar:)` in Kit and the completion hook that spawns the next occurrence, with tests. Until then, hide it behind `Features.repeat`.
4. **Weight.** Three pebble buttons in a row labelled "Small", "Medium" and "Large". They are 44 pt tall, with pebble glyphs of 8, 11 and 14 pt. The selected one is filled with `ink` at `.subheadline.weight(.semibold)`. They bind to `weightRaw`. VoiceOver reads "Weight, Medium" as an adjustable element.
5. **Tag.** A horizontal row of chips: "None", each `Tag` in order (a 6 pt dot in its colour plus the name, `.subheadline`), and "+ New". "+ New" opens an `.alert` with a `TextField`. It creates a `Tag` with the next free `tag.N` colour and assigns it. The selected chip is `ink` text on `card` with a 1.5 pt `ink` border. VoiceOver: each chip is a button with the selected trait.
6. **Steps.** These are the subtasks, ordered by `order`.
   - **Rows:** a 22 pt circle check button, then a `TextField`.
   - **Adding:** the last row is "Add a step" (a `TextField`); return creates a step and keeps focus.
   - **Reordering:** via a context menu (Move up, Move down, Delete) and the matching VoiceOver actions. A `ScrollView` can't use `.onMove`, and a nested `List` isn't justified.
   - **Checking:** a check fades the step text to `inkTertiary` with a strikethrough.
   - **Not in this phase:** "Smaller" (step suggestions) is not shown.
7. **Notes.** `TextField("Notes", text: $task.notes, axis: .vertical)` with a line limit of 3 to 12 and `.body`, on a `card` group.
8. **Pledge (placeholder).** A group with a lantern glyph: a 10 pt `witness` circle with a 20 pt `witness` 20% halo, drawn as shapes.
   - **If `task.pledge` exists** (from an `@name` capture): show "Promised to **Sam**" and "by Fri 30 Oct" in `witnessText`.
   - **Otherwise:** show "Promise this to someone" in `inkSecondary`.
   - **Both cases:** add the footnote "Witnesses and receipts arrive in a later update." The row is **not** a button and has no chevron, so it isn't a dead end.
   - **VoiceOver:** "Pledge. Promised to Sam by Friday 30 October. Witness tools arrive in a later update."
9. **Trail (only if `task.landmark` is set).** A read-only line: "▲ On the way to Sam's 40th · T-7", using `landmark` colour.
10. **Footer.** "Added 23 Oct · Edited 06:30" in `.caption`, `inkTertiary`.

### B.3 Saving

- Edits bind straight to the `@Bindable var task: ToDo`.
- On each change, set `task.modifiedAt = .now` (via `.onChange` on a small hashable snapshot of the edited fields).
- On disappear:
  - Trim the title, and restore it if it's empty.
  - Save the context.
  - Run `await scheduler.schedule(task)` and `Widgets.reload()`.
- There is no Save button. Closing the sheet keeps the edits, as with a card.

### B.4 Finish bar and delete

- **Finish bar.**
  - Full width minus 20 pt on each side, 56 pt tall, `.glassEffect(.regular.tint(Tokens.ember.opacity(0.25)).interactive(), in: .capsule)`. Its label is "Hold to finish" in `.headline` `ink`, with a `circle.dotted` glyph.
  - It uses `holdToComplete`. While pressing, an `ember` fill grows left to right over `Motion.hold` (a `Rectangle` masked to the capsule, `scaleEffect(x:)` anchored leading).
  - On completion: `dismiss()`, then the parent calls `complete(id)` after 0.35 s, so the `sink` transition, the new stone and the toast all play on the visible field.
  - **VoiceOver or Reduce Motion:** the bar becomes a plain button, "Finish", which completes on a tap. The Undo toast covers mistakes.
  - **Already-completed task:** the bar reads "Reopen" (`.bordered`), which calls `Completion.undo` if inside the window. Otherwise it sets `isCompleted = false`, `stateRaw = "active"`, `completedAt = nil`.
- **Delete.** Choosing the menu item shows `.confirmationDialog("Delete “\(title)”?", titleVisibility: .visible)` with the message "This can't be undone." and `Button("Delete", role: .destructive)`. This is the only red in the app. After deleting:
  - Dismiss the sheet.
  - Cancel the notification (`notificationID`).
  - Reload widgets.
  - Post the announcement "Deleted."
- **Dependency, needed before Delete ships.** `cairnTotal` is currently `todos.filter(\.isCompleted).count`, so deleting a finished task would make the Cairn shrink. That breaks "the total can never decrease". Add a monotonic `cairn.lifetime` counter, kept in `Store.groupDefaults` or as a tiny model:
  - `Completion.complete` increments it.
  - `Completion.undo` decrements it, but only inside the undo window.
  - Delete never touches it.

### B.5 Notification permission, in context (shared with §C)

`requestNotificationPermission()` is removed from `App.init` (`registerCategories()` stays). A small `NudgePermission` observable in the app target wraps `UNUserNotificationCenter.notificationSettings()`.

| Trigger | Status `.notDetermined` | `.denied` | `.authorized` / `.provisional` |
|---|---|---|---|
| Remind toggled on in the sheet | Show an inline card under the row: "Waymark nudges you only for things you set a reminder on." with buttons [Allow nudges], which calls `requestAuthorization([.alert, .sound, .badge])`, and [Not now], which turns the toggle back off | Keep the toggle on and show the inline text "Nudges are off for Waymark." with an [Open Settings] button (`UIApplication.openNotificationSettingsURLString`) | Nothing |
| A task with a time is captured on the main screen, and no ask has happened yet | Once only, a glass banner above the capture bar: "Want a nudge at 2:00 PM? [Allow] [×]" | Nothing | Nothing |
| Onboarding step 3 (§C) | See §C | Not applicable | Not applicable |

Store `nudges.asked` (Bool) in standard defaults. After one decline, the main screen never asks again; only the sheet's Remind toggle can.

---

## C. First-run onboarding (three screens at most)

**Trigger:** `@AppStorage("onboarding.v1.done") == false` and the store booted successfully. It's presented as a `.fullScreenCover` over `HorizonView`, with `interactiveDismissDisabled()`. A **Skip** button (top trailing, plain, `inkSecondary`, 44 pt) is on every step and marks onboarding done.

**Structure:** use a single `OnboardingView` holding `@State var step: Int` and a `switch` that swaps views with `.transition(.push(from: .trailing))` and `Motion.page` (opacity under Reduce Motion). **Don't use a paged `TabView`.** Swiping between pages would fight the hold practice on step 2, and explicit buttons make the pace clear.

**Layout for each step:**

- The background is the same `SkyBackground` at the current time.
- The top 55% holds the illustration or live element.
- Then a headline in `.largeTitle` serif semibold, `ink`, with a line limit of 3 and `minimumScaleFactor(0.85)`, followed by body text in `.body` `inkSecondary`, with a maximum width of 34 em (about 480 pt).
- The bottom holds a step indicator and a primary button using `.buttonStyle(.glassProminent)`, tinted `ember`, with `controlSize(.large)` and full width.
  - **Step indicator:** three 6 pt capsules. The current one is 18 pt wide and `ink`, the others `contour`. It's labelled "Step 1 of 3" and has `accessibilityHidden` on the shapes.
- **At accessibility sizes:** the whole step goes in a `ScrollView`, and the illustration shrinks to 30%.

**Step 1: the path.**

- **Illustration:** a live miniature of the field: the path rails, the horizon line, the sun, and five sample chips ("Dentist", "Pay rent", "Sam's 40th ▲", and so on).
  - **Motion:** every 2.4 s, one chip moves from the threshold up to its band (`reflow`), showing that time is distance. The loop pauses after three cycles.
  - **Reduce Motion:** a static frame.
  - **Accessibility:** decorative, hidden.
- **New user:** "Your days, laid out ahead." / "Today is close and large. Later things wait further up the path, smaller, until they're near." Button: **Next**.
- **Upgrading user** (the relocation result was `.moved(rows: n)`, or a V1→V2 migration ran): "Your tasks made the move." / "All \(n) are here, placed by when they're due. Nothing was lost." This requires `Store.bootstrap()` to return the `RelocationResult` along with the container (§E).

**Step 2: hold to finish.**

- **Live element:** a real-sized ember `TaskCard` titled "Hold me to finish", above a three-stone Cairn strip.
- **Behaviour:** it uses `holdToComplete` with the same ring and haptic ramp. On completion the card sinks, a fourth stone lands with the settle haptic, and the copy changes. The card does not reappear; a **Try again** text button restores it.
- **Copy:** "Hold to finish." / "Press and hold for a moment. Finished things become stones in your cairn, and the pile only grows." After a successful hold: "That's a stone." / "Undo is always there for a few seconds."
- **Next:** always enabled, so the step is never forced.
- **VoiceOver:** the card has the custom action "Finish" and the hint "In Waymark, hold a card to finish it. With VoiceOver, use the Finish action." A successful finish posts the announcement "Stone laid."
- **Reduce Motion:** the copy reads "Tap to finish." and a tap completes, matching the app's behaviour.

**Step 3: drop a thought (and the contextual nudge ask).**

- **Live element:** the real `CaptureBar` with parse chips, focused on appear (keyboard up). Above it sit the three example chips from §A.7.
- **Copy:** "Drop a thought." / "Type it like you'd say it. A day or time sends it up the path; *#tag* and *@name* work too."
- **On commit:** the task is really created (`Capture.insert`) and shown as a landed card ("Landed in hand." or "Placed on Fri, up the path.").
  - **If it has a time** and the status is `.notDetermined`, an inline card slides in: "Want a nudge at 2:00 PM on Fri?" / "Waymark only nudges for things you give a time." with [Allow nudges] and [Not now]. Both set `nudges.asked`.
  - **If it has no time:** no ask.
- **Primary button:** **Start**, enabled at any point, including before a commit. It marks onboarding done.

**After onboarding:** the cover dismisses with a cross-fade. The tasks created in step 3 are already in the field, and the Horizon shows either First light or the new card.

**Settings › Developer (DEBUG)** has "Reset onboarding", which sets the flag to false and `nudges.asked` to false.

---

## D. Recovery screen: store relocation failed

**Today:** `Store.bootstrap()` throwing ends in `fatalError`. Moving the store already stops safely (the legacy store is untouched on a mismatch, `Relocation.swift`), but the user sees a crash loop.

**Boot state:**

```swift
enum BootFailure: Equatable {
  case relocationMismatch(expected: Int, got: Int)   // RelocationError.rowCountMismatch
  case outOfSpace                                     // NSFileWriteOutOfSpaceError / ENOSPC in the chain
  case other(code: String)                            // domain+code only, never task text
}
@Observable final class Boot { var state: State; enum State { case ready(ModelContainer, RelocationResult), failed(BootFailure), retrying } }
```

- `App.init` attempts the bootstrap once.
- `WindowGroup` switches: `.ready` shows `HorizonView` (and onboarding), `.failed` or `.retrying` shows `RecoveryView`.
- While the boot has failed, there's no notification reconcile and no `DemoSeed`. Widgets and intents are already guarded by `Store.isReady`.

**RecoveryView layout:**

- **Background:** `SkyBackground` fixed to the dusk keyframe (calm, never alarming), with the field hidden.
- **Content:** a `ScrollView` with a `VStack(spacing: 20)` and 28 pt horizontal padding, vertically centred with `containerRelativeFrame(.vertical)` at default sizes.
- **Mark:** a 56 pt cairn of three stacked stones drawn with shapes in `stone` and `ember` on top. It's decorative. **No warning triangle and no red.**
- **Title:** "Your tasks are safe." in `.title` serif semibold. Set `.accessibilityAddTraits(.isHeader)` and give it focus on appear (`@AccessibilityFocusState`).
- **Body** (`.body`, `inkSecondary`), by case:
  - **mismatch:** "Waymark couldn't finish moving your tasks to their new home, so it stopped and left the original copy untouched on this iPhone."
  - **outOfSpace:** "Your iPhone is nearly out of space, so Waymark couldn't move your tasks yet. The original copy is untouched. Free up some space and try again."
  - **other:** "Something stopped Waymark from opening your tasks. The original copy is untouched on this iPhone."
- **"What happened"** is a `DisclosureGroup` in `.footnote`, `inkSecondary`. It contains the plain explanation ("We copy your tasks to a shared place so widgets and Siri can see them. The copy had 21 of 23 tasks, so we stopped.") and a diagnostic code such as `WM-R1 23/21`, selectable with `.textSelection(.enabled)`.

**Actions** are stacked full width, with a minimum height of 50:

1. **Try again.** `.buttonStyle(.glassProminent)`, `.tint(ember)`.
   - Runs `Store.bootstrap()` off the main actor (`Task.detached`), with `ProgressView()` shown inside the button and the label "Trying…".
   - **On success:** cross-fade to the Horizon (opacity 0.3 s), with the announcement "Your tasks are back."
   - **On failure:** stay, increment `attempts`, and announce "Still couldn't move them. Your original copy is safe."
   - **For `outOfSpace`:** add a secondary line button, "Open Settings" (`UIApplication.openSettingsURLString`).
2. **View my tasks.** `.buttonStyle(.glass)`. Opens a read-only sheet that lists the legacy store's contents with `ModelContainer(for: SchemaV1.ToDo.self, SchemaV1.SubTask.self, configurations: ModelConfiguration(url: Store.legacyStoreURL, allowsSave: false, cloudKitDatabase: .none))`. Each row shows the title, the due date, and the subtasks as secondary text. There are no edits. If the legacy file is gone, because the failure happened after relocation (the `.other` case), the button is hidden.
3. **Share a copy.** `.buttonStyle(.glass)`. A `ShareLink` of a JSON export (`waymark-backup-YYYY-MM-DD.json`: title, dueDate, isAllDay, isCompleted, category, subtasks) built from the same read-only container. It's hidden under the same condition as "View my tasks".
4. **Email support.** `.buttonStyle(.plain)`, `emberText`. A `mailto:` link with the diagnostic code, iOS version and app version in the body. **It never includes task titles.**

After three or more attempts, the order changes to Email support, Try again, Share a copy, View my tasks, and the body adds: "This needs a closer look. Your tasks stay safe here in the meantime." **The screen never offers "start fresh" or anything that deletes data.**

**Accessibility:** every button is a standard control, the screen uses Dynamic Type with no caps, and nothing animates except the progress indicator.

---

## E. Build order, files and acceptance

All work stays in `Simple Task/Horizon/` and `SimpleTaskKit/Horizon/`, plus the new files named below.

| # | Work | Files | Acceptance |
|---|---|---|---|
| 1 | Tokens and contrast | `Tokens.swift` (new text, surface and tag tokens; `Space`, `Radius`), `Sky.swift` (keyframes and sun position, pure) | A `TokenContrastTests` test asserts that every text token has at least 4.5:1 and every tag at least 3:1, light and dark, against `ground` and `card`. `SkyTests` checks 06:00 is dawn, 12:00 is day, 18:00 is golden, 23:00 is night, and that interpolation is monotonic |
| 2 | Field depth | `SkyBackground.swift` (Canvas), `BandHeights.swift` (pure, Kit), `BandField`/`FarChip` rewrite (no `scaleEffect`; path insets), `HorizonHeader.swift` | `BandHeightsTests`: empty bands get 32 pt, the sum is the total, and populated bands get at least their rows. Snapshots on iPhone SE (3rd generation) and 17 Pro Max in light and dark, at 06:30, 12:00 and 20:00 |
| 3 | Cards and In Hand | `TaskCard` (ember rail, glow, pebbles, centred content, no menu), `InHandSection` (Grid, odd-span rule), `SinkTransition`, `CairnStrip` (empty and label copy) | The screenshot fixture shows no "…", no "0 today 0" and no ladybug. Snapshot at AX5 is in Itinerary mode |
| 4 | Empty states and capture | `EmptyStates.swift`, `CaptureBar` (glass, hidden disabled arrow, example-chip fill API) | The three empty-state snapshots. Tapping an example fills the field without committing |
| 5 | Task sheet | `TaskSheet/TaskSheet.swift`, `DistanceStrip.swift`, `WhenGroup.swift`, `TagRow.swift`, `StepsGroup.swift`, `PledgePlaceholder.swift`, `FinishBar.swift`; remove the `DetailView` route | UI test: tap a card, change Distance to Week, close, and the card is now in Week. Delete asks for confirmation. The Cairn total is unchanged after deleting a finished task (needs the `cairn.lifetime` counter) |
| 6 | Permission in context | `NudgePermission.swift`; remove the launch request in `Simple TaskApp.swift` | A fresh install shows no prompt at launch. Toggling Remind shows the pre-prompt card. A denied status shows Open Settings |
| 7 | Onboarding | `Onboarding/OnboardingView.swift` plus three step views; `Store.bootstrap()` returns `(ModelContainer, RelocationResult)` | A fresh install shows step 1. Skip works on every step. Step 2 hold lands a stone. Step 3 creates a real task. Relaunching doesn't show onboarding again |
| 8 | Recovery | `Boot.swift`, `Recovery/RecoveryView.swift`, `LegacyReadOnlyList.swift`; replace `fatalError` | A unit test forces `RelocationError.rowCountMismatch` (stub the counts) and checks that the boot state is `.failed(.relocationMismatch)` and the legacy file still exists. Retry succeeds once the stub is cleared. The UI snapshot contains no red |
| 9 | Repeat (gated) | `Recurrence.swift` (Kit), hooked into `Completion.complete` | Tests cover daily, weekdays (Friday rolls to Monday), monthly on the 31st, and DST crossing. `Features.repeat` is turned on only after these pass |

**Never:** red outside the delete confirmation, a "You missed" message, streak copy, `.system(size:)` text, `scaleEffect` on text, or a context menu on a holdable card.

**Open questions for the owner:**

1. Should the path rails be visible at all times, or only when the field has at least one far item? The recommendation is always, because they carry the identity.
2. "Month" is +14 days on the Distance strip. Is that acceptable as the default, or should Month open the date picker the way Beyond does?
3. Should Itinerary mode be offered as a user setting for everyone, or kept as accessibility-only? The recommendation is accessibility-only for now.
