# Tau Module — Trade Journaler

Tau owns journaling of brokerage executions into Notion Positions/Strategies and generates governance‑grade audit trails.

- Product: capture and journal fills; track return‑on‑capital relative to sleeve capacity.
- Stewardship: IRS‑ready audits; entity‑level segregation across accounts.
- Historical daemon: `swift run trade-journaler --poll` (legacy; future flows route through Tau).

Related packages

- NotionTrader: `code/mono/apple/spm/universal/domain/finance/notion-trader`
- Trade Daemon: `code/mono/apple/spm/universal/domain/finance/trade-daemon`
