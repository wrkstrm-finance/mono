import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaActivityService: CommonActivityService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient

  public init(client: AlpacaClient, serviceType: ServiceType = .sandbox) {
    self.client = client
    self.serviceType = serviceType
  }

  public func history(
    for _: String,
    start: Date?,
    end: Date?,
    type: CommonHistoryEventType?
  ) async throws -> [CommonBrokerageActivityEventModel] {
    try await client.accountActivities(
      activityType: type?.alpacaActivityType,
      after: start,
      until: end
    ).map(commonActivity)
  }

  public func gainLoss(
    for _: String,
    page _: Int?,
    limit: Int?,
    sortBy: CommonGainLossSortBy?,
    sort: CommonSortDirection?,
    start: Date?,
    end: Date?,
    symbol: String?
  ) async throws -> [CommonBrokerageClosedPositionModel] {
    let fills = try await client.accountActivities(
      activityType: "FILL",
      after: start,
      until: end,
      pageSize: limit
    )
    let closed = closedPositions(from: fills, symbol: symbol)
    let sorted = sortClosedPositions(closed, sortBy: sortBy, sort: sort)
    guard let limit, limit > 0 else { return sorted }
    return Array(sorted.prefix(limit))
  }
}

func commonActivity(_ activity: AlpacaActivity) -> CommonBrokerageActivityEventModel {
  let trade: CommonBrokerageTradeEventModel?
  if activity.symbol != nil || activity.price != nil || activity.qty != nil {
    trade = CommonBrokerageTradeEventModel(
      commission: nil,
      description: activity.description,
      price: double(activity.price),
      quantity: double(activity.qty ?? activity.cumQty),
      symbol: activity.symbol,
      tradeType: activity.side ?? activity.type
    )
  } else {
    trade = nil
  }

  let ach: CommonBrokerageACHEventModel?
  if ["CSD", "CSW", "TRANS"].contains(activity.activityType ?? "") {
    ach = CommonBrokerageACHEventModel(
      description: activity.description,
      quantity: double(activity.netAmount)
    )
  } else {
    ach = nil
  }

  let transfer: CommonBrokerageTransferEventModel?
  if (activity.activityType ?? "").hasPrefix("ACAT") {
    transfer = CommonBrokerageTransferEventModel(
      description: activity.description,
      quantity: double(activity.qty ?? activity.netAmount)
    )
  } else {
    transfer = nil
  }

  return CommonBrokerageActivityEventModel(
    id: commonIntegerID(activity.id),
    date: activity.transactionTime ?? activity.date,
    type: activity.activityType ?? activity.type,
    amount: double(activity.netAmount) ?? signedTradeAmount(activity),
    trade: trade,
    ach: ach,
    transfer: transfer
  )
}

func signedTradeAmount(_ activity: AlpacaActivity) -> Double? {
  guard let price = double(activity.price), let quantity = double(activity.qty ?? activity.cumQty) else {
    return nil
  }
  let amount = price * quantity
  return activity.side == "sell" ? amount : -amount
}

func closedPositions(from activities: [AlpacaActivity], symbol requestedSymbol: String?) -> [CommonBrokerageClosedPositionModel] {
  struct Lot {
    var quantity: Double
    let price: Double
    let date: Date?
  }

  var lotsBySymbol: [String: [Lot]] = [:]
  var closed: [CommonBrokerageClosedPositionModel] = []

  let fills = activities
    .filter { activity in
      guard let symbol = activity.symbol else { return false }
      if let requestedSymbol, symbol.uppercased() != requestedSymbol.uppercased() {
        return false
      }
      return true
    }
    .sorted { ($0.transactionTime ?? $0.date ?? .distantPast) < ($1.transactionTime ?? $1.date ?? .distantPast) }

  for fill in fills {
    guard
      let symbol = fill.symbol,
      let quantity = double(fill.qty ?? fill.cumQty),
      let price = double(fill.price)
    else {
      continue
    }

    if fill.side == "buy" {
      lotsBySymbol[symbol, default: []].append(Lot(quantity: quantity, price: price, date: fill.transactionTime ?? fill.date))
      continue
    }

    guard fill.side == "sell" else { continue }
    var remaining = quantity
    var cost = 0.0
    var openedAt: Date?
    var symbolLots = lotsBySymbol[symbol, default: []]

    while remaining > 0, symbolLots.isEmpty == false {
      var lot = symbolLots.removeFirst()
      let closedQuantity = min(lot.quantity, remaining)
      cost += closedQuantity * lot.price
      remaining -= closedQuantity
      lot.quantity -= closedQuantity
      openedAt = openedAt ?? lot.date
      if lot.quantity > 0 {
        symbolLots.insert(lot, at: 0)
      }
    }

    lotsBySymbol[symbol] = symbolLots

    let closedQuantity = quantity - remaining
    guard closedQuantity > 0 else { continue }
    let proceeds = closedQuantity * price
    let realized = proceeds - cost
    closed.append(
      CommonBrokerageClosedPositionModel(
        symbol: symbol,
        quantity: closedQuantity,
        realizedPnl: realized,
        openDate: openedAt,
        closeDate: fill.transactionTime ?? fill.date,
        cost: cost,
        proceeds: proceeds,
        gainLossPercentage: cost == 0 ? nil : realized / cost,
        term: nil
      )
    )
  }

  return closed
}

func sortClosedPositions(
  _ positions: [CommonBrokerageClosedPositionModel],
  sortBy: CommonGainLossSortBy?,
  sort: CommonSortDirection?
) -> [CommonBrokerageClosedPositionModel] {
  let ascending = sort != .desc
  return positions.sorted { lhs, rhs in
    let lhsDate = sortBy == .openDate ? lhs.openDate : lhs.closeDate
    let rhsDate = sortBy == .openDate ? rhs.openDate : rhs.closeDate
    if ascending {
      return (lhsDate ?? .distantPast) < (rhsDate ?? .distantPast)
    }
    return (lhsDate ?? .distantPast) > (rhsDate ?? .distantPast)
  }
}

extension CommonHistoryEventType {
  var alpacaActivityType: String {
    switch self {
    case .trade:
      "FILL"
    case .ach:
      "TRANS"
    case .transfer:
      "ACATS"
    }
  }
}
