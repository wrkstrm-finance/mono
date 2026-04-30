import Foundation

extension AlpacaClient {
  public func latestStockQuote(symbol: String, feed: String? = "iex") async throws -> AlpacaStockQuote {
    let response = try await send(try AlpacaLatestStockQuoteURLRequest(symbol: symbol, feed: feed))
    return response.quote
  }
}
