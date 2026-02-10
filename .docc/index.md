# wrkstrm-finance taxonomy

This document defines the **taxonomy** for Wrkstrm Finance documentation and agent artifacts.

## What lives where

### Private agent system (authoritative, non-public)

- **Path:** `orgs/wrkstrm-finance/private/.clia/`
- **Purpose:** The CLIA agent system for this repo: triads, agendas, agency logs, generated agent bundles, and any operational metadata.
- **Why private:** This material includes operational posture (and may include sensitive details) and is not intended for public distribution.

What you will find:

- `private/.clia/agents/<agent>/` — agent directories
  - `*.agent.triad.json` — persona + guardrails
  - `*.agenda.triad.json` — forward plan / backlog
  - `*.agency.triad.json` — decision log / institutional memory

### Public documentation (published)

- **Path:** `orgs/wrkstrm-finance/public/docc/pages/wrkstrm-finance.github.io/`
- **Purpose:** Public-facing DocC/markdown pages intended to be published (GitHub Pages DocC exports).
- **Rule:** Public docs should describe *APIs, workflows, and architecture* without leaking private operational details.

### Workspace / local-only DocC (developer convenience)

- **Path:** `docc/private/host/local/` (mono workspace)
- **Purpose:** Local/private catalogs used for internal browsing and developer ergonomics.

## Naming + navigation rules (DocC)

These follow the repo DocC design system:

- Use an explicit technology root (`@TechnologyRoot`) for DocC bundles.
- Navigation is defined by the **curation tree** in `## Topics` (not folders on disk).
- Avoid “double curation”: parents link to containers; containers link to children.
- Keep resources in a flat `resources/` directory and use path-prefixed asset names to avoid collisions.

## Intent

- Keep **execution + agent governance** private (`private/.clia`).
- Keep **API surface area + usage docs** public (`public/docc/pages/...`).
- Keep **developer-only catalogs** out of the public publishing path (`docc/private/...`).
