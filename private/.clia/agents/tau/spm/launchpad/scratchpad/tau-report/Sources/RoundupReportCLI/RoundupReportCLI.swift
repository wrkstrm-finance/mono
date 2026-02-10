import ArgumentParser
import CommonShell
import Foundation

@main
struct RoundupReportCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "roundup-report",
    abstract: "Executive product roundup reporting tools.",
    subcommands: [
      Scan.self,
      Extract.self,
      Libraries.self,
      Summarize.self,
      Render.self,
      Audit.self,
    ],
    defaultSubcommand: Scan.self,
    helpNames: .shortAndLong
  )

  func run() async throws {
    throw ValidationError("Select a subcommand. Run with --help for options.")
  }
}

struct Scan: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "scan",
    abstract: "Scan for product sources and emit a manifest."
  )

  @Option(help: "Root path to scan.")
  var rootPath: String = "."

  @Option(help: "Product root path to scan for markdown sources.")
  var productRootPath: String = ""

  @Option(help: "DocC bundle path to scan. Pass empty string to skip.")
  var doccRootPath: String = ""

  @Option(parsing: .upToNextOption, help: "Additional library paths to include in the manifest.")
  var libraryPaths: [String] = []

  @Option(parsing: .upToNextOption, help: "Only include sources that match any of these substrings.")
  var sourcesAllowlist: [String] = []

  @Option(parsing: .upToNextOption, help: "Exclude sources that match any of these substrings.")
  var sourcesDenylist: [String] = []

  @Option(help: "Output path for the manifest JSON.")
  var outputPath: String = ".clia/tmp/roundup-report-manifest.json"

  func run() async throws {
    if productRootPath.isEmpty {
      throw ValidationError("Provide --product-root-path for the product sources.")
    }
    let scanner = RoundupReportScanner(
      rootPath: rootPath,
      productRootPath: productRootPath,
      doccRootPath: doccRootPath,
      libraryPaths: libraryPaths,
      sourcesAllowlist: sourcesAllowlist,
      sourcesDenylist: sourcesDenylist
    )
    let manifest = try scanner.scan()
    try RoundupReportJSONWriter.write(manifest, to: outputPath)
    print("[roundup-report scan] root=\(rootPath) sources=\(manifest.sources.count)")
    print(outputPath)
  }
}

struct Extract: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "extract",
    abstract: "Extract dated events into a year/week index."
  )

  @Option(help: "Path to a manifest JSON.")
  var manifestPath: String = ".clia/tmp/roundup-report-manifest.json"

  @Option(help: "Year to extract.")
  var year: Int = 2025

  @Option(help: "Output path for the events JSON.")
  var outputPath: String = ".clia/tmp/roundup-report-events.json"

  @Flag(help: "Include git history events.")
  var includeGit: Bool = false

  @Flag(help: "Include git tag events for release cadence summaries.")
  var includeGitTags: Bool = false

  @Option(help: "Git repo root path for history extraction.")
  var gitRootPath: String = "."

  @Option(help: "Git paths to scan for commits (repeat for multiple paths).")
  var gitPaths: [String] = []

  func run() async throws {
    let manifest = try RoundupReportJSONWriter.read(RoundupReportManifest.self, from: manifestPath)
    if includeGit && gitPaths.isEmpty {
      throw ValidationError("Provide --git-paths when --include-git is set.")
    }
    let extractor = RoundupReportExtractor(year: year)
    let events = try await extractor.extract(
      from: manifest,
      includeGit: includeGit,
      includeGitTags: includeGitTags,
      gitRootPath: gitRootPath,
      gitPaths: gitPaths
    )
    try RoundupReportJSONWriter.write(events, to: outputPath)
    print("[roundup-report extract] events=\(events.events.count) year=\(year)")
    print(outputPath)
  }
}

struct Libraries: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "libraries",
    abstract: "Map product imports to package histories."
  )

  @Option(help: "Source root to scan for imports.")
  var sourceRootPath: String = ""

  @Option(help: "SPM root to search for packages.")
  var spmRootPath: String = ""

  @Option(help: "Additional roots to search for Package.swift (repeat for multiple).")
  var packageSearchRoots: [String] = []

  @Option(help: "Owned package roots to include when listing library changes (repeat for multiple).")
  var ownedPackageRoots: [String] = []

  @Option(help: "Roots to scan for owned SwiftPM targets (repeat for multiple).")
  var ownedTargetRoots: [String] = []

  @Option(help: "Repo root for git log scans.")
  var repoRootPath: String = "."

  @Option(help: "Year to scan for library changes.")
  var year: Int = 2025

  @Option(help: "Output path for the libraries JSON.")
  var outputPath: String = ".clia/tmp/roundup-report-libraries.json"

  func run() async throws {
    if sourceRootPath.isEmpty {
      throw ValidationError("Provide --source-root-path for the imports scan.")
    }
    if spmRootPath.isEmpty {
      throw ValidationError("Provide --spm-root-path for package discovery.")
    }
    let mapper = RoundupReportLibraryMapper(
      sourceRootPath: sourceRootPath,
      spmRootPath: spmRootPath,
      packageSearchRoots: packageSearchRoots,
      ownedPackageRoots: ownedPackageRoots,
      ownedTargetRoots: ownedTargetRoots,
      repoRootPath: repoRootPath,
      year: year
    )
    let report = try await mapper.buildReport()
    try RoundupReportJSONWriter.write(report, to: outputPath)
    print("[roundup-report libraries] libraries=\(report.libraries.count) year=\(year)")
    print(outputPath)
  }
}

struct Summarize: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "summarize",
    abstract: "Generate executive summaries for DocC pages."
  )

  @Option(help: "Events JSON path.")
  var eventsPath: String = ".clia/tmp/roundup-report-events.json"

  @Option(help: "Libraries JSON path.")
  var librariesPath: String = ".clia/tmp/roundup-report-libraries.json"

  @Option(help: "Output path for the summary JSON.")
  var outputPath: String = ".clia/tmp/roundup-report-summary.json"

  func run() async throws {
    let events = try RoundupReportJSONWriter.read(RoundupReportEvents.self, from: eventsPath)
    let libraries = try RoundupReportJSONWriter.read(RoundupReportLibraries.self, from: librariesPath)
    let summarizer = RoundupReportSummarizer(events: events, libraries: libraries)
    let summary = summarizer.buildSummary()
    try RoundupReportJSONWriter.write(summary, to: outputPath)
    print("[roundup-report summarize] weeks=\(summary.weekSummaries.count) months=\(summary.monthSummaries.count)")
    print(outputPath)
  }
}

struct Render: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "render",
    abstract: "Render DocC year/month/week pages from extracted data."
  )

  @Option(help: "Summary JSON path.")
  var summaryPath: String = ".clia/tmp/roundup-report-summary.json"

  @Option(help: "DocC output directory.")
  var outputPath: String = ""

  @Option(help: "Product display name for headings.")
  var productName: String = ""

  @Option(help: "Product slug for filenames and DocC links.")
  var productSlug: String = ""

  func run() async throws {
    if productName.isEmpty {
      throw ValidationError("Provide --product-name for DocC headings.")
    }
    if outputPath.isEmpty {
      throw ValidationError("Provide --output-path for DocC output.")
    }
    let summary = try RoundupReportJSONWriter.read(RoundupReportSummary.self, from: summaryPath)
    let slug = productSlug.isEmpty ? RoundupReportRenderer.slugify(productName) : productSlug
    let renderer = RoundupReportRenderer(
      summary: summary,
      outputPath: outputPath,
      productName: productName,
      productSlug: slug
    )
    try renderer.render()
    print("[roundup-report render] output=\(outputPath)")
  }
}

struct Audit: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "audit",
    abstract: "Audit DocC output for completeness and ordering."
  )

  @Option(help: "DocC root to audit.")
  var doccRootPath: String = ""

  func run() async throws {
    if doccRootPath.isEmpty {
      throw ValidationError("Provide --docc-root-path to audit.")
    }
    let auditor = RoundupReportAuditor(doccRootPath: doccRootPath)
    let report = try auditor.run()
    print("[roundup-report audit] docc=\(doccRootPath)")
    print("Broken doc links: \(report.brokenDocLinks.count)")
    for broken in report.brokenDocLinks {
      print("- \(broken)")
    }
    print("Week pages missing day sections: \(report.weekPagesMissingDays.count)")
    for page in report.weekPagesMissingDays {
      print("- \(page)")
    }
    print("Missing week pages: \(report.missingWeekPages.count)")
    for page in report.missingWeekPages {
      print("- \(page)")
    }
  }
}

struct RoundupReportManifest: Codable {
  let rootPath: String
  let generatedAt: Date
  let sources: [RoundupReportSource]
}

struct RoundupReportSource: Codable {
  let path: String
  let type: String
  let notes: String?
}

struct RoundupReportEvents: Codable {
  let year: Int
  let generatedAt: Date
  let events: [RoundupReportEvent]
  let releases: [RoundupReportRelease]
}

struct RoundupReportEvent: Codable {
  let date: String
  let isoWeek: Int
  let summary: String
  let sourcePath: String
  let changedFiles: [String]?
}

struct RoundupReportLibraries: Codable {
  let year: Int
  let generatedAt: Date
  let libraries: [RoundupReportLibrary]
}

struct RoundupReportLibrary: Codable {
  let moduleName: String
  let packagePaths: [String]
  let weeks: [Int]
  let notes: String?
}

struct RoundupReportRelease: Codable {
  let date: String
  let tag: String
}

struct RoundupReportSummary: Codable {
  let year: Int
  let generatedAt: Date
  let dataCoverage: RoundupReportDataCoverage
  let releases: [RoundupReportRelease]
  let keyResults: [String]
  let misses: [String]
  let backlog: [String]
  let monthSummaries: [RoundupReportMonthSummary]
  let weekSummaries: [RoundupReportWeekSummary]
}

struct RoundupReportDataCoverage: Codable {
  let sourcesCount: Int
  let weeksInYear: Int
  let weeksWithEvents: Int
  let weeksWithLibraries: Int
  let percentWeeksWithEvents: Double
  let percentWeeksWithLibraries: Double
}

struct RoundupReportMonthSummary: Codable {
  let month: String
  let monthName: String
  let weeks: [RoundupReportWeekSummary]
  let synopsis: String
}

struct RoundupReportWeekSummary: Codable {
  let isoWeek: Int
  let weekRange: String
  let month: String
  let synopsis: String
  let events: [RoundupReportEvent]
  let libraries: [String]
}

final class RoundupReportScanner {
  private let rootURL: URL
  private let productRootURL: URL
  private let doccRootURL: URL?
  private let libraryPaths: [String]
  private let sourcesAllowlist: [String]
  private let sourcesDenylist: [String]
  private let fileManager: FileManager = .default

  init(
    rootPath: String,
    productRootPath: String,
    doccRootPath: String,
    libraryPaths: [String],
    sourcesAllowlist: [String],
    sourcesDenylist: [String]
  ) {
    self.rootURL = URL(fileURLWithPath: rootPath)
    self.productRootURL = RoundupReportScanner.resolveURL(rootURL: rootURL, path: productRootPath)
    if doccRootPath.isEmpty {
      self.doccRootURL = nil
    } else {
      self.doccRootURL = RoundupReportScanner.resolveURL(rootURL: rootURL, path: doccRootPath)
    }
    self.libraryPaths = libraryPaths
    self.sourcesAllowlist = sourcesAllowlist
    self.sourcesDenylist = sourcesDenylist
  }

  func scan() throws -> RoundupReportManifest {
    var sources: [RoundupReportSource] = []
    sources.append(contentsOf: try productDocs())
    sources.append(contentsOf: try testingNotes())
    sources.append(contentsOf: try doccSources())
    sources.append(contentsOf: try librarySources())

    let filteredSources = sources
      .filter { shouldIncludeSource($0.path) }

    let manifest = RoundupReportManifest(
      rootPath: rootURL.path,
      generatedAt: Date(),
      sources: filteredSources.sorted { $0.path < $1.path }
    )
    return manifest
  }

  private func testingNotes() throws -> [RoundupReportSource] {
    let testingURL = productRootURL.appendingPathComponent("TestingNotes")
    guard fileManager.fileExists(atPath: testingURL.path) else { return [] }
    let files = try fileManager.contentsOfDirectory(at: testingURL, includingPropertiesForKeys: nil)
    return files
      .filter { $0.pathExtension == "md" }
      .map { RoundupReportSource(path: $0.path, type: "testing-notes", notes: nil) }
  }

  private func productDocs() throws -> [RoundupReportSource] {
    guard fileManager.fileExists(atPath: productRootURL.path) else { return [] }
    guard let files = fileManager.enumerator(at: productRootURL, includingPropertiesForKeys: nil) else {
      return []
    }
    var sources: [RoundupReportSource] = []
    for case let fileURL as URL in files {
      guard fileURL.pathExtension == "md" else { continue }
      if shouldSkipSourcePath(fileURL.path) { continue }
      sources.append(RoundupReportSource(path: fileURL.path, type: "product-doc", notes: nil))
    }
    return sources
  }

  private func doccSources() throws -> [RoundupReportSource] {
    guard let doccURL = doccRootURL else { return [] }
    guard fileManager.fileExists(atPath: doccURL.path) else { return [] }
    guard let files = fileManager.enumerator(at: doccURL, includingPropertiesForKeys: nil) else {
      return []
    }
    var sources: [RoundupReportSource] = []
    for case let fileURL as URL in files {
      guard fileURL.pathExtension == "md" else { continue }
      if shouldSkipSourcePath(fileURL.path) { continue }
      sources.append(RoundupReportSource(path: fileURL.path, type: "docc", notes: nil))
    }
    return sources
  }

  private func librarySources() throws -> [RoundupReportSource] {
    let uniquePaths = Array(Set(libraryPaths)).sorted()
    return uniquePaths.map { path in
      RoundupReportSource(
        path: RoundupReportScanner.resolveURL(rootURL: rootURL, path: path).path,
        type: "library",
        notes: nil
      )
    }
  }

  private func shouldSkipSourcePath(_ path: String) -> Bool {
    return path.contains("/.build/")
      || path.contains("/.clia/tmp/")
      || path.contains("/SourcePackages/")
      || path.contains("/derived/")
  }

  private func shouldIncludeSource(_ path: String) -> Bool {
    let allowlist = sourcesAllowlist.filter { !$0.isEmpty }
    if !allowlist.isEmpty && !allowlist.contains(where: { path.contains($0) }) {
      return false
    }
    let denylist = sourcesDenylist.filter { !$0.isEmpty }
    if denylist.contains(where: { path.contains($0) }) {
      return false
    }
    return true
  }

  private static func resolveURL(rootURL: URL, path: String) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path)
    }
    return rootURL.appendingPathComponent(path)
  }
}

final class RoundupReportExtractor {
  private let year: Int
  private let calendar: Calendar

  init(year: Int) {
    self.year = year
    self.calendar = Calendar(identifier: .iso8601)
  }

  func extract(
    from manifest: RoundupReportManifest,
    includeGit: Bool,
    includeGitTags: Bool,
    gitRootPath: String,
    gitPaths: [String]
  ) async throws -> RoundupReportEvents {
    var events: [RoundupReportEvent] = []
    for source in manifest.sources {
      if source.type == "library" {
        continue
      }
      let fileURL = URL(fileURLWithPath: source.path)
      guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      events.append(contentsOf: extractEvents(from: contents, sourcePath: source.path))
    }
    if includeGit {
      let gitEvents = try await extractGitEvents(rootPath: gitRootPath, paths: gitPaths)
      events.append(contentsOf: gitEvents)
    }
    let releases = includeGitTags ? try await extractGitTags(rootPath: gitRootPath) : []
    let normalizedEvents = normalizeEvents(events)
    let sortedEvents = normalizedEvents.sorted { lhs, rhs in
      if lhs.date == rhs.date {
        return lhs.sourcePath < rhs.sourcePath
      }
      return lhs.date < rhs.date
    }
    return RoundupReportEvents(
      year: year,
      generatedAt: Date(),
      events: sortedEvents,
      releases: releases
    )
  }

  private func extractEvents(from contents: String, sourcePath: String) -> [RoundupReportEvent] {
    var events: [RoundupReportEvent] = []
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if let bulletEvent = parseBulletEvent(from: trimmed, sourcePath: sourcePath) {
        events.append(bulletEvent)
      } else if let updatedEvent = parseLastUpdated(from: trimmed, sourcePath: sourcePath) {
        events.append(updatedEvent)
      }
    }
    return events
  }

  private func normalizeEvents(_ events: [RoundupReportEvent]) -> [RoundupReportEvent] {
    var seen: Set<String> = []
    var normalized: [RoundupReportEvent] = []
    for event in events {
      let summary = normalizeSummary(event.summary)
      if summary.isEmpty {
        continue
      }
      let key = "\(event.date)|\(summary)"
      guard !seen.contains(key) else { continue }
      seen.insert(key)
      normalized.append(
        RoundupReportEvent(
          date: event.date,
          isoWeek: event.isoWeek,
          summary: summary,
          sourcePath: event.sourcePath,
          changedFiles: event.changedFiles
        )
      )
    }
    return normalized
  }

  private func normalizeSummary(_ summary: String) -> String {
    let collapsed = summary.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    if isTruncatedSummary(cleaned) {
      return ""
    }
    return cleaned
  }

  private func isTruncatedSummary(_ summary: String) -> Bool {
    let lowered = summary.lowercased()
    if lowered.hasSuffix("...") || lowered.hasSuffix("…") || lowered.hasSuffix("—") || lowered.hasSuffix("-") {
      return true
    }
    let tailWords = [" a", " an", " and", " for", " in", " of", " on", " or", " the", " to", " with"]
    return tailWords.contains { lowered.hasSuffix($0) }
  }

  private func parseBulletEvent(from line: String, sourcePath: String) -> RoundupReportEvent? {
    guard line.hasPrefix("- ") else { return nil }
    let payload = line.dropFirst(2)
    guard let colonIndex = payload.firstIndex(of: ":") else { return nil }
    let datePart = payload[..<colonIndex].trimmingCharacters(in: .whitespaces)
    guard datePart.count == 10, datePart.hasPrefix(String(year)) else { return nil }
    let summary = payload[payload.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
    guard let week = isoWeek(for: datePart) else { return nil }
    return RoundupReportEvent(
      date: datePart,
      isoWeek: week,
      summary: summary,
      sourcePath: sourcePath,
      changedFiles: nil
    )
  }

  private func parseLastUpdated(from line: String, sourcePath: String) -> RoundupReportEvent? {
    guard line.lowercased().hasPrefix("last updated:") else { return nil }
    let datePart = line.dropFirst("last updated:".count).trimmingCharacters(in: .whitespaces)
    guard datePart.count == 10, datePart.hasPrefix(String(year)) else { return nil }
    guard let week = isoWeek(for: datePart) else { return nil }
    let summary = "Last updated \(datePart)."
    return RoundupReportEvent(
      date: datePart,
      isoWeek: week,
      summary: summary,
      sourcePath: sourcePath,
      changedFiles: nil
    )
  }

  private func isoWeek(for dateString: String) -> Int? {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: dateString) else { return nil }
    return calendar.component(.weekOfYear, from: date)
  }

  private func extractGitEvents(rootPath: String, paths: [String]) async throws -> [RoundupReportEvent] {
    guard !paths.isEmpty else { return [] }
    let shell = CommonShell(workingDirectory: rootPath, executable: .name("git"))
    var events: [RoundupReportEvent] = []
    for path in paths {
      let output = try await shell.run(arguments: [
        "log",
        "--no-merges",
        "--since=\(year)-01-01",
        "--until=\(year)-12-31",
        "--date=short",
        "--pretty=format:%x1e%ad%x1f%s",
        "--name-only",
        "--",
        path,
      ])
      let records = output.components(separatedBy: "\u{1E}").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      for record in records {
        let lines = record.split(separator: "\n", omittingEmptySubsequences: false)
        guard let header = lines.first else { continue }
        let parts = header.split(separator: "\u{1F}", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { continue }
        let datePart = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let summary = String(parts[1]).trimmingCharacters(in: .whitespaces)
        guard datePart.hasPrefix(String(year)) else { continue }
        guard let week = isoWeek(for: datePart) else { continue }
        let fileLines = lines.dropFirst().map { String($0).trimmingCharacters(in: .whitespaces) }
        let changedFiles = fileLines
          .filter { !$0.isEmpty }
          .filter { !$0.contains("/.build/") }
        if changedFiles.isEmpty {
          continue
        }
        events.append(
          RoundupReportEvent(
            date: datePart,
            isoWeek: week,
            summary: summary,
            sourcePath: "git:\(path)",
            changedFiles: changedFiles.isEmpty ? nil : changedFiles
          )
        )
      }
    }
    return events
  }

  private func extractGitTags(rootPath: String) async throws -> [RoundupReportRelease] {
    let shell = CommonShell(workingDirectory: rootPath, executable: .name("git"))
    let output = try await shell.run(arguments: [
      "tag",
      "--list",
      "--sort=creatordate",
      "--format=%(refname:short)%x1f%(creatordate:short)",
    ])
    var releases: [RoundupReportRelease] = []
    for line in output.split(separator: "\n") {
      let parts = line.split(separator: "\u{1F}", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2 else { continue }
      let tag = String(parts[0]).trimmingCharacters(in: .whitespaces)
      let datePart = String(parts[1]).trimmingCharacters(in: .whitespaces)
      guard datePart.hasPrefix(String(year)) else { continue }
      releases.append(RoundupReportRelease(date: datePart, tag: tag))
    }
    return releases.sorted { $0.date < $1.date }
  }
}

final class RoundupReportSummarizer {
  private let events: RoundupReportEvents
  private let libraries: RoundupReportLibraries
  private let calendar: Calendar
  private let dateFormatter: DateFormatter
  private let monthFormatter: DateFormatter

  init(events: RoundupReportEvents, libraries: RoundupReportLibraries) {
    self.events = events
    self.libraries = libraries
    self.calendar = Calendar(identifier: .iso8601)
    self.dateFormatter = DateFormatter()
    dateFormatter.calendar = calendar
    dateFormatter.dateFormat = "yyyy-MM-dd"
    self.monthFormatter = DateFormatter()
    monthFormatter.calendar = calendar
    monthFormatter.dateFormat = "MMMM"
  }

  func buildSummary() -> RoundupReportSummary {
    let weekSummaries = buildWeekSummaries()
    let monthSummaries = buildMonthSummaries(weeks: weekSummaries)
    let dataCoverage = buildDataCoverage(weeks: weekSummaries)
    let keyResults = buildKeyResults(from: weekSummaries)
    let misses = buildMisses(from: events.events)
    let backlog = buildBacklog(from: events.events)

    return RoundupReportSummary(
      year: events.year,
      generatedAt: Date(),
      dataCoverage: dataCoverage,
      releases: events.releases,
      keyResults: keyResults,
      misses: misses,
      backlog: backlog,
      monthSummaries: monthSummaries,
      weekSummaries: weekSummaries
    )
  }

  private func buildWeekSummaries() -> [RoundupReportWeekSummary] {
    let eventsByWeek = Dictionary(grouping: events.events, by: { $0.isoWeek })
    var weekSummaries: [RoundupReportWeekSummary] = []
    for (week, weekEvents) in eventsByWeek {
      let sortedEvents = weekEvents.sorted { $0.date < $1.date }
      let synopsis = summarizeEvents(sortedEvents)
      let weekRange = formatWeekRange(week)
      let monthName = monthNameForWeek(week)
      let libraryModules = librariesForWeek(week)
      let summary = RoundupReportWeekSummary(
        isoWeek: week,
        weekRange: weekRange,
        month: monthName.lowercased(),
        synopsis: synopsis,
        events: sortedEvents,
        libraries: libraryModules
      )
      weekSummaries.append(summary)
    }
    return weekSummaries.sorted { $0.isoWeek > $1.isoWeek }
  }

  private func buildMonthSummaries(weeks: [RoundupReportWeekSummary]) -> [RoundupReportMonthSummary] {
    let months = Dictionary(grouping: weeks, by: { $0.month })
    let sortedMonths = months.keys.sorted { $0 > $1 }
    return sortedMonths.compactMap { monthKey in
      guard let monthWeeks = months[monthKey] else { return nil }
      let summary = summarizeMonth(weeks: monthWeeks)
      let monthName = monthWeeks.first?.month.capitalized ?? monthKey.capitalized
      return RoundupReportMonthSummary(
        month: monthKey,
        monthName: monthName,
        weeks: monthWeeks.sorted { $0.isoWeek > $1.isoWeek },
        synopsis: summary
      )
    }
  }

  private func buildKeyResults(from weeks: [RoundupReportWeekSummary]) -> [String] {
    guard !weeks.isEmpty else {
      return ["Key results need additional source material for clear outcomes."]
    }
    let totalEvents = weeks.reduce(0) { $0 + $1.events.count }
    let totalWeeks = Set(weeks.map(\.isoWeek)).count
    var results: [String] = []
    results.append("Captured \(totalEvents) dated milestones across \(totalWeeks) weeks.")

    let themes = extractThemes(from: weeks)
    if themes.isEmpty {
      results.append("Recurring themes pending; add more source detail to sharpen outcomes.")
    } else {
      results.append("Recurring themes: \(themes.joined(separator: ", ")).")
    }

    let libraryWeeks = weeks.filter { !$0.libraries.isEmpty }.count
    if libraryWeeks == 0 {
      results.append("No library change weeks detected; confirm dependency sources and git history inputs.")
    } else {
      results.append("Library changes documented in \(libraryWeeks) weeks; expand notes for deeper insights.")
    }
    return results
  }

  private func buildDataCoverage(weeks: [RoundupReportWeekSummary]) -> RoundupReportDataCoverage {
    let sourcesCount = Set(events.events.map(\.sourcePath)).count
    let weeksInYear = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: dateForYear())?.count ?? 52
    let weeksWithEvents = Set(events.events.map(\.isoWeek)).count
    let weeksWithLibraries = Set(weeks.filter { !$0.libraries.isEmpty }.map(\.isoWeek)).count
    let percentWeeksWithEvents = percentage(weeksWithEvents, weeksInYear)
    let percentWeeksWithLibraries = percentage(weeksWithLibraries, weeksInYear)
    return RoundupReportDataCoverage(
      sourcesCount: sourcesCount,
      weeksInYear: weeksInYear,
      weeksWithEvents: weeksWithEvents,
      weeksWithLibraries: weeksWithLibraries,
      percentWeeksWithEvents: percentWeeksWithEvents,
      percentWeeksWithLibraries: percentWeeksWithLibraries
    )
  }

  private func percentage(_ value: Int, _ total: Int) -> Double {
    guard total > 0 else { return 0 }
    return (Double(value) / Double(total)) * 100
  }

  private func dateForYear() -> Date {
    let components = DateComponents(calendar: calendar, weekday: 2, weekOfYear: 1, yearForWeekOfYear: events.year)
    return calendar.date(from: components) ?? Date()
  }

  private func extractThemes(from weeks: [RoundupReportWeekSummary]) -> [String] {
    let stopWords: Set<String> = [
      "about", "after", "again", "against", "along", "also", "and", "another",
      "around", "backlog", "before", "being", "between", "both", "build",
      "built", "during", "each", "from", "into", "more", "most", "over",
      "progress", "report", "review", "roadmap", "some", "still", "that",
      "their", "then", "this", "through", "with", "year"
    ]
    var counts: [String: Int] = [:]
    for event in weeks.flatMap(\.events) {
      let words = tokenize(event.summary)
      for word in words where !stopWords.contains(word) {
        counts[word, default: 0] += 1
      }
    }
    let sorted = counts.sorted { lhs, rhs in
      if lhs.value == rhs.value {
        return lhs.key < rhs.key
      }
      return lhs.value > rhs.value
    }
    return sorted.prefix(3).map { $0.key }
  }

  private func tokenize(_ summary: String) -> [String] {
    let separators = CharacterSet.alphanumerics.inverted
    return summary
      .lowercased()
      .components(separatedBy: separators)
      .filter { $0.count >= 4 }
  }

  private func buildMisses(from events: [RoundupReportEvent]) -> [String] {
    let missKeywords = ["failed", "regression", "not found", "missing"]
    let misses = events.filter { event in
      let summary = event.summary.lowercased()
      return missKeywords.contains { summary.contains($0) }
    }
    if misses.isEmpty {
      return ["No explicit misses extracted; review for hidden regressions."]
    }
    return misses.map { "\($0.date): \($0.summary)" }
  }

  private func buildBacklog(from events: [RoundupReportEvent]) -> [String] {
    let backlogKeywords = ["last updated", "backlog", "prd"]
    let backlog = events.filter { event in
      let summary = event.summary.lowercased()
      return backlogKeywords.contains { summary.contains($0) }
    }
    if backlog.isEmpty {
      return ["Backlog seeds missing; add PRD updates or roadmap items."]
    }
    return backlog.map { "\($0.date): \($0.summary)" }
  }

  private func summarizeEvents(_ events: [RoundupReportEvent]) -> String {
    guard !events.isEmpty else {
      return "No dated events found in current sources."
    }
    if events.count == 1 {
      return "This week advanced delivery through: \(events[0].summary)"
    }
    if events.count == 2 {
      return "This week delivered two key moves: \(events[0].summary) and \(events[1].summary)."
    }
    let first = events[0].summary
    let second = events[1].summary
    let last = events.last?.summary ?? ""
    return "This week focused on \(first), followed by \(second). Momentum continued with \(last)."
  }

  private func summarizeMonth(weeks: [RoundupReportWeekSummary]) -> String {
    guard let latest = weeks.sorted(by: { $0.isoWeek > $1.isoWeek }).first else {
      return "Monthly summary pending."
    }
    return "Monthly recap anchored by the latest focus: \(latest.synopsis)"
  }

  private func formatWeekRange(_ week: Int) -> String {
    guard let start = calendar.date(from: DateComponents(calendar: calendar, weekday: 2, weekOfYear: week, yearForWeekOfYear: events.year)),
          let end = calendar.date(from: DateComponents(calendar: calendar, weekday: 1, weekOfYear: week, yearForWeekOfYear: events.year)) else {
      return "Week \(week)"
    }
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateFormat = "MMM dd"
    return "\(formatter.string(from: start))-\(formatter.string(from: end))"
  }

  private func monthNameForWeek(_ week: Int) -> String {
    guard let start = calendar.date(from: DateComponents(calendar: calendar, weekday: 2, weekOfYear: week, yearForWeekOfYear: events.year)) else {
      return "unknown"
    }
    return monthFormatter.string(from: start)
  }

  private func librariesForWeek(_ week: Int) -> [String] {
    let modules = libraries.libraries.filter { $0.weeks.contains(week) }.map { $0.moduleName }
    return modules.sorted()
  }
}

final class RoundupReportRenderer {
  private let summary: RoundupReportSummary
  private let outputURL: URL
  private let productName: String
  private let productSlug: String

  init(summary: RoundupReportSummary, outputPath: String, productName: String, productSlug: String) {
    self.summary = summary
    self.outputURL = URL(fileURLWithPath: outputPath)
    self.productName = productName
    self.productSlug = productSlug
  }

  func render() throws {
    try renderRootPage()
    try renderYearPage()
    try renderMonthPages()
    try renderWeekPages()
    try renderRoundupPage()
  }

  private func renderRootPage() throws {
    let rootPath = outputURL.appendingPathComponent("\(productSlug).md")
    let lines: [String] = [
      "# \(productName) roundup",
      "",
      "@Metadata {",
      "  @TechnologyRoot",
      "}",
      "",
      "Executive product roundup for \(productName), ordered newest-first.",
      "",
      "## Topics",
      "",
      "### Overview",
      "",
      "- <doc:\(yearDoc)>",
      "- <doc:\(roundupDoc)>",
      "",
    ]
    try lines.joined(separator: "\n").write(to: rootPath, atomically: true, encoding: .utf8)
  }

  private func renderYearPage() throws {
    let articlesURL = outputURL.appendingPathComponent("articles")
    try FileManager.default.createDirectory(at: articlesURL, withIntermediateDirectories: true)
    let yearPath = articlesURL.appendingPathComponent("\(yearDoc).md")

    var lines: [String] = [
      "# \(productName) \(summary.year)",
      "",
      "Executive summary for \(productName) \(summary.year) milestones, ordered newest-first.",
      "",
      nextStepsCallout(title: "Next steps", items: nextStepsItems()),
      "",
      "## \(summary.year) outcomes",
      "",
      "### Data coverage",
      "",
      dataCoverageSummary(),
      "",
      "### Key results",
      "",
    ]
    lines.append(contentsOf: summary.keyResults.map { "- \($0)" })
    lines.append("")
    lines.append("### Misses")
    lines.append("")
    lines.append(contentsOf: summary.misses.map { "- \($0)" })
    lines.append("")
    lines.append("### \(summary.year + 1) backlog (seed)")
    lines.append("")
    lines.append(contentsOf: summary.backlog.map { "- \($0)" })
    lines.append("")
    lines.append("### Release cadence")
    lines.append("")
    lines.append(contentsOf: releaseLines())
    lines.append("")
    lines.append("## \(summary.year) monthly summaries")
    lines.append("")

    for monthSummary in summary.monthSummaries {
      lines.append("### \(productName) \(summary.year) \(monthSummary.monthName)")
      lines.append("")
      lines.append(monthSummary.synopsis)
      lines.append("")
      for week in monthSummary.weeks {
        lines.append("#### Week \(String(format: "%02d", week.isoWeek)) (\(week.weekRange))")
        lines.append("")
        lines.append(week.synopsis)
        lines.append("")
        lines.append("##### Key events")
        lines.append("")
        for day in groupedEvents(week.events) {
          lines.append("- \(day.date):")
          for summary in day.summaries {
            lines.append("\t- \(summary)")
          }
        }
        lines.append("")
        lines.append("##### Week page")
        lines.append("")
        lines.append("- <doc:\(weekDoc(week.isoWeek))>")
        lines.append("")
      }
      lines.append("#### Month page")
      lines.append("")
      lines.append("- <doc:\(monthDoc(monthSummary.month))>")
      lines.append("")
    }

    lines.append("## Topics")
    lines.append("")
    lines.append("### By month (newest first)")
    lines.append("")
    for monthSummary in summary.monthSummaries {
      lines.append("- <doc:\(monthDoc(monthSummary.month))>")
    }
    lines.append("")
    lines.append("### By week (newest first)")
    lines.append("")
    for week in summary.weekSummaries {
      lines.append("- <doc:\(weekDoc(week.isoWeek))>")
    }
    lines.append("")

    try lines.joined(separator: "\n").write(to: yearPath, atomically: true, encoding: .utf8)
  }

  private func renderMonthPages() throws {
    let articlesURL = outputURL.appendingPathComponent("articles")
    for monthSummary in summary.monthSummaries {
      let path = articlesURL.appendingPathComponent("\(monthDoc(monthSummary.month)).md")
      var lines: [String] = [
        "# \(productName) \(summary.year) \(monthSummary.monthName)",
        "",
        monthSummary.synopsis,
        "",
        nextStepsCallout(title: "Next steps", items: nextStepsItems()),
        "",
        "## Weekly roundup",
        "",
      ]
      for week in monthSummary.weeks {
        lines.append("### Week \(String(format: "%02d", week.isoWeek)) (\(week.weekRange))")
        lines.append("")
        lines.append(week.synopsis)
        lines.append("")
        lines.append("#### Key events")
        lines.append("")
        for day in groupedEvents(week.events) {
          lines.append("- \(day.date):")
          for summary in day.summaries {
            lines.append("\t- \(summary)")
          }
        }
        lines.append("")
        lines.append("#### Week page")
        lines.append("")
        lines.append("- <doc:\(weekDoc(week.isoWeek))>")
        lines.append("")
      }
      lines.append("## Topics")
      lines.append("")
      lines.append("### Weeks (newest first)")
      lines.append("")
      for week in monthSummary.weeks {
        lines.append("- <doc:\(weekDoc(week.isoWeek))>")
      }
      lines.append("")
      try lines.joined(separator: "\n").write(to: path, atomically: true, encoding: .utf8)
    }
  }

  private func renderWeekPages() throws {
    let articlesURL = outputURL.appendingPathComponent("articles")
    for week in summary.weekSummaries {
      let path = articlesURL.appendingPathComponent("\(weekDoc(week.isoWeek)).md")
      var lines: [String] = [
        "# \(productName) \(summary.year) Week \(String(format: "%02d", week.isoWeek)) (\(week.weekRange))",
        "",
        week.synopsis,
        "",
        nextStepsCallout(title: "Next steps", items: nextStepsItems()),
        "",
        "## Key events",
        "",
      ]
      for day in groupedEvents(week.events) {
        lines.append("### \(day.date)")
        lines.append("")
        for summary in day.summaries {
          lines.append("- \(summary)")
        }
        lines.append("")
      }
      lines.append("## Libraries")
      lines.append("")
      if week.libraries.isEmpty {
        lines.append("- No library changes recorded for this week.")
      } else {
        lines.append("- " + week.libraries.joined(separator: ", "))
      }
      lines.append("")
      lines.append("## Sources")
      lines.append("")
      lines.append(contentsOf: sourceLines(for: week.events))
      lines.append("")
      lines.append("## Details")
      lines.append("")
      lines.append("More detail can be added here as sources expand.")
      lines.append("")
      try lines.joined(separator: "\n").write(to: path, atomically: true, encoding: .utf8)
    }
  }

  private func renderRoundupPage() throws {
    let articlesURL = outputURL.appendingPathComponent("articles")
    let path = articlesURL.appendingPathComponent("\(roundupDoc).md")
    var lines: [String] = [
      "# \(productName) \(summary.year) roundup (weekly)",
      "",
      "Executive summary of \(productName) \(summary.year) milestones, newest-first. Detailed sources and",
      "library notes follow each week.",
      "",
      nextStepsCallout(title: "Next steps", items: nextStepsItems()),
      "",
      "## \(summary.year) outcomes",
      "",
      "### Data coverage",
      "",
      dataCoverageSummary(),
      "",
      "### Key results",
      "",
    ]
    lines.append(contentsOf: summary.keyResults.map { "- \($0)" })
    lines.append("")
    lines.append("### Misses")
    lines.append("")
    lines.append(contentsOf: summary.misses.map { "- \($0)" })
    lines.append("")
    lines.append("### \(summary.year + 1) backlog (seed)")
    lines.append("")
    lines.append(contentsOf: summary.backlog.map { "- \($0)" })
    lines.append("")
    lines.append("### Release cadence")
    lines.append("")
    lines.append(contentsOf: releaseLines())
    lines.append("")
    lines.append("## Monthly summaries")
    lines.append("")
    for monthSummary in summary.monthSummaries {
      lines.append("### \(productName) \(summary.year) \(monthSummary.monthName)")
      lines.append("")
      lines.append(monthSummary.synopsis)
      lines.append("")
      for week in monthSummary.weeks {
        lines.append("#### Week \(String(format: "%02d", week.isoWeek)) (\(week.weekRange))")
        lines.append("")
        lines.append(week.synopsis)
        lines.append("")
        lines.append("##### Key events")
        lines.append("")
        for day in groupedEvents(week.events) {
          lines.append("- \(day.date):")
          for summary in day.summaries {
            lines.append("\t- \(summary)")
          }
        }
        lines.append("")
        lines.append("##### Week page")
        lines.append("")
        lines.append("- <doc:\(weekDoc(week.isoWeek))>")
        lines.append("")
      }
      lines.append("#### Month page")
      lines.append("")
      lines.append("- <doc:\(monthDoc(monthSummary.month))>")
      lines.append("")
    }
    lines.append("## Weekly timeline")
    lines.append("")
    for week in summary.weekSummaries {
      lines.append("## Week \(String(format: "%02d", week.isoWeek)) (\(week.weekRange))")
      lines.append("")
      lines.append("### Key events")
      lines.append("")
      for day in groupedEvents(week.events) {
        lines.append("### \(day.date)")
        lines.append("")
        for summary in day.summaries {
          lines.append("- \(summary)")
        }
        lines.append("")
      }
      lines.append("### Libraries")
      lines.append("")
      if week.libraries.isEmpty {
        lines.append("- No library changes recorded for this week.")
      } else {
        lines.append("- " + week.libraries.joined(separator: ", "))
      }
      lines.append("")
      lines.append("### Sources")
      lines.append("")
      lines.append(contentsOf: sourceLines(for: week.events))
      lines.append("")
      lines.append("### Synopsis")
      lines.append("")
      lines.append(week.synopsis)
      lines.append("")
    }
    lines.append("## Topics")
    lines.append("")
    lines.append("### Overview")
    lines.append("")
    lines.append("- <doc:\(roundupDoc)>")
    lines.append("")
    lines.append("### By month (newest first)")
    lines.append("")
    for monthSummary in summary.monthSummaries {
      lines.append("- <doc:\(monthDoc(monthSummary.month))>")
    }
    lines.append("")
    lines.append("### By week (newest first)")
    lines.append("")
    for week in summary.weekSummaries {
      lines.append("- <doc:\(weekDoc(week.isoWeek))>")
    }
    lines.append("")

    try lines.joined(separator: "\n").write(to: path, atomically: true, encoding: .utf8)
  }

  private var yearDoc: String {
    "\(productSlug)-\(summary.year)"
  }

  private var roundupDoc: String {
    "\(productSlug)-\(summary.year)-roundup"
  }

  private func monthDoc(_ month: String) -> String {
    "\(productSlug)-\(summary.year)-\(month)"
  }

  private func weekDoc(_ week: Int) -> String {
    "\(productSlug)-\(summary.year)-week-\(String(format: "%02d", week))"
  }

  private func dataCoverageSummary() -> String {
    let coverage = summary.dataCoverage
    return "- Sources: \(coverage.sourcesCount)\n" +
      "- Weeks with events: \(coverage.weeksWithEvents)/\(coverage.weeksInYear) " +
      "(\(formatPercent(coverage.percentWeeksWithEvents)))\n" +
      "- Weeks with library changes: \(coverage.weeksWithLibraries)/\(coverage.weeksInYear) " +
      "(\(formatPercent(coverage.percentWeeksWithLibraries)))"
  }

  private func formatPercent(_ value: Double) -> String {
    String(format: "%.1f%%", value)
  }

  private func releaseLines() -> [String] {
    if summary.releases.isEmpty {
      return ["- No release tags detected in git history."]
    }
    return summary.releases.map { "- \($0.date): \($0.tag)" }
  }

  private func nextStepsItems() -> [String] {
    var items: [String] = []
    if let firstMiss = summary.misses.first {
      items.append("Triage misses: \(firstMiss)")
    }
    if let firstBacklog = summary.backlog.first {
      items.append("Seed \(summary.year + 1) backlog: \(firstBacklog)")
    }
    let coverage = summary.dataCoverage
    if coverage.percentWeeksWithEvents < 50 {
      items.append("Increase source coverage for additional weeks.")
    }
    if coverage.percentWeeksWithLibraries < 25 {
      items.append("Expand library history inputs for fuller dependency coverage.")
    }
    if items.isEmpty {
      items.append("Add more sources to refine key results and misses.")
    }
    return items
  }

  private func nextStepsCallout(title: String, items: [String]) -> String {
    var lines: [String] = [
      "<callout icon=\"checkmark\" color=\"green_bg\">",
      "\(title)",
    ]
    for item in items {
      lines.append("\t- \(item)")
    }
    lines.append("</callout>")
    return lines.joined(separator: "\n")
  }

  private func sourceLines(for events: [RoundupReportEvent]) -> [String] {
    var files: Set<String> = []
    var sources: Set<String> = []
    for event in events {
      if let changedFiles = event.changedFiles, !changedFiles.isEmpty {
        files.formUnion(changedFiles)
      } else if !event.sourcePath.isEmpty {
        sources.insert(event.sourcePath)
      }
    }
    if !files.isEmpty {
      return files
        .filter { !$0.contains("/.build/") }
        .sorted()
        .map { "- `\($0)`" }
    }
    return sources
      .filter { !$0.contains("/.build/") }
      .sorted()
      .map { "- `\($0)`" }
  }

  private struct RoundupReportDayEvents {
    let date: String
    let summaries: [String]
  }

  private func groupedEvents(_ events: [RoundupReportEvent]) -> [RoundupReportDayEvents] {
    let grouped = Dictionary(grouping: events, by: { $0.date })
    let sortedDates = grouped.keys.sorted()
    return sortedDates.compactMap { date in
      guard let dayEvents = grouped[date] else { return nil }
      let summaries = dayEvents.map { $0.summary }
      return RoundupReportDayEvents(date: date, summaries: summaries)
    }
  }

  static func slugify(_ value: String) -> String {
    let lowered = value.lowercased()
    var result = ""
    var previousWasHyphen = false
    for scalar in lowered.unicodeScalars {
      let isAlnum = (scalar.value >= 48 && scalar.value <= 57) || (scalar.value >= 97 && scalar.value <= 122)
      if isAlnum {
        result.unicodeScalars.append(scalar)
        previousWasHyphen = false
      } else if scalar == " " || scalar == "_" || scalar == "-" {
        if !previousWasHyphen {
          result.append("-")
          previousWasHyphen = true
        }
      }
    }
    return result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}

final class RoundupReportLibraryMapper {
  private let sourceRootURL: URL
  private let spmRootURL: URL
  private let packageSearchRoots: [URL]
  private let ownedPackageRoots: [URL]
  private let ownedTargetRoots: [URL]
  private let repoRootPath: String
  private let year: Int
  private let fileManager: FileManager = .default
  private let calendar: Calendar
  private let dateFormatter: DateFormatter

  init(
    sourceRootPath: String,
    spmRootPath: String,
    packageSearchRoots: [String],
    ownedPackageRoots: [String],
    ownedTargetRoots: [String],
    repoRootPath: String,
    year: Int
  ) {
    self.sourceRootURL = URL(fileURLWithPath: sourceRootPath)
    self.spmRootURL = URL(fileURLWithPath: spmRootPath)
    let resolved = packageSearchRoots.map { RoundupReportLibraryMapper.resolveURL(path: $0) }
    self.packageSearchRoots = resolved
    self.ownedPackageRoots = ownedPackageRoots.map { RoundupReportLibraryMapper.resolveURL(path: $0).standardizedFileURL }
    self.ownedTargetRoots = ownedTargetRoots.map { RoundupReportLibraryMapper.resolveURL(path: $0).standardizedFileURL }
    self.repoRootPath = repoRootPath
    self.year = year
    self.calendar = Calendar(identifier: .iso8601)
    self.dateFormatter = DateFormatter()
    dateFormatter.calendar = calendar
    dateFormatter.dateFormat = "yyyy-MM-dd"
  }

  func buildReport() async throws -> RoundupReportLibraries {
    let imports = try scanImports()
    let modulePackages = try mapModulesToPackages(imports: imports)
    let ownedTargets = try scanOwnedTargets()
    let libraries = try await buildLibraryEntries(modulePackages: modulePackages, imports: imports)
      .filter { ownedTargets.isEmpty || ownedTargets.contains($0.moduleName) || !$0.packagePaths.isEmpty }
    return RoundupReportLibraries(year: year, generatedAt: Date(), libraries: libraries.sorted {
      $0.moduleName < $1.moduleName
    })
  }

  private func scanImports() throws -> Set<String> {
    guard fileManager.fileExists(atPath: sourceRootURL.path) else { return [] }
    guard let files = fileManager.enumerator(at: sourceRootURL, includingPropertiesForKeys: nil) else {
      return []
    }
    var imports: Set<String> = []
    for case let fileURL as URL in files {
      guard fileURL.pathExtension == "swift" else { continue }
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for line in contents.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)
        guard trimmed.hasPrefix("import ") else { continue }
        let module = trimmed.replacingOccurrences(of: "import ", with: "")
          .split(separator: " ")
          .first
        if let module, module.first?.isUppercase == true {
          imports.insert(String(module))
        }
      }
    }
    return imports
  }

  private func mapModulesToPackages(imports: Set<String>) throws -> [String: Set<String>] {
    let roots = Array(Set((packageSearchRoots + [spmRootURL]).map { $0.standardizedFileURL }))
      .sorted { $0.path < $1.path }
    var modulePackages: [String: Set<String>] = [:]
    let regex = try NSRegularExpression(pattern: "\\bname:\\s*\\\"([^\\\"]+)\\\"")

    for root in roots {
      guard fileManager.fileExists(atPath: root.path) else { continue }
      guard let files = fileManager.enumerator(at: root, includingPropertiesForKeys: nil) else {
        continue
      }
      for case let fileURL as URL in files {
        guard fileURL.lastPathComponent == "Package.swift" else { continue }
        if fileURL.pathComponents.contains(".build") { continue }
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let matches = regex.matches(in: contents, range: NSRange(contents.startIndex..., in: contents))
        for match in matches {
          guard let range = Range(match.range(at: 1), in: contents) else { continue }
          let name = String(contents[range])
          guard imports.contains(name) else { continue }
          modulePackages[name, default: []].insert(fileURL.deletingLastPathComponent().path)
        }
      }
    }
    return modulePackages
  }

  private func buildLibraryEntries(
    modulePackages: [String: Set<String>],
    imports: Set<String>
  ) async throws -> [RoundupReportLibrary] {
    var libraries: [RoundupReportLibrary] = []
    let sortedImports = imports.sorted()
    for moduleName in sortedImports {
      let packages = modulePackages[moduleName] ?? []
      let packagePaths = packages.sorted()
      let filteredPackages = filterOwnedPackages(packagePaths)
      let expandedPaths = try resolveLocalDependencies(startingPaths: filteredPackages)
      let filteredExpanded = filterOwnedPackages(Array(expandedPaths))
      let weeks = try await weeksForPackages(paths: filteredExpanded.sorted())
      let notes = packagePaths.isEmpty ? "No Package.swift match found in SPM root." : nil
      libraries.append(
        RoundupReportLibrary(
          moduleName: moduleName,
          packagePaths: filteredPackages,
          weeks: weeks,
          notes: notes
        )
      )
    }
    return libraries
  }

  private func weeksForPackages(paths: [String]) async throws -> [Int] {
    guard !paths.isEmpty else { return [] }
    var weekSet: Set<Int> = []
    for path in paths {
      let dates = try await gitDates(for: path)
      for dateString in dates {
        if let date = dateFormatter.date(from: dateString) {
          weekSet.insert(calendar.component(.weekOfYear, from: date))
        }
      }
    }
    return weekSet.sorted()
  }

  private func gitDates(for path: String) async throws -> [String] {
    let shell = CommonShell(workingDirectory: repoRootPath, executable: .name("git"))
    let output = try await shell.run(arguments: [
      "log",
      "--since=\(year)-01-01",
      "--until=\(year)-12-31",
      "--date=short",
      "--pretty=format:%ad",
      "--",
      path,
    ])
    return output
      .split(separator: "\n")
      .map { String($0).trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }

  private func resolveLocalDependencies(startingPaths: [String]) throws -> Set<String> {
    var visited: Set<String> = []
    var queue = startingPaths
    let pathRegex = try NSRegularExpression(pattern: "\\.package\\([^\\)]*path:\\s*\\\"([^\\\"]+)\\\"")

    while let current = queue.popLast() {
      if visited.contains(current) { continue }
      visited.insert(current)

      let packageManifest = URL(fileURLWithPath: current).appendingPathComponent("Package.swift")
      guard fileManager.fileExists(atPath: packageManifest.path) else { continue }
      let contents = try String(contentsOf: packageManifest, encoding: .utf8)
      let matches = pathRegex.matches(in: contents, range: NSRange(contents.startIndex..., in: contents))
      for match in matches {
        guard let range = Range(match.range(at: 1), in: contents) else { continue }
        let rawPath = String(contents[range])
        let resolved = URL(fileURLWithPath: current).appendingPathComponent(rawPath).standardizedFileURL.path
        if fileManager.fileExists(atPath: resolved) && !visited.contains(resolved) {
          queue.append(resolved)
        }
      }
    }

    return visited
  }

  private func filterOwnedPackages(_ paths: [String]) -> [String] {
    guard !ownedPackageRoots.isEmpty else { return paths }
    return paths.filter { path in
      let normalized = URL(fileURLWithPath: path).standardizedFileURL
      return ownedPackageRoots.contains { root in
        normalized.path.hasPrefix(root.path)
      }
    }
  }

  private func scanOwnedTargets() throws -> Set<String> {
    guard !ownedTargetRoots.isEmpty else { return [] }
    let regex = try NSRegularExpression(pattern: "\\b(?:target|executableTarget|testTarget)\\s*\\(\\s*name:\\s*\\\"([^\\\"]+)\\\"")
    var targets: Set<String> = []

    for root in ownedTargetRoots {
      guard fileManager.fileExists(atPath: root.path) else { continue }
      guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil) else { continue }
      for case let fileURL as URL in enumerator {
        guard fileURL.lastPathComponent == "Package.swift" else { continue }
        let path = fileURL.path
        if path.contains("/.build/") { continue }
        if path.contains("/.clia/tmp/") { continue }
        if path.contains("/SourcePackages/") { continue }
        if path.contains("/derived/") { continue }
        if path.contains("/.git/") { continue }
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let matches = regex.matches(in: contents, range: NSRange(contents.startIndex..., in: contents))
        for match in matches {
          guard let range = Range(match.range(at: 1), in: contents) else { continue }
          targets.insert(String(contents[range]))
        }
      }
    }
    return targets
  }

  private static func resolveURL(path: String) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path)
    }
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return root.appendingPathComponent(path)
  }
}

struct RoundupReportAuditReport {
  let brokenDocLinks: [String]
  let weekPagesMissingDays: [String]
  let missingWeekPages: [String]
}

final class RoundupReportAuditor {
  private let doccRootURL: URL
  private let fileManager: FileManager = .default

  init(doccRootPath: String) {
    self.doccRootURL = URL(fileURLWithPath: doccRootPath)
  }

  func run() throws -> RoundupReportAuditReport {
    let files = try markdownFiles()
    let availableDocs = Set(files.map { $0.deletingPathExtension().lastPathComponent })
    var brokenLinks: [String] = []
    var missingWeekPages: [String] = []
    var weekPagesMissingDays: [String] = []

    for file in files {
      let contents = try String(contentsOf: file, encoding: .utf8)
      for docRef in docLinks(in: contents) {
        if !availableDocs.contains(docRef) {
          brokenLinks.append("\(docRef) <- \(file.path)")
          if docRef.contains("-week-") {
            missingWeekPages.append(docRef)
          }
        }
      }
    }

    for file in files where file.lastPathComponent.contains("-week-") {
      let contents = try String(contentsOf: file, encoding: .utf8)
      if !containsDaySections(contents) {
        weekPagesMissingDays.append(file.path)
      }
    }

    return RoundupReportAuditReport(
      brokenDocLinks: brokenLinks.sorted(),
      weekPagesMissingDays: weekPagesMissingDays.sorted(),
      missingWeekPages: Array(Set(missingWeekPages)).sorted()
    )
  }

  private func markdownFiles() throws -> [URL] {
    guard fileManager.fileExists(atPath: doccRootURL.path) else { return [] }
    let articlesURL = doccRootURL.appendingPathComponent("articles")
    var files: [URL] = []
    if let enumerator = fileManager.enumerator(at: doccRootURL, includingPropertiesForKeys: nil) {
      for case let fileURL as URL in enumerator {
        guard fileURL.pathExtension == "md" else { continue }
        if fileURL.path.contains("/.build/") { continue }
        files.append(fileURL)
      }
    }
    if fileManager.fileExists(atPath: articlesURL.path),
       let enumerator = fileManager.enumerator(at: articlesURL, includingPropertiesForKeys: nil) {
      for case let fileURL as URL in enumerator {
        guard fileURL.pathExtension == "md" else { continue }
        if fileURL.path.contains("/.build/") { continue }
        files.append(fileURL)
      }
    }
    return Array(Set(files))
  }

  private func docLinks(in contents: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: "<doc:([^>]+)>") else { return [] }
    let range = NSRange(contents.startIndex..., in: contents)
    let matches = regex.matches(in: contents, range: range)
    return matches.compactMap { match in
      guard let range = Range(match.range(at: 1), in: contents) else { return nil }
      return String(contents[range])
    }
  }

  private func containsDaySections(_ contents: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: "^###\\s\\d{4}-\\d{2}-\\d{2}", options: [.anchorsMatchLines]) else {
      return false
    }
    let range = NSRange(contents.startIndex..., in: contents)
    return regex.firstMatch(in: contents, range: range) != nil
  }
}

enum RoundupReportJSONWriter {
  static func write<T: Encodable>(_ value: T, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(value)
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: url, options: [.atomic])
  }

  static func read<T: Decodable>(_ type: T.Type, from path: String) throws -> T {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(type, from: data)
  }
}
