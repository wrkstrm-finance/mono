# UptimeTelemetry — Bugs Found, Root Causes, and Fixes

This article documents the concrete issues encountered while building the
multi‑target telemetry preview (Status Menu) and the reusable per‑day detail
component, along with the rationale for fixes and remaining follow‑ups.

## 1) Weekday Axis Reordering (Mon→Fri Drift)

- Symptom: Bars occasionally appeared out of weekday order after data refresh.
- Why: Swift Charts inferred a categorical X domain from incoming series and
  re‑sorted when labels changed or data arrived out of order.
- Fix: Pin a stable domain with the exact weekday labels used by the view
  model: `chartXScale(domain: vm.tauSeries.map { $0.day })`.
- Files: mac-status-app/UptimePreviewView.swift

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/UptimePreviewView.swift
Chart(combined(from: vm.tauSeries, vm.statusSeries)) { rec in
  BarMark(
    x: .value("Day", rec.day),
    y: .value("Uptime", rec.percent)
  )
  .position(by: .value("App", rec.series))
}
.chartXScale(domain: vm.tauSeries.map { $0.day })  // pin Mon→Fri order
.chartYScale(domain: 0...1)
```

## 2) Hover Jitter (Bars “Wiggle” on Move)

- Symptom: Hovering caused tiny layout shifts; sometimes bars flickered.
- Why: Our hover state updated every move and combined with implicit chart
  animations and grouped layout, caused re‑layout churn.
- Fix: Removed hover visuals for now; backlog request created to re‑introduce
  a ChartSelection‑based solution. Click‑to‑detail remains.
- Files: mac-status-app/UptimePreviewView.swift; request slug
  `alphabeta-tau-uptime-chart-hover-selection`.

## 3) Ambiguous Multi‑series Hover (Tau vs Status)

- Symptom: Hover over a day didn’t disambiguate which series (left vs right).
- Why: `value(atX:)` returns only the X label (day) in a grouped chart.
- Attempted workaround: Infer left/right by comparing pointer X against the
  group center via `position(forX:)`. This was brittle and contributed to
  jitter.
- Resolution: Removed the heuristic; defer series‑aware hover to the backlog
  (ChartSelection), where the selection API can track series directly.

```swift
// Hover overlay removed; keep only click-to-detail gesture
.chartOverlay { proxy in
  GeometryReader { geo in
    Rectangle().fill(.clear).contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onEnded { value in
          // compute nearest day and open detail …
        })
  }
}
```

## 4) Duplicate Online/Refresh in Header and Footer

- Symptom: Both header and footer showed Online dot + Refresh.
- Why: We added a footer to centralize status while leaving the header in
  place.
- Fix: Removed header indicators; footer now owns Online dot, Last‑seen, and
  a light refresh control.
- Files: mac-status-app/TauStatusMenuApp.swift

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/TauStatusMenuApp.swift
HStack {
  Text("Tau Status").font(.title3).bold()
  Spacer()
  // Header Online/Refresh removed — footer owns status/refresh now.
}
```

## 5) Detail Moved to TauKit — Build Errors

- Symptom: “Cannot find UptimeTelemetry in scope” and type lookup failures.
- Why: The Status Menu target didn’t import TauKit where we bridged to the new
  reusable component.
- Fix: `import TauKit` in UptimeDetailWindowManager and call
  `UptimeTelemetryDetailWindow.show(...)` with a small TargetConfig bridge.
- Files: mac-status-app/UptimeDetailWindowManager.swift; TauKit detail files
  under `TauKit/Sources/TauKit/UptimeTelemetry/`.

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/UptimeDetailWindowManager.swift
#if canImport(TauKit)
import TauKit
#endif

let target = UptimeTelemetry.TargetConfig(
  bundleIdentifier: "",
  slug: appFolder,  // "tau" or "status-menu"
  title: appFolder == "tau" ? "Tau" : "Status Menu",
  role: .app,
  source: .both,
  color: "#6AA0FF"
)
let slo: UptimeTelemetry.SLOMode = (mode == .marketHours8x5) ? .eightFive : .twentyFourFive
UptimeTelemetryDetailWindow.show(target: target, day: day, source: .uptime, slo: slo)
```

## 6) Main‑actor Warnings on Detail Window Lifecycle

- Symptom: “main actor‑isolated property ‘window’ mutated from a Sendable
  closure”.
- Why: NSWindow is main‑actor; our NotificationCenter handler mutated a static
  window from a closure without main‑actor context.
- Fix: Marked the window helper enum `@MainActor`. For the observer, prefer a
  main‑actor closure or wrap assignments in `Task { @MainActor in ... }`.
- Files: TauKit/UptimeTelemetryDetailWindow.swift.
- Follow‑up: Replace `addObserver` with a main‑actor `NotificationCenter`
  publisher or explicit `Task { @MainActor in self.window = nil }` to silence
  the remaining warning.

## 7) “Today Shows Too Many Hours Early in the Day”

- Symptom: Early local morning showed more hours than elapsed.
- Why: Aggregators initially didn’t clamp the window end to `now` and mixed
  local vs ET anchors inconsistently.
- Fix: Compute business window (Local for 24/5; ET for 8/5), then
  `effectiveEnd = min(sloEnd, now)` before fraction math.
- Files: mac-status-app/UptimeViewModel.scoreDay/scoreOnlineDay; same approach
  to be applied in TauKit Aggregator implementation.

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/UptimeViewModel.swift
let effectiveEnd = min(sloEnd, now)
let expected = max(0, effectiveEnd.timeIntervalSince(sloStart))
guard expected > 0 else { return 0 }
```

## 8) “Detail View Shows Same Bins Across Days”

- Symptom: Switching days didn’t update the table content reliably.
- Why: The view was reused without a change identity and had shallow
  dependency updates.
- Fix: Added a composite `.id(viewKey)` and `onChange` handlers for day/mode
  to recompute bins.
- Files: mac-status-app/UptimeDayDetailView.swift

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/UptimeDayDetailView.swift
.id("\(appFolder)|\(utcDayName(from: day))|\(mode)")
  .onChange(of: day) { _, _ in Task { bins = await computeBins() } }
  .onChange(of: mode) { _, _ in Task { bins = await computeBins() } }
```

## 9) Missing Offline Periods in Online Mode

- Symptom: Brief offline periods weren’t reflected.
- Why: Initially only the Status Menu wrote network events; Tau app parity was
  pending. Also, the aggregator counted coverage using transition events and a
  coarse tick. Sub‑tick outages could be under‑counted.
- Fixes in flight:
  - Status Menu now samples every 30s and logs transitions. Tau app online
    writer parity is planned next.
  - Aggregator computes coverage from events with a tail segment to `now` and
    clamps to the business window. Consider a periodic sampler as a fallback
    for zero‑transition days.
- Files: mac-status-app/TauStatusMenuModel+Network.swift; ViewModel scoring.

## 10) Chart Card Felt Left‑heavy Off‑balance

- Symptom: Visual imbalance despite centered title.
- Why: Chart container was `.leading` aligned and controls had uneven widths
  (140 vs 112), and the info button added trailing weight.
- Fix: Center align the chart container; even out picker widths; keep the info
  button lightweight (plain style, subtle tint). Final tweak applied manually.
- Files: mac-status-app/UptimePreviewView.swift

## 11) UTC File Joins Around Day Boundaries

- Symptom: Edge bins near midnight/close appeared off.
- Why: Business windows (Local or ET) can cross UTC midnight; a single ET day
  requires reading up to two UTC files and merging.
- Fix: Explicitly collect the UTC YYYY‑MM‑DD names covering the window and
  merge text before parsing; apply to both uptime/online readers.
- Files: mac-status-app/UptimeViewModel.utcDayNamesCoveringWindow; mirrored in
  detail bin calculators.

```swift
// code/mono/apple/alphabeta/tau/mac-status-app/UptimeViewModel.swift
private func utcDayNamesCoveringWindow(start: Date, end: Date) -> [String] {
  let fmt = DateFormatter()
  fmt.dateFormat = "yyyy-MM-dd"
  fmt.timeZone = .init(secondsFromGMT: 0)
  var names: Set<String> = []
  var cursor = start
  let cal = Calendar(identifier: .gregorian)
  while cursor <= end {
    names.insert(fmt.string(from: cursor))
    cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
  }
  names.insert(fmt.string(from: end))
  return Array(names).sorted()
}
```

## 12) Single‑instance Behavior

- Symptom: Multiple helper/app instances led to confusing metrics and UI.
- Fix: Enforce single instance via Info.plist (LSMultipleInstancesProhibited),
  not ad‑hoc file locks.
- Files: app Info.plist across helper/app/cross targets.

```xml
<!-- Info.plist -->
<key>LSMultipleInstancesProhibited</key>
<true/>
```

---

### Open Follow‑ups

- Implement TauKit `UptimeTelemetry.Aggregator.summarize` and add Swift
  Testing for scoring (uptime + online), DST edges, UTC joins, and “today”
  clamp.
- Re‑introduce series‑aware hover with ChartSelection and tooltip.
- Add Tau app online writer parity.

```swift
// code/mono/apple/spm/cross/TauKit/Sources/TauKit/UptimeTelemetry/UptimeTelemetryDetailWindow.swift
@MainActor
public enum UptimeTelemetryDetailWindow {
  private static var window: NSWindow?
  // …
}
```
