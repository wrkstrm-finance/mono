# UptimeTelemetry — Multi‑Target Learnings (Today)

This note documents the decisions and patterns refined while shipping the
multi‑target telemetry component (Status Menu + Tau) and the reusable detail
view.

## What Shipped

- Models in TauKit (scoped for 1–2 targets):
  - `UptimeTelemetry.GroupConfig`, `TargetConfig`, `GroupSummary`.
  - `Source`: `uptime|online`; `SLOMode`: `twentyFourFive|eightFive`.
- Reusable detail view and macOS window helper:
  - Paths: `metrics/{uptime|online}/{app|network}/{slug}/YYYY-MM-DD.jsonl` (UTC files).
  - SLO anchors business window: 24/5 ⇒ Local; 8/5 ⇒ US/Eastern.
- Status Menu preview refinements:
  - Centered title; right‑aligned footer (“Last seen …” with status dot + refresh).
  - Weekday axis order pinned; hover disabled (request filed to re‑introduce).
  - Info popover lists monitored targets, metrics paths, and App Group root.

## Rationale

- UTC‑bounded files are resilient to DST and local time drift. Business windows
  (Local vs ET) are applied in aggregators at read time.
- GroupConfig limits scope to 1–2 targets for a compact, readable UI.
- Detail view is a component so any app can present bins/totals without owning
  filesystem logic.

## Acceptance Criteria (Kept Green)

- Correct per‑day availability under 24/5 Local and 8/5 ET windows.
- “Today” clamps at now; past days use full window.
- Axis day order remains Mon→Fri; grouped bars render stably.
- Single‑instance enforced via Info.plist; writers tick cleanly.

## Next Steps

- Implement `UptimeTelemetry.Aggregator.summarize` (JSONL read, UTC joins,
  today clamp, KPIs).
- Persist Source/SLO toggles; pass Source into detail.
- Swift Testing: uptime/online scoring, DST edges, UTC split joins.
- Hover return (ChartSelection) with tooltip — see request
  `alphabeta-tau-uptime-chart-hover-selection`.

## Pointers (Paths)

- TauKit models and views:
  - `code/mono/apple/spm/cross/TauKit/Sources/TauKit/UptimeTelemetry/`.
- Status Menu integration:
  - `code/mono/apple/alphabeta/tau/mac-status-app/UptimePreviewView.swift`
  - `code/mono/apple/alphabeta/tau/mac-status-app/UptimeDetailWindowManager.swift`
