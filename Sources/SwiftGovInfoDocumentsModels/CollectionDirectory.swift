/// The directory of collections currently exposed by GovInfo.
///
/// Counts are repository holdings at retrieval, not a historical census.
public struct CollectionDirectory: Codable, Hashable, Sendable {
  /// Collections in provider order.
  public let collections: [CollectionInfo]
  /// Every directory field, including future provider metadata.
  public let fields: [String: JSONValue]

  /// Decodes the directory without discarding unknown fields.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    collections = try container.decode([CollectionInfo].self, forKey: .collections)
  }

  /// Encodes the complete source directory.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey { case collections }
}

/// A collection's source name, open identifier, and reported counts.
///
/// A null granule count remains distinct from zero through the original fields.
public struct CollectionInfo: Codable, Hashable, Sendable {
  /// The collection's open identifier.
  public let collectionCode: CollectionCode
  /// The provider's display name.
  public let collectionName: String
  /// Every source field, including explicit null counts.
  public let fields: [String: JSONValue]
  /// The reported granule count, if supplied.
  public let granuleCount: Int?
  /// The reported package count.
  public let packageCount: Int

  /// Decodes all collection metadata without discarding unknown fields.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    collectionCode = try container.decode(CollectionCode.self, forKey: .collectionCode)
    collectionName = try container.decode(String.self, forKey: .collectionName)
    granuleCount = try container.decodeIfPresent(Int.self, forKey: .granuleCount)
    packageCount = try container.decode(Int.self, forKey: .packageCount)
  }

  /// Encodes every source field.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey {
    case collectionCode, collectionName, granuleCount, packageCount
  }
}

/// A page of packages discovered by publication date or modification time.
///
/// Dates are retained as the provider returned them, without deriving contents-level dates.
public struct PackagePage: Codable, GovInfoPage, Hashable, Sendable {
  /// The provider's reported count.
  public let count: Int
  /// All envelope fields, including null and future metadata.
  public let fields: [String: JSONValue]
  /// Whether the provider supplied the continuation key.
  public var hasNextPage: Bool { fields.keys.contains("nextPage") }
  /// Packages in provider order.
  public var items: [DocumentMetadata] { packages }
  /// The unmodified next-page link.
  public var nextPage: String? { fields["nextPage"]?.string }
  /// Packages in provider order.
  public let packages: [DocumentMetadata]

  /// Decodes the envelope and validates the continuation's JSON type.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = try container.decode(Int.self, forKey: .count)
    packages = try container.decode([DocumentMetadata].self, forKey: .packages)
    _ = try container.decodeIfPresent(String.self, forKey: .nextPage)
  }

  /// Encodes the complete original envelope.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey { case count, nextPage, packages }
}
