# Tau Module — Exit Whisper

This module, formerly tracked as the WhisperExit agent, is now owned by Tau. It drafts exit recommendations and actions as trades approach targets, and records realized P/L aligned with payroll cadence and audit documentation.

- Product function: Recommend or execute exits at profit-capture thresholds or trailing stop breaches.
- Stewardship function: Journal realized P/L with entity segregation and governance alignment.
- Historical daemon/app: `whisper-exit.app` (legacy; future flows route through Tau).

Milestones (from legacy agenda)

- Near-term: profit capture and trailing stop strategies; broker hooks; P/L journal writes with entity segregation.
- Mid-term: strategy-aware exits (calendars/diagonals/verticals) with sleeve guardrails; simulation/replay tooling.
- Long-term: autonomous exit engine with human-in-the-loop overrides and governance logs.

Alignment

- Journal outcomes to Trade Journaler and feed Strategy Auditor (now also Tau-owned agendas).

Archive

- Triad content was imported into Tau on 2025-10-07.
