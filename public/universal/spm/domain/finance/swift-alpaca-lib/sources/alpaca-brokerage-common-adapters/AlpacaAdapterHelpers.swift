import Foundation

func double(_ value: String?) -> Double? {
  guard let value else { return nil }
  return Double(value)
}

func decimalString(_ value: Double) -> String {
  String(format: "%.8g", value)
}

func commonIntegerID(_ value: String) -> Int {
  var accumulator: UInt64 = 0
  for scalar in value.unicodeScalars {
    accumulator = accumulator &* 31 &+ UInt64(scalar.value)
  }
  return Int(accumulator & 0x7fff_ffff)
}

func unixSeconds(_ date: Date) -> Int {
  Int(date.timeIntervalSince1970)
}

func monthDateRange(month: Int, year: Int) -> (start: Date, end: Date) {
  var components = DateComponents()
  components.calendar = Calendar(identifier: .gregorian)
  components.timeZone = TimeZone(secondsFromGMT: 0)
  components.year = year
  components.month = month
  components.day = 1
  let start = components.date ?? Date(timeIntervalSince1970: 0)
  let end = components.calendar?.date(
    byAdding: DateComponents(month: 1, day: -1),
    to: start
  ) ?? start
  return (start, end)
}

func alpacaDate(_ value: String) -> Date? {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.date(from: value)
}

func alpacaDateString(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.string(from: date)
}

func alpacaDateTimeString(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}

func alpacaDateTime(date: String, time: String) -> Date? {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(identifier: "America/New_York")
  formatter.dateFormat = "yyyy-MM-dd HH:mm"
  return formatter.date(from: "\(date) \(time)")
}
