# Uptime Telemetry Overview

This article outlines Tau’s approach to capturing and visualizing uptime. It covers data
collection, aggregation, and charting, with support for 24/5 and 8/5 SLOs.

## Goals

- Capture minute‑level online/offline state from Status Menu and Tau app.
- Persist as JSONL snapshots with deterministic filenames per day.
- Aggregate to per‑day totals and SLO‑aware scoring.
- Visualize as stacked bars (uptime vs. offline) with concise KPIs.

## Data Sources

- Status Menu: writes minute snapshots under `metrics/uptime/status-menu`.
- Tau app: parity writer, plus `NWPathMonitor` network transitions under
  `metrics/network/tau`.

## Aggregation

- Daily bins with totals (uptime minutes, offline minutes, last event).
- SLO presets: 24/5 and 8/5; scoring honors business hours.

## Visualization

- Swift Charts stacked bars per day.
- Header KPIs: uptime %, offline minutes, last network transition.

## Next Steps

- Add alert thresholds and annotations for SLO breaches.
- Export compact CSV/JSON for sharing and archival.
