# Tau Expertise

Welcome. This catalog captures practical engineering learnings from Tau’s
day‑to‑day work across the app family. Entries prefer the smallest useful
artifact: concise rationale, concrete paths, and acceptance criteria.

- See: Uptime and Online telemetry — multi‑target design and UI
  - <doc:uptime-telemetry-today>
  - <doc:uptime-telemetry-bugs-and-fixes>
  - <doc:code-recipes>

## Recent Work

- Diagnosed CodeSwiftly DocC preview routing, removed the baseUrl override for
  /documentation/<slug> previews, and rebuilt the mac app to restore local rendering.
- Expanded roundup-report CLI for executive product roundups (coverage metrics, audits, owned
  library filters, git tag cadence) and regenerated Tau/Hack-Nu/CodeSwiftly DocC bundles.

## Preview Locally

```bash
xcrun docc preview \
  .clia/agents/tau/expertise.docc \
  --fallback-display-name "Tau Expertise" \
  --fallback-bundle-identifier "me.rismay.tau.expertise" \
  --fallback-bundle-version "1.0.0" \
  --port 8085
```
