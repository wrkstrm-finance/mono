import Foundation

public enum AlpacaCommonAdapterError: Error, Sendable, Equatable {
  case unsupported(String)
  case missingData(String)
}
