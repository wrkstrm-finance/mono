# Code Recipes — Tau Uptime/Online Telemetry

Practical, copy‑pasteable snippets Tau uses across the app family. Lead with
code; keep it small and predictable.

## Group Configuration (1–2 Targets)

```swift
import TauKit

let group = UptimeTelemetry.GroupConfig(
  groupId: "tau-suite",
  title: "Tau Telemetry",
  targets: [
    .init(
      bundleIdentifier: "me.rismay.tau.cross.app.beta",
      slug: "tau",
      title: "Tau",
      role: .app,
      source: .both,
      color: "#6AA0FF"
    ),
    .init(
      bundleIdentifier: "me.rismay.tau.mac.status.beta",
      slug: "status-menu",
      title: "Status",
      role: .helper,
      source: .both,
      color: "#89F94F"
    ),
  ],
  defaultSource: .uptime,
  sloDefault: .twentyFourFive,
  colorPalette: nil,
  overrides: .init(appGroupId: "group.me.rismay.tau.alphabeta")
)
```

## Present Reusable Per‑day Detail (macOS)

```swift
import TauKit

let target = group.targets[0]  // Tau
UptimeTelemetryDetailWindow.show(
  target: target,
  day: Date(),
  source: .uptime,
  slo: .twentyFourFive,
  groupOverrides: group.overrides
)
```

## Pin Weekday Order in Charts (No Drift)

```swift
Chart(combined(from: vm.tauSeries, vm.statusSeries)) { rec in
  BarMark(x: .value("Day", rec.day), y: .value("Uptime", rec.percent))
    .position(by: .value("App", rec.series))
}
.chartXScale(domain: vm.tauSeries.map { $0.day })  // Mon→Fri pinned
.chartYScale(domain: 0...1)
```

## Append JSONL Uptime Snapshot (UTC Day Files)

```swift
let iso = ISO8601DateFormatter()
iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
let now = Date()
let snapshot: [String: Any] = [
  "startedAt": iso.string(from: ProcessInfo.processInfo.systemUptimeStartDate),
  "lastSeen": iso.string(from: now),
  "uptimeSeconds": ProcessInfo.processInfo.systemUptimeSeconds,
  "bundleId": Bundle.main.bundleIdentifier ?? "",
]
let day = ISO8601DateFormatter().string(from: now).prefix(10)
let base = FileManager.default.containerURL(
  forSecurityApplicationGroupIdentifier: "group.me.rismay.tau.alphabeta")!
let url = base.appendingPathComponent("metrics/uptime/tau/\(day).jsonl")
try FileManager.default.createDirectory(
  at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
let data = try JSONSerialization.data(withJSONObject: snapshot)
if let fh = FileHandle(forWritingAtPath: url.path) {
  try fh.seekToEnd()
  fh.write(data)
  fh.write("\n".data(using: .utf8)!)
  try fh.close()
} else {
  var blob = Data()
  blob.append(data)
  blob.append("\n".data(using: .utf8)!)
  try blob.write(to: url, options: .atomic)
}
```

## UTC Filenames Covering a Business Window

```swift
func utcDayNamesCoveringWindow(start: Date, end: Date) -> [String] {
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

## Clamp “Today” Within the Business Window

```swift
let effectiveEnd = min(sloEnd, now)
let expected = max(0, effectiveEnd.timeIntervalSince(sloStart))
guard expected > 0 else { return 0 }
let fraction = min(1, max(0, covered / expected))
```

## Single‑instance via Info.plist

```xml
<key>LSMultipleInstancesProhibited</key>
<true/>
```

## Minimal Click‑to‑detail Overlay

```swift
.chartOverlay { proxy in
  GeometryReader { geo in
    Rectangle().fill(.clear).contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onEnded { value in
          guard let frame = proxy.plotFrame else { return }
          let origin = geo[frame].origin
          let x = value.location.x - origin.x
          // Find nearest day center, decide Tau vs Status by comparing to group center
          // then present detail window (see previous recipe).
        })
  }
}
```

## Swift Testing — Scoring Uptime and Online

```swift
import Foundation
import Testing

@Suite struct TelemetryScoringTests {
  // Uptime: integrate successive lastSeen snapshots inside [start,end)
  @Test func uptime_scoring_clamps_today_and_merges_utc() throws {
    let tz = TimeZone(identifier: "America/New_York")!
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let day = cal.date(from: DateComponents(year: 2025, month: 10, day: 2))!
    let start = day  // 00:00 local
    let now = cal.date(bySettingHour: 11, minute: 0, second: 0, of: day)!
    let end = now  // clamp at now (today)

    // Snapshots every hour from 07:00–10:00 (4 hours covered)
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let snaps = stride(from: 7, through: 10, by: 1).map { h in
      iso.string(from: cal.date(bySettingHour: h, minute: 0, second: 0, of: day)!)
    }
    let covered = coveredUptimeSeconds(
      snapshotsISO: snaps,
      windowStart: start,
      windowEnd: end
    )
    let expected = end.timeIntervalSince(start)
    let fraction = max(0, min(1, covered / expected))
    #expect(abs(fraction - (4.0 * 3600) / expected) < 0.001)
  }

  // Online: attribute elapsed time to the prior state (online/offline)
  @Test func online_scoring_respects_transitions_and_tail() throws {
    let tz = TimeZone(identifier: "America/New_York")!
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let day = cal.date(from: DateComponents(year: 2025, month: 10, day: 2))!
    let start = cal.date(bySettingHour: 9, minute: 30, second: 0, of: day)!
    let end = cal.date(bySettingHour: 16, minute: 0, second: 0, of: day)!

    // Transitions: 09:30 online, 12:00 offline, 13:00 online → end (tail counts)
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let events: [(String, Bool)] = [
      (iso.string(from: start), true),
      (iso.string(from: cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)!), false),
      (iso.string(from: cal.date(bySettingHour: 13, minute: 0, second: 0, of: day)!), true),
    ]
    let covered = coveredOnlineSeconds(
      eventsISO: events,
      windowStart: start,
      windowEnd: end
    )
    // Online spans: 09:30–12:00 (2.5h) and 13:00–16:00 (3h) → 5.5h
    #expect(abs(covered - 5.5 * 3600) < 0.5)
  }
}

// Helpers used by tests
func coveredUptimeSeconds(snapshotsISO: [String], windowStart: Date, windowEnd: Date)
  -> TimeInterval
{
  let iso = ISO8601DateFormatter()
  iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let snaps = snapshotsISO.compactMap { iso.date(from: $0) }.sorted()
  guard snaps.count >= 2 else { return 0 }
  var total: TimeInterval = 0
  for (a, b) in zip(snaps, snaps.dropFirst()) {
    let lo = max(a, windowStart)
    let hi = min(b, windowEnd)
    if hi > lo { total += hi.timeIntervalSince(lo) }
  }
  return max(0, total)
}

func coveredOnlineSeconds(eventsISO: [(String, Bool)], windowStart: Date, windowEnd: Date)
  -> TimeInterval
{
  let iso = ISO8601DateFormatter()
  iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let evs = eventsISO.compactMap { (s, on) in (iso.date(from: s), on) as? (Date, Bool) }.sorted {
    $0.0 < $1.0
  }
  var total: TimeInterval = 0
  var prev: Date?
  var online = false
  for (ts, on) in evs {
    if let p = prev {
      let lo = max(p, windowStart)
      let hi = min(ts, windowEnd)
      if hi > lo, online { total += hi.timeIntervalSince(lo) }
    }
    prev = ts
    online = on
  }
  if let p = prev, p < windowEnd, online {
    total += max(0, windowEnd.timeIntervalSince(max(p, windowStart)))
  }
  return max(0, total)
}
```
