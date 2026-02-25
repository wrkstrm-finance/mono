# TastyTradeLib

Prototype Swift package for interacting with Tastytrade APIs. The library focuses on account management,
order routing, and options data retrieval while adhering to Wrkstrm coding standards.

The client uses WrkstrmFoundation for networking scaffolding and CommonLog for runtime diagnostics.
This outline is provided for feasibility review and does not yet implement network calls.

## JSON key mapping: Do/Don’t

- Do map keys explicitly with `CodingKeys`.

```swift
struct Position: Decodable {
  let costBasis: Double
  enum CodingKeys: String, CodingKey { case costBasis = "cost_basis" }
}
```

- Don’t use `.convertFromSnakeCase` / `.convertToSnakeCase` on decoders/encoders.

See: ../../../../WrkstrmFoundation/Sources/WrkstrmFoundation/Documentation.docc/AvoidSnakeCaseKeyStrategies.md
