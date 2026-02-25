import ArgumentParser
import Foundation
import MarketSummarizer

@main
struct EODSummaryCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "eod-summary",
    abstract: "Generate an end‑of‑day market summary.",
    version: "0.1.0",
    subcommands: [Once.self, Serve.self],
    defaultSubcommand: Once.self
  )
}

struct CommonOptions: ParsableArguments {
  @Option(
    name: [.customLong("symbol"), .short], parsing: .upToNextOption, help: "Symbols to include.")
  var symbols: [String] = []

  @Option(name: .long, help: "Output format: text|json|md")
  var format: SummaryFormat = .text

  @Option(name: .long, help: "Write output to file (optional).")
  var output: String?
}

struct Once: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Run once and print/write summary.")

  @OptionGroup var options: CommonOptions

  func run() throws { try runOnce(options: options) }
}

struct Serve: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Run as a simple daemon (interval loop).")

  @OptionGroup var options: CommonOptions

  @Option(name: .long, help: "Interval seconds between runs (default 300).")
  var interval: UInt32 = 300

  func run() throws {
    // Simple loop; replace with SystemScheduler/SwiftDaemon when ready.
    while true {
      try runOnce(options: options)
      sleep(interval)
    }
  }
}

@discardableResult
private func runOnce(options: CommonOptions) throws -> String {
  let engine = MarketSummarizerEngine()
  let summary = engine.summarize(symbols: options.symbols)
  let rendered = engine.render(summary, as: options.format)
  if let path = options.output {
    do {
      try rendered.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
      FileHandle.standardError.write(Data("Wrote summary to \(path)\n".utf8))
    } catch {
      throw MarketSummarizerError.writeFailed("Failed writing to \(path): \(error)")
    }
  } else {
    print(rendered)
  }
  return rendered
}
