#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A validated GovInfo URL and its response type, with no transport or credentials.
///
/// `Endpoint<DocumentMetadata>.package("PPP-1929-book1")` describes one JSON request.
/// Only HTTPS API and public content origins are accepted. API keys belong in SDK configuration.
public struct Endpoint<Response>: Hashable, Sendable {
  /// The media type requested from the provider.
  public let accept: String
  /// The validated origin.
  public let origin: String
  /// The percent-encoded path and query.
  public let path: String
  /// The credential-free source URL.
  public var url: URL {
    guard let value = URL(string: origin + path) else {
      preconditionFailure("Validated GovInfo components form a URL.")
    }
    return value
  }

  /// Creates a source endpoint from a published link.
  ///
  /// Rejects user information, fragments, nondefault ports, query credentials, malformed escapes,
  /// dot segments, and other origins. Public content paths are limited to content, metadata, and bulkdata.
  public init?(accept: String = "application/json", link: URL) {
    guard let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
      components.scheme?.lowercased() == "https",
      let host = components.host?.lowercased(),
      ["api.govinfo.gov", "www.govinfo.gov"].contains(host),
      components.port == nil || components.port == 443,
      components.user == nil, components.password == nil, components.fragment == nil,
      !accept.contains("\r"), !accept.contains("\n")
    else { return nil }
    let path = components.percentEncodedPath
    guard Self.validPath(path),
      !(components.queryItems ?? []).contains(where: {
        ["api_key", "apikey", "key", "x-api-key"].contains($0.name.lowercased())
      }),
      host == "api.govinfo.gov"
        || ["/bulkdata/", "/content/", "/metadata/"].contains(where: path.hasPrefix)
    else { return nil }
    self.accept = accept
    self.origin = "https://" + host
    self.path = path + (components.percentEncodedQuery.map { "?" + $0 } ?? "")
  }

  /// Creates an API endpoint from an encoded relative path and query.
  public init?(accept: String = "application/json", path: String) {
    guard path.hasPrefix("/"), !path.hasPrefix("//"),
      let link = URL(string: "https://api.govinfo.gov" + path, encodingInvalidCharacters: false)
    else { return nil }
    self.init(accept: accept, link: link)
  }

  /// Validates a next-page URL without changing route, page size, or filters.
  /// - Throws: `GovInfoValidationError` for missing, empty, repeated, or invalid continuation.
  public func continuation<Page: GovInfoPage>(after page: Page) throws(GovInfoValidationError)
    -> Self?
  {
    guard page.hasNextPage else { throw .missingContinuation }
    guard let link = page.nextPage else { return nil }
    guard let url = URL(string: link, encodingInvalidCharacters: false),
      let next = Self(accept: accept, link: url), next.origin == origin,
      let currentParts = URLComponents(url: self.url, resolvingAgainstBaseURL: false),
      let nextParts = URLComponents(url: next.url, resolvingAgainstBaseURL: false),
      currentParts.percentEncodedPath == nextParts.percentEncodedPath
    else { throw .invalidLink }
    let currentItems = currentParts.queryItems ?? []
    let nextItems = nextParts.queryItems ?? []
    let cursors = nextItems.filter { $0.name == "offsetMark" }
    guard cursors.count == 1, let cursor = cursors.first?.value, !cursor.isEmpty,
      cursor != currentItems.first(where: { $0.name == "offsetMark" })?.value
    else { throw .repeatedContinuation }
    func filters(_ items: [URLQueryItem]) -> [String] {
      items.filter { $0.name != "offsetMark" }.map { $0.name + "=" + ($0.value ?? "") }.sorted()
    }
    guard filters(currentItems) == filters(nextItems) else { throw .invalidLink }
    return next
  }

  static func builtIn(path: String) -> Self {
    guard let endpoint = Self(path: path) else {
      preconditionFailure("Fixed paths with encoded parameters form valid GovInfo endpoints.")
    }
    return endpoint
  }

  static func segment(_ value: String) throws(GovInfoValidationError) -> String {
    guard !value.isEmpty, value != ".", value != "..",
      !value.unicodeScalars.contains(where: { $0.properties.generalCategory == .control })
    else { throw .invalidIdentifier }
    return value.utf8.map { byte in
      switch byte {
      case 45, 46, 48...57, 65...90, 95, 97...122, 126: String(UnicodeScalar(byte))
      default: "%" + (byte < 16 ? "0" : "") + String(byte, radix: 16, uppercase: true)
      }
    }.joined()
  }

  private static func validPath(_ value: String) -> Bool {
    guard value.hasPrefix("/"), !value.hasPrefix("//"),
      let decoded = value.removingPercentEncoding,
      !decoded.hasPrefix("//"), !decoded.contains("\\"),
      !decoded.unicodeScalars.contains(where: { $0.properties.generalCategory == .control }),
      !decoded.split(separator: "/").contains(where: { $0 == "." || $0 == ".." })
    else { return false }
    return true
  }
}

extension Endpoint where Response == DocumentMetadata {
  /// Describes one granule summary; identifiers are encoded separately.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for empty or invalid identifiers.
  public static func granule(_ granuleID: String, in packageID: String)
    throws(GovInfoValidationError) -> Self
  {
    try Self.builtIn(
      path: "/packages/" + segment(packageID) + "/granules/" + segment(granuleID) + "/summary")
  }
  /// Describes one package summary, which is metadata rather than full text.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for an empty or invalid identifier.
  public static func package(_ packageID: String) throws(GovInfoValidationError) -> Self {
    try Self.builtIn(path: "/packages/" + segment(packageID) + "/summary")
  }
}

extension Endpoint where Response == GranulePage {
  /// Describes the first page of a package's granules, including zero-granule books.
  /// - Throws: `GovInfoValidationError` for an invalid identifier or page size.
  public static func granules(in packageID: String, pageSize: Int = 100)
    throws(GovInfoValidationError) -> Self
  {
    guard (1...1000).contains(pageSize) else { throw .invalidPageSize }
    return try Self.builtIn(
      path: "/packages/" + segment(packageID) + "/granules?offsetMark=*&pageSize=\(pageSize)")
  }
}
