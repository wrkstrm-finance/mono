import Foundation
import TradierLib
import CommonLog

@main
struct TradierCLI {
  static func main() async throws {
    let service = Tradier.CodableService(environment: Tradier.HTTPSProdEnvironment())
    do {
      let quote = try await service.quote(for: "AAPL")
      Log.verbose("AAPL: \(quote.description)")
      let history = try await service.accountHistory(for: "6YA13177")
      Log.verbose("History: \(history)")
    } catch {
      Log.verbose("Failed to fetch quote: \(error)")
    }
  }
}
