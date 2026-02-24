import CommonLog

extension Log {
  public static let tastyTrade: Log = .init(
    system: "TastyTradeLib",
    category: "TastyTrade",
    maxExposureLevel: .trace,
  )
}
