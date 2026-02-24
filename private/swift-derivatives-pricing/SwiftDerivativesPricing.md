# SwiftDerivativesPricing – Codex Implementation Guide

Purpose-built Swift library for fast, numerically stable option pricing and Greeks, with portfolio‑level aggregation and “dollarized” risk for our theta‑harvest mandate. Production‑ready for macOS/iOS/visionOS targets, zero external deps, DocC documented, and CI‑benchmarked.

---

## 1) Scope and Non‑Goals

**In scope**

- Black–Scholes–Merton analytics with dividend yield
- Greeks: Δ, Γ, Θ, ϑ (vanna), charm (∂Δ/∂t), ν (vega), ρ, color (∂Γ/∂t)
- Implied volatility solver (Brent; safe brackets, monotonic)
- Dollarization helpers (× 100 × contracts) and per‑day conversions
- Strategy/portfolio aggregation, sleeve‑aware exposure summaries
- Stable numerics near expiry and for deep ITM/OTM
- SIMD‑friendly batch pricing; async APIs for UI responsiveness
- DocC, unit tests, micro‑benchmarks, SwiftFormat/SwiftLint gates

**Out of scope (v1)**

- American exercise, barriers, exotics
- Stochastic vol or local vol surfaces
- Full Monte Carlo/FD engines

---

## 2) Package Layout

```
SwiftDerivativesPricing/
├─ Package.swift
├─ Sources/
│  └─ SwiftDerivativesPricing/
│     ├─ Core/
│     │  ├─ Normal.swift          // φ, Φ with stable tails
│     │  ├─ BlackScholes.swift    // price, delta, gamma, theta, vega, rho
│     │  ├─ SecondOrder.swift     // charm, vanna, vomma, color (stable forms)
│     │  ├─ Dollarize.swift       // $ conversions, per-day conversions
│     │  └─ Types.swift           // OptionType, Params, Greeks structs
│     ├─ IV/
│     │  ├─ ImpliedVol.swift      // Brent + safe brackets
│     │  └─ SurfaceHooks.swift    // protocol for surfaces (stub)
│     ├─ Portfolio/
│     │  ├─ Aggregation.swift     // sum greeks per strategy / sleeve
│     │  └─ RiskLimits.swift      // tripwires (e.g., |sumCharm| threshold)
│     ├─ Concurrency/
│     │  └─ BatchPricing.swift    // async sequence/batch APIs
│     └─ Logging/
│        └─ PricingLog.swift      // CommonLog hooks (debug only)
├─ Tests/
│  ├─ PricingTests/
│  │  ├─ BlackScholesTests.swift
│  │  ├─ GreeksTests.swift
│  │  ├─ CharmStabilityTests.swift
│  │  ├─ ImpliedVolTests.swift
│  │  └─ DollarizeTests.swift
│  └─ Benchmarks/
│     └─ MicroBench.swift
└─ Docs.docc/                     // DocC articles, how‑tos, symbols
```

---

## 3) Public API (Swift 6.2)

```swift
public enum OptionType { case call, put }

public struct OptionParams: Sendable {
  public let spot: Double  // S > 0
  public let strike: Double  // K > 0
  public let rate: Double  // r, cont. annual (e.g. 0.045)
  public let dividend: Double  // q, cont. annual
  public let vol: Double  // σ as decimal (0.35)
  public let timeYears: Double  // T in years (DTE/365)
  public let type: OptionType
}

public struct Greeks: Sendable {
  public let price: Double
  public let delta: Double
  public let gamma: Double
  public let theta: Double  // per year
  public let vega: Double  // per 1.0 vol (100% move)
  public let rho: Double
  public let charm: Double  // ∂Δ/∂t per year
  public let vanna: Double
  public let vomma: Double
  public let color: Double
}

public enum Pricing {
  public static func blackScholes(_ p: OptionParams) -> Greeks
  public static func impliedVol(
    price target: Double, _ p: OptionParams,
    tol: Double = 1e-8, maxIter: Int = 100
  ) -> Double
}

public enum Dollarize {
  public static func perContract(_ x: Double, multiplier: Double = 100) -> Double
  public static func perPosition(_ x: Double, contracts: Int, multiplier: Double = 100) -> Double
  public static func perDayFromPerYear(_ x: Double, tradingDays: Double = 252) -> Double
  public static func charmDollarsPerDay(
    charmPerYear: Double, contracts: Int, multiplier: Double = 100, tradingDays: Double = 252
  ) -> Double
}

public struct StrategyExposure: Sendable {
  public let delta: Double
  public let gamma: Double
  public let thetaPerDay$: Double
  public let vegaPer1pctIV$: Double
  public let charmPerDay$: Double
}

public enum Portfolio {
  public static func aggregate(
    legs: [(greeks: Greeks, contracts: Int)],
    multiplier: Double = 100,
    tradingDays: Double = 252
  ) -> StrategyExposure

  public static func breachFlags(
    exposure: StrategyExposure,
    charmDailyLimit$: Double,
    thetaDailyTarget$: ClosedRange<Double>
  ) -> [String]
}
```

---

## 4) Numerics and Stability

- **Normal PDF/CDF**: hand‑rolled `φ`, `Φ` with erfc for tails, no `pow`.
- **Clamps**: `T = max(T, 1e-12)`, denom guards like `max(σ√T, 1e-18)`.
- **Analytic second‑order**:
  - Charm uses a rearrangement that avoids `T→0` blowups and subtraction loss.
  - Provide unit tests comparing analytic charm to a tiny symmetric difference for sanity.

- **Theta units**: expose per‑year internally; provide helpers for per‑day conversions.
- **Vega units**: per 1.00 IV move; document conversion for 1% IV as `vega * 0.01`.
- **Implied Vol**: Brent on a monotone price(σ), bracket using low/high σ with bail‑outs:
  - Start `σ∈[1e-6, 6.0]`
  - Tighten with price sign; terminate on `abs(f) < tol` or `iter == maxIter`.

---

## 5) Performance Plan

- Mark hot math `@inline(__always)`.
- Avoid allocations; pass simple value types.
- Batch APIs accept arrays of `OptionParams` and return arrays of `Greeks`.
- Provide `Task`‑based async pricing to keep UI responsive for 1k+ legs.
- Micro‑benchmarks: target ≥ 5M BS evaluations/sec on Apple silicon release build.

---

## 6) Compliance, CFO/COO Hooks

- Dollarization helpers return **real account swings**:
  - Delta dollars per \$1 move = `Δ × 100 × contracts`.
  - Theta dollars per **day** = `Θ_perYear / 252 × 100 × contracts`.
  - Vega dollars per **1% IV** = `vega × 0.01 × 100 × contracts`.
  - Charm dollars per **day** = `charm_perYear / 252 × 100 × contracts`.

- Portfolio tripwires:
  - `abs(sumCharmPerDay$)` guard to prevent delta drift from time passage alone.
  - Theta daily range aligned to payroll cadence for smoother P\&L.

- Logging hooks compile‑time gated:
  - `#if canImport(CommonLog)` then `import CommonLog` and use `Log.verbose` for diagnostics.
  - Note: load PEMs with `Data(contentsOf:)` per our platform guidance.

---

## 7) Implementation Details

### 7.1 Normal

```swift
@inline(__always) internal func normPDF(_ x: Double) -> Double {
  0.3989422804014327 * exp(-0.5 * x * x)
}
@inline(__always) internal func normCDF(_ x: Double) -> Double {
  0.5 * erfc(-x / .sqrt2)
}
```

### 7.2 d1/d2 with carry

```swift
@inline(__always)
internal func d1d2(S: Double, K: Double, r: Double, q: Double, σ: Double, T: Double) -> (
  Double, Double
) {
  let Tp = max(T, 1e-12)
  let b = r - q
  let v = σ * sqrt(Tp)
  let d1 = (log(S / K) + (b + 0.5 * σ * σ) * Tp) / max(v, 1e-18)
  return (d1, d1 - v)
}
```

### 7.3 Price and Greeks (selected)

- Provide call/put price and primary Greeks in closed form.
- **Charm (analytic)**, stable form:

```swift
@inline(__always)
internal func charm(
  S: Double, K: Double, r: Double, q: Double, σ: Double, T: Double, type: OptionType
) -> Double {
  let Tp = max(T, 1e-12)
  let (d1, d2) = d1d2(S: S, K: K, r: r, q: q, σ: σ, T: Tp)
  let carry = exp(-q * Tp)
  let φd1 = normPDF(d1)
  let sqrtT = sqrt(Tp)
  let common = carry * φd1 * ((2 * (r - q) * Tp - d2 * σ * sqrtT) / (2 * Tp))
  switch type {
  case .call: return -q * carry * normCDF(d1) + common
  case .put: return q * carry * normCDF(-d1) - common
  }
}
```

- Implement vanna, vomma, color in similarly stable rearrangements.

### 7.4 Implied Vol (Brent)

- Function signature:

```swift
public static func impliedVol(
  price target: Double, _ p: OptionParams,
  tol: Double = 1e-8, maxIter: Int = 100
) -> Double
```

- Behavior:
  - Reject arbitrage‑infeasible targets with a precise error.
  - Clamp output within `[1e-6, 6.0]`.
  - Strict monotonicity check per iteration.

---

## 8) Strategy and Portfolio Aggregation

```swift
public static func aggregate(
  legs: [(greeks: Greeks, contracts: Int)],
  multiplier: Double = 100, tradingDays: Double = 252
) -> StrategyExposure {
  // Sum unit Greeks then dollarize where appropriate
}
```

- Expose:
  - `thetaPerDay$` and `charmPerDay$` for cadence planning.
  - `vegaPer1pctIV$` to quantify IV shock sensitivity.

- Add `breachFlags` with rules such as:
  - `"CharmDailyLimitBreach"` when `abs(charmPerDay$) > limit`.
  - `"ThetaBelowTarget"` / `"ThetaAboveTarget"` if outside desired range.

---

## 9) DocC & Developer Experience

- `Docs.docc` articles:
  - **GettingStarted.md**: pricing one leg, dollarizing, aggregating.
  - **Numerics.md**: stability choices, units, conversions.
  - **RiskTripwires.md**: how to set charm/theta guards per sleeve.
  - **IVSolver.md**: convergence behavior and errors.

- DocC symbols documented for all public APIs with parameter semantics.
- Xcode scheme `SwiftDerivativesPricing-Package` builds docs.

---

## 10) Testing & Bench

- **Golden tests**: compare Greeks against reputable references at grid points:
  - Moneyness S/K ∈ {0.7, 1.0, 1.3}, T ∈ {1/365, 7/365, 0.25, 1.0}, σ ∈ {0.1, 0.5}

- **Stability tests**:
  - `T → 0` and deep ITM/OTM, ensure finite outputs and small relative error vs numeric diff.

- **IV solver tests**:
  - Known price→σ pairs, bracketing edge cases.

- **Benchmarks**:
  - 1e6 BS evals: report ns/op on CI; budget regression guard ±5%.

---

## 11) CI, Linting, Versioning

- CI steps:
  1. `swift build -c release`
  2. Unit tests + benches
  3. SwiftFormat + SwiftLint (keep your precious two‑space indents, trailing commas)
  4. DocC build

- SemVer:
  - v0.1.0 initial public surface
  - v0.2.x adds second‑order greeks
  - v0.3.x async batches and portfolio aggregation

- Platforms:
  - iOS 16+, macOS 13+, visionOS 1+, Linux (for CLI/agents)

---

## 12) Usage Examples

### Price and Greeks for one leg

```swift
let p = OptionParams(
  spot: 430, strike: 430, rate: 0.045, dividend: 0.0,
  vol: 0.35, timeYears: 7.0 / 365.0, type: .call
)
let g = Pricing.blackScholes(p)
// Dollarize vega for a 1% IV move on 10 contracts:
let vega1pct$ = Dollarize.perPosition(g.vega * 0.01, contracts: 10)
```

### Charm drift per day (dollars)

```swift
let charmDay$ = Dollarize.charmDollarsPerDay(
  charmPerYear: g.charm, contracts: -25  // short 25
)
```

### Aggregate a double diagonal sleeve

```swift
let legs: [(Greeks, Int)] = [(gShort1, -10), (gShort2, -10), (gLong1, 5), (gLong2, 5)]
let exposure = Portfolio.aggregate(legs: legs)
let flags = Portfolio.breachFlags(
  exposure: exposure,
  charmDailyLimit$: 1500,  // sleeve policy
  thetaDailyTarget$: 500...2500
)
```

---

## 13) Integration Notes

- UI updates: compute in a task group then publish `StrategyExposure` via Combine.
- Journaling: persist exposure snapshots to Notion with timestamps for governance.
- Limits: drive WhisperExit rules when charm or theta trip wires fire.

---

## 14) Coding Standards

- Swift 6.2 syntax, no unnecessary `return`, value semantics by default.
- Prefer `@inline(__always)` for hot paths.
- No `pow` for small integer powers; use `x*x` etc.
- Document all public APIs with units and economic meaning.

---

## 15) Deliverables Checklist (for Codex)

- [ ] Package skeleton and SPM manifest
- [ ] Core math with tests for Δ, Γ, Θ, ν, ρ
- [ ] Second‑order set: charm, vanna, vomma, color (+ tests)
- [ ] Implied vol solver with benchmarks and failure modes
- [ ] Dollarization and aggregation modules
- [ ] DocC with 4 articles and symbol docs
- [ ] CI pipeline, SwiftFormat/SwiftLint configs
- [ ] Micro‑bench with regression thresholds
- [ ] Sample app playground demonstrating UI usage

Build it clean, prove it with tests, and keep numerics polite near expiry. If charm starts freelancing, your roll logic will catch it before the P\&L does.
