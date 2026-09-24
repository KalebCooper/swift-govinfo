#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A validated package discovery window with an explicit date meaning.
///
/// Use `.modified(collection:from:through:)` for repository corrections and
/// `.published(collections:from:through:)` for publication dates. A finite upper bound supports
/// resumable inventories; no window guarantees a stable snapshot.
public struct PackageQuery: Hashable, Sendable {
  /// The semantic date range sent to GovInfo.
  public enum Window: Hashable, Sendable {
    /// Repository modification timestamps, in whole-second UTC ISO 8601 form.
    case modified(collection: CollectionCode, from: String, through: String)
    /// Publication dates in YYYY-MM-DD form.
    case published(collections: [CollectionCode], from: String, through: String)
  }
  /// Requested page size, from 1 through 1,000.
  public let pageSize: Int
  /// The validated source date window.
  public let window: Window

  /// Creates a bounded query without performing I/O.
  /// - Throws: `GovInfoValidationError` for invalid dates, identifiers, or page sizes.
  public init(pageSize: Int = 100, window: Window) throws(GovInfoValidationError) {
    guard (1...1000).contains(pageSize) else { throw .invalidPageSize }
    let from: String
    let through: String
    let timestamp: Bool
    let codes: [CollectionCode]
    switch window {
    case .modified(let collection, let start, let end):
      codes = [collection]; from = start; through = end; timestamp = true
    case .published(let collections, let start, let end):
      codes = collections; from = start; through = end; timestamp = false
    }
    guard !codes.isEmpty,
      codes.allSatisfy({
        !$0.rawValue.isEmpty
          && $0.rawValue.utf8.allSatisfy {
            (65...90).contains($0) || (48...57).contains($0) || $0 == 95
          }
      })
    else {
      throw .invalidIdentifier
    }
    guard Self.validDate(from, timestamp: timestamp), Self.validDate(through, timestamp: timestamp),
      from <= through
    else {
      throw .invalidDateWindow
    }
    self.pageSize = pageSize
    self.window = window
  }

  var path: String {
    let paging = "offsetMark=*&pageSize=\(pageSize)"
    switch window {
    case .modified(let collection, let from, let through):
      return "/collections/\(collection.rawValue)/\(from)/\(through)?\(paging)"
    case .published(let collections, let from, let through):
      return
        "/published/\(from)/\(through)?collection=\(collections.map(\.rawValue).joined(separator: ","))&\(paging)"
    }
  }

  private static func validDate(_ value: String, timestamp: Bool) -> Bool {
    let bytes = Array(value.utf8)
    guard bytes.count == (timestamp ? 20 : 10), bytes[4] == 45, bytes[7] == 45 else { return false }
    let punctuation: Set<Int> = timestamp ? [4, 7, 10, 13, 16, 19] : [4, 7]
    guard
      bytes.enumerated().allSatisfy({
        punctuation.contains($0.offset) || (48...57).contains($0.element)
      }),
      let year = Int(String(value.prefix(4))),
      let month = Int(String(value.dropFirst(5).prefix(2))),
      let day = Int(String(value.dropFirst(8).prefix(2))),
      year > 0, (1...12).contains(month)
    else { return false }
    let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    let lengths = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    guard (1...lengths[month - 1]).contains(day) else { return false }
    if !timestamp { return true }
    return bytes[10] == 84 && bytes[13] == 58 && bytes[16] == 58 && bytes[19] == 90
      && String(value.dropFirst(11).prefix(2)) <= "23"
      && String(value.dropFirst(14).prefix(2)) <= "59"
      && String(value.dropFirst(17).prefix(2)) <= "59"
  }
}

extension Endpoint where Response == CollectionDirectory {
  /// The current collection inventory, retrieved as one response.
  public static var collections: Self { .builtIn(path: "/collections") }
}

extension Endpoint where Response == PackagePage {
  /// One independently usable package listing page.
  public static func packages(matching query: PackageQuery) -> Self { .builtIn(path: query.path) }
}

extension DocumentRequest where Response == CollectionDirectory {
  /// A collection discovery request.
  public static var collections: Self { Self(endpoint: .collections) }
}

extension DocumentRequest where Response == PackagePage {
  /// A lazy package traversal, or the first page when executed with value(for:).
  public static func packages(matching query: PackageQuery) -> Self {
    Self(pages: .packages(matching: query))
  }
}
