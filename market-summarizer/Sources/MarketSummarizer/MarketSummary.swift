import ArgumentParser
import Foundation

public struct MarketSummary: Sendable, Codable, Equatable {
  public struct Highlight: Sendable, Codable, Equatable {
    public let title: String
    public let details: String?

    public init(title: String, details: String? = nil) {
      self.title = title
      self.details = details
    }
  }

  public let date: String
  public let symbols: [String]
  public let highlights: [Highlight]

  public init(date: String, symbols: [String], highlights: [Highlight]) {
    self.date = date
    self.symbols = symbols
    self.highlights = highlights
  }
}

public enum SummaryFormat: String, Codable, CaseIterable {
  case text
  case json
  case md
}

extension SummaryFormat: ExpressibleByArgument {}

public enum MarketSummarizerError: Error {
  case writeFailed(String)
}

public struct MarketSummarizerEngine {
  public init() {}

  public func summarize(
    date: Date = .init(),
    symbols: [String]
  ) -> MarketSummary {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withFullDate]
    let dateString = iso.string(from: date)

    // Placeholder logic; real implementation will analyze IV, flow, sectors.
    let bullets: [MarketSummary.Highlight] =
      symbols.isEmpty
      ? [
        .init(title: "No symbols specified", details: "Add --symbol to focus highlights.")
      ]
      : symbols.map { sym in
        .init(title: "Summary pending for \(sym)", details: "Unusual flow / IV shift analysis TBD")
      }

    return MarketSummary(date: dateString, symbols: symbols, highlights: bullets)
  }

  public func render(_ summary: MarketSummary, as format: SummaryFormat) -> String {
    switch format {
    case .json:
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys]
      return (try? String(data: enc.encode(summary), encoding: .utf8)) ?? "{}"
    case .text:
      return renderText(summary)
    case .md:
      return renderMarkdown(summary)
    }
  }

  private func renderText(_ s: MarketSummary) -> String {
    var out: [String] = []
    out.append("EOD Summary — \(s.date)")
    if !s.symbols.isEmpty { out.append("Symbols: \(s.symbols.joined(separator: ", "))") }
    for h in s.highlights { out.append("- \(h.title)" + (h.details.map { " — \($0)" } ?? "")) }
    return out.joined(separator: "\n")
  }

  private func renderMarkdown(_ s: MarketSummary) -> String {
    var out: [String] = []
    out.append("# End of Day — \(s.date)")
    if !s.symbols.isEmpty { out.append("_Symbols_: \(s.symbols.joined(separator: ", "))") }
    out.append("")
    out.append("## Highlights")
    for h in s.highlights { out.append("- \(h.title)" + (h.details.map { ": \($0)" } ?? "")) }
    return out.joined(separator: "\n")
  }
}
