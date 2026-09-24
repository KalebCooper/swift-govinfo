/// A provider envelope that exposes items and an explicit continuation field.
///
/// A missing `nextPage` is malformed for built-in paginated operations; a JSON null terminates.
public protocol GovInfoPage: Decodable, Sendable {
  /// The type of one item in source order.
  associatedtype Item: Sendable
  /// Whether the provider included the continuation key, even when null.
  var hasNextPage: Bool { get }
  /// The ordered items; no filtering or deduplication.
  var items: [Item] { get }
  /// The provider's next URL, or nil for an explicit terminal null.
  var nextPage: String? { get }
}

/// A complete granule listing page, including book-only empty results.
///
/// A zero count says the package has no granules; it does not say the book lacks content.
public struct GranulePage: Codable, GovInfoPage, Hashable, Sendable {
  /// The reported total count.
  public let count: Int
  /// Every source field, preserving null offset and future metadata.
  public let fields: [String: JSONValue]
  /// Granules in source order.
  public let granules: [DocumentMetadata]
  /// The explicit continuation's presence.
  public var hasNextPage: Bool { fields.keys.contains("nextPage") }
  /// Granules in source order.
  public var items: [DocumentMetadata] { granules }
  /// The unmodified next-page link.
  public var nextPage: String? { fields["nextPage"]?.string }

  /// Decodes the envelope, rejecting a non-string, non-null continuation.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = try container.decode(Int.self, forKey: .count)
    granules = try container.decode([DocumentMetadata].self, forKey: .granules)
    _ = try container.decodeIfPresent(String.self, forKey: .nextPage)
  }
  /// Encodes every original envelope field.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
  private enum CodingKeys: String, CodingKey { case count, granules, nextPage }
}
