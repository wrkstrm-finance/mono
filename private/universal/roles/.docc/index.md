# wrkstrm-finance Roles

This directory is the org-owned home for role definitions in the commissioned
`wrkstrm-finance` collective.

## Core Rule

- Roles define reusable mandates.
- Positions bind roles to wrkstrm-finance seats.
- Assignments bind agents, runtimes, or operators to those positions.
- Agents can serve roles, but they do not own the role definition.

## Storage Rule

Role definitions live as flat `*.org-role.json` packets under
`private/universal/roles/`.

- `roles.json` is the machine-readable local role catalog.
- `*.org-role.json` files hold the reusable mandate.
- `private/universal/workstream-templates/*.workstream-template.json` holds reusable work instructions.
- `private/.wrkstrm/beads/formulas/*.formula.json` holds local Beads workflow formulas.
- Position and assignment packets should reference these roles instead of
  copying mandate text into agents.
- Active backlog and planned execution work should not live directly in role
  sections; roles point at templates and formulas instead.

## Current Role Definitions

- `finance-broker-adapter-steward.org-role.json` — Wrkstrm Finance Broker Adapter Steward
- `exit-whisper.org-role.json` — Wrkstrm Finance Exit Whisper
- `market-summarizer.org-role.json` — Wrkstrm Finance Market Summarizer
- `strategy-auditor.org-role.json` — Wrkstrm Finance Strategy Auditor
- `swift-public-libraries-steward.org-role.json` — Wrkstrm Finance Public Library Steward
- `trade-journaler.org-role.json` — Wrkstrm Finance Trade Journaler
