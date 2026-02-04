# ^tau: Agency

_Updated: 2025-10-03T02:47:00Z_

## Agency log
### 2026-01-07T22:23:22Z — journal — CodeSwiftly DocC preview routing fix

- Summary: Diagnosed CodeSwiftly DocC preview routing and removed the baseUrl override for documentation slugs.
- Stopped overriding DocC baseUrl when serving /documentation/<slug> so SPA routing matches the archive output.
- Rebuilt and reinstalled the CodeSwiftly mac app to validate preview rendering.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): engineering=1 — Adjusted DocC preview server baseUrl handling for /documentation/<slug> and rebuilt CodeSwiftly to validate local previews.
- Tags: code-swiftly, docc, preview, bugfix

### 2026-01-07T11:28:31Z — journal — Roundup tooling and DocC refresh

- Summary: Expanded roundup-report tooling and refreshed product roundups for Tau, Hack-Nu, and CodeSwiftly.
- Extended roundup-report CLI to add data coverage, release cadence, and audit checks for missing pages and broken doc links.
- Added owned library filters based on package roots and Package.swift targets; removed .build, SourcePackages, derived, and .clia/tmp sources.
- Regenerated DocC bundles for tau, hack-nu, and code-swiftly roundups with updated summaries and sources.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): tooling=1 — Built roundup-report CLI features (coverage metrics, next-step callouts, git tag cadence, audits, source allow/deny lists, owned-package filtering, and .build/derived exclusions).; documentation=1 — Regenerated Tau, Hack-Nu, and CodeSwiftly executive roundups with per-day grouping and source file listings.; engineering=1 — Adjusted DocC tech root outputs and preview workflows for roundups.
- Tags: docc, roundup-report, tooling, tau, hack-nu, code-swiftly

### 2026-01-05T16:21:37Z — journal — DocC structure and validator updates

- Summary: Refined rismay-me DocC structure/assets and extended swift-docc-validator checks.
- Moved rismay-me experience pages into a folder and updated DocC links and metadata assets.
- Refined the About Me story copy to be more human and Swift platform aware.
- Updated swift-docc-validator to build DocC archives and detect duplicate PageImage references.
- Participants: codex (^codex)
- Contributions:
  - codex (^codex): documentation=1 — Updated rismay-me DocC structure and assets; refined About Me copy; extended swift-docc-validator (DocC archive + duplicate PageImage checks); validated rismay-me bundle.; tooling=1 — Rebuilt and reran swift-docc-validator audit/references/metadata for rismay-me.; engineering=1 — Adjusted validator internals for duplicate PageImage detection.
- Tags: docc, rismay-me, validator, tooling

### 2025-12-22T09:00:00Z — journal — Tau expertise kickoff

- Summary: Initialized Tau expertise DocC bundle with an index and two starter articles (uptime telemetry, status menu UI).
- Added tau-expertise.md and two articles (uptime telemetry overview; status menu & telemetry UI).
- DocC preview available via xcrun on port 8084.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): documentation=1 — Created memory.docc bundle and starter articles
- Tags: docc, tau, expertise
- Link: [Tau expertise root](.clia/agents/tau/docc/memory.docc)
- Link: [Uptime telemetry overview](.clia/agents/tau/docc/memory.docc/Articles/uptime-telemetry-overview.md)
- Link: [Status Menu and telemetry UI](.clia/agents/tau/docc/memory.docc/Articles/status-menu-and-telemetry-ui.md)

### 2025-12-22T08:00:00Z — journal — Expertise kickoff

- Summary: Tau expertise bundle initialized and previewed.
- Created Tau expertise DocC bundle with starter articles (uptime telemetry overview, status menu & telemetry UI).
- Previewed locally; linked from agents triads.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): documentation=1 — expertise bundle
- Tags: docc, tau, expertise
- Link: [Tau memory.docc](.clia/agents/tau/docc/memory.docc)

### 2025-10-03T02:47:00Z — journal — Reusable telemetry component landed; Status Menu wired; info popover

- Summary: Added TauKit UptimeTelemetry models and a reusable per‑day detail view; Status Menu preview cleaned (centered title, right‑aligned footer); hover deferred with backlog request.
- TauKit: UptimeTelemetry.{GroupConfig, TargetConfig, GroupSummary} with SLO (24/5, 8/5) and Source (uptime, online).
- TauKit: UptimeTelemetryDetailView (+ macOS window helper) renders bins/totals and source files.
- Status Menu: Preview uses grouped bars; info popover shows targets, metrics paths, App Group root.
- Hover: removed due to glitchiness; backlog filed to reintroduce via ChartSelection.
- Participants: tau (^tau), clia (^clia), codex (^codex), rismay (^rismay)
- Contributions:
  - tau (^tau): engineering=1 — migrated; ui=1 — migrated; documentation=1 — migrated
  - clia (^clia): engineering=1 — migrated; ui=1 — migrated; documentation=1 — migrated
  - codex (^codex): engineering=1 — migrated; ui=1 — migrated; documentation=1 — migrated
  - rismay (^rismay): engineering=1 — migrated; ui=1 — migrated; documentation=1 — migrated

### 2025-10-03T02:46:00Z — journal

- Summary: Adopted reusable telemetry components; Status Menu preview refined; detail moved to TauKit.
- Status Menu uses TauKit UptimeTelemetryDetailView via window helper.
- Preview: centered title, right‑aligned footer, info popover (targets, paths, App Group).
- Hover removed pending stable series selection behavior (request filed).
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-10-03T00:29:00Z — journal — Crash observed in background; triage request staged

- Summary: AppKit NSToolbar layout recursion crash (Catalyst, macOS 26.1) observed while app not active/minimized. Staged DocC request with full log.
- Exception: EXC_BREAKPOINT (SIGTRAP) during NSToolbarItemGroupView layout.
- Deep NSView layout recursion; symbolication pending.
- DocC request: tau-crash-2025-10-03 (resources include crash-5F5D140E.log).
- Next: Reproduce on Catalyst, audit constraints/toolbar grouping, add guards/tests.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry
- Link: [DocC request](code/.clia/docc/requests.docc/articles/tau-crash-2025-10-03.md)

### 2025-10-02T18:05:00Z — journal — Animation demo + push bug workaround

- Summary: Added Tau Animation Demo component; opened via window while MenuBarExtra push bug is investigated.
- Component: TauAnimationDemoComponent (ServiceView + FakeTauService)
- Navigation: openWindow(id: 'tau-animation-demo') from Status Menu
- Backlog: menu push navigation popover content invisible
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): ux=1 — migrated; engineering=1 — migrated
- Link: [Demo component](code/mono/apple/alphabeta/tau/mac-status-app/components/TauAnimationDemoComponent.swift)
- Link: [Backlog item](backlog/menu-push-navigation-popover-bug.md)

### 2025-10-02T00:23:02Z — journal — Uptime epic in motion — writers, aggregator, charts, and 24/5 toggle

- Summary: Seeded App Group minute snapshots in both apps; added aggregator + Swift Charts with stacked uptime/offline per day; network transitions are logged; SLO picker supports 24/5 vs 8/5.
- Status Menu: JSONL per-day writer under metrics/uptime/status-menu; snapshots include online flag.
- Tau app: parity writer + NWPathMonitor; logs network events under metrics/network/tau.
- Aggregator: daily scoring; last 5 business days; 24/5 default.
- UI: header KPIs (uptime %, offline minutes, last event) + stacked bars (uptime/offline).
- Single-instance: Info.plist LSMultipleInstancesProhibited across helper/app.
- Docs: Uptime and SLO DocC page; epic documented under mono requests.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): product=1 — migrated; design=1 — migrated; engineering=1 — migrated; documentation=1 — migrated

### 2025-09-27T00:27:05Z — spawn — Commissioned Tau

- Summary: Instantiated the founder persona to steer Tau's roadmap while staying hands-on with CommonShell-first engineering.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry
- Tags: spawn, product, engineering

### 2025-09-03 — journal — PublicLib – AGENCY
- 2025-09-03: Added DocC catalog (Getting Started, Services, Authentication, HTTP Requests). Documented end‑to‑end auth flow and request anatomy. Verified SwiftPM and Xcode workspace builds; 23 tests passed.
- 2025-09-03: Executed domain-service refactor aligning PublicLib to OmniBroker/TradierLib structure (Quote/Order/Activity/Positions/Profile/Auth/Services). Moved models into domain folders; split `PublicClient` into per-domain extensions; kept type and API names stable for source compatibility. Updated swift-format file list. Build verification should be done via Xcode workspace on macOS.
- 2025-09-03: Planned domain-service refactor to align PublicLib with OmniBroker/TradierLib structure (Quote/Order/Activity/Positions/Profile/Auth/Streaming). No behavioral changes expected; docs and tutorials to mirror TradierLib. Implementation deferred to a follow-up session.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:59Z — journal — Entry Template

- Summary: Seed: Initialized during PJM-SPRINT to complete the CLIA triad.
- Date:
- Context:
- Decision:
- Rationale:
- Impact:
- Follow-ups:
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:58Z — journal — Agency Log — Whisper Exit (Parent)

- Summary: > Document exit heuristics, thresholds, and audit requirements.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:57Z — journal — Entry Template

- Summary: Seed: Initialized during PJM-SPRINT to complete the CLIA triad.
- Date:
- Context:
- Decision:
- Rationale:
- Impact:
- Follow-ups:
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:56Z — journal — Agency Log — Note Linker (Parent)

- Summary: > Institutional memory for note-linking rules, schemas, and safeguards.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:55Z — journal — Entry Template

- Summary: Seed: Initialized during PJM-SPRINT to complete the CLIA triad.
- Date:
- Context:
- Decision:
- Rationale:
- Impact:
- Follow-ups:
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:54Z — journal — Agency Log — Strategy Auditor (Parent)

- Summary: > Record risk model assumptions, governance thresholds, and compliance interpretations.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:53Z — journal — Entry Template

- Summary: Seed: Initialized during PJM-SPRINT to complete the CLIA triad.
- Date:
- Context:
- Decision:
- Rationale:
- Impact:
- Follow-ups:
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:52Z — journal — Agency Log — Trade Journaler (Parent)

- Summary: > Institutional memory for journal schemas, reconciliation logic, and entity routing.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:51Z — journal — Entry Template

- Summary: Seed: Initialized during PJM-SPRINT to complete the CLIA triad.
- Date:
- Context:
- Decision:
- Rationale:
- Impact:
- Follow-ups:
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry

### 2025-09-02T23:59:50Z — journal — Agency Log — Market Summarizer (Parent)

- Summary: > Record decisions, data sources, formatting standards, and governance needs for EOD summaries.
- Participants: tau (^tau)
- Contributions:
  - tau (^tau): log=1 — legacy-entry
