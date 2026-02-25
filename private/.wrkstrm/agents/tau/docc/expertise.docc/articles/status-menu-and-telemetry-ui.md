# Status Menu and Telemetry UI

This article documents the Status Menu’s role in Tau’s telemetry system and outlines
the reusable UI components for previews and in‑app integration.

## Components

- TauKit.UptimeTelemetryDetailView: renders per‑day bins and totals.
- Status Menu Preview: grouped bars; centered title; right‑aligned footer.
- Info Popover: lists targets, metrics paths, and App Group root.

## Interaction

- Open `tau-animation-demo` window from the menu for richer demos.
- Defer hover effects until stable chart selection behavior is available.

## Known Issues

- Menu push navigation popover content may be invisible; track via backlog.

## Follow‑ups

- Add chart annotations for outage periods and SLO breaches.
- Add deep‑linking to specific dates and components for bug reports.
