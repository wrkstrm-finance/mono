# wrkstrm-finance

Wrkstrm Finance is a small, composable set of finance primitives (brokers, market data, execution) designed to be:

- **Readable**: boring APIs, explicit naming, predictable behavior.
- **Testable**: protocol-first boundaries; deterministic adapters.
- **Composable**: small packages that layer cleanly.

## Repository shape

This repo is the **mono hub** for the wrkstrm-finance org.

- `public/readmes/public-readme` → shared org-level README / issue templates (submodule)
- `public/spm/universal/domain/finance/*` → Swift packages (submodules)

## Brand voice (docs + READMEs)

Write like a careful engineer explaining a tool to another careful engineer.

- Prefer **plain language** over marketing.
- State **constraints** and **tradeoffs** early.
- Avoid promises about coverage, broker support, or timelines.
- Use short sections, concrete examples, and stable terminology.

### Vocabulary

- **Broker**: external service/provider (Tradier, etc.)
- **Adapter**: our integration layer around a broker API
- **Domain model**: types we own and keep stable

## DocC site direction (skeleton)

Primary audiences:

1. Builders integrating a broker into an app or service.
2. Maintainers adding new broker adapters.

Proposed information architecture:

- **Overview**
  - What this org is (and isn’t)
  - Package map
- **Getting Started**
  - Choose a broker
  - Authenticate (where applicable)
  - Fetch quotes / place an order (end-to-end snippet)
- **Concepts**
  - Accounts, positions, orders, fills
  - Market data vs trading
  - Error model + retries
- **Adapters**
  - Per-broker capabilities matrix
  - Rate limits, sandbox behavior
- **Contributing**
  - Adding a broker package
  - Testing strategy
  - Release/versioning expectations

## Next small steps

- Add a tiny **capabilities matrix** to each broker adapter package.
- Establish a shared **error taxonomy** (retryable vs terminal).
- Add one canonical **end-to-end example** (paper trading / sandbox if available).
