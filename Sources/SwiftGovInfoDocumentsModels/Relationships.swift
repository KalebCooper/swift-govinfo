#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A named, source-published relationship with an open target collection.
///
/// Follow `relationshipLink` through a validated endpoint, without title-based joins.
public struct DocumentRelationship: Codable, Hashable, Sendable {
  /// The target collection's open identifier.
  public let collection: CollectionCode
  /// Every source field, including future relationship metadata.
  public let fields: [String: JSONValue]
  /// The relationship's source label.
  public let relationship: String
  /// The unmodified source link.
  public let relationshipLink: URL

  /// Decodes an explicit relationship and retains unknown fields.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    collection = try container.decode(CollectionCode.self, forKey: .collection)
    relationship = try container.decode(String.self, forKey: .relationship)
    relationshipLink = try container.decode(URL.self, forKey: .relationshipLink)
  }

  /// Encodes every original source field.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey { case collection, relationship, relationshipLink }
}

/// Records connected by one published relationship, without invented pagination.
///
/// Results may name packages, granules, citations, or another relationship's granulesLink.
public struct RelatedDocuments: Codable, Hashable, Sendable {
  /// Every source envelope field.
  public let fields: [String: JSONValue]
  /// The source access identifier.
  public let relatedID: String
  /// Records in source order, retaining all citation and identity fields.
  public let results: [DocumentMetadata]

  /// Decodes a complete related response.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    relatedID = try container.decode(String.self, forKey: .relatedID)
    results = try container.decode([DocumentMetadata].self, forKey: .results)
  }

  /// Encodes every original source field.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey {
    case relatedID = "relatedId"
    case results
  }
}

/// The relationships explicitly published for a source access identifier.
///
/// A signing-statement relationship does not independently establish an enacted law.
public struct RelationshipDirectory: Codable, Hashable, Sendable {
  /// Every response field, including future metadata.
  public let fields: [String: JSONValue]
  /// The source access identifier.
  public let relatedID: String
  /// The published relationship kinds in provider order.
  public let relationships: [DocumentRelationship]

  /// Decodes all source fields and the relationship directory.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    relatedID = try container.decode(String.self, forKey: .relatedID)
    relationships = try container.decode([DocumentRelationship].self, forKey: .relationships)
  }

  /// Encodes every original source field.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }

  private enum CodingKeys: String, CodingKey {
    case relatedID = "relatedId"
    case relationships
  }
}

extension Endpoint where Response == RelatedDocuments {
  /// Follows a source-published relationship URL, including its nested granule lookup.
  /// - Throws: `GovInfoValidationError.invalidLink` for non-API or unrelated routes.
  public static func relatedDocuments(at url: URL) throws(GovInfoValidationError) -> Self {
    guard let endpoint = Self(link: url), endpoint.origin == "https://api.govinfo.gov",
      endpoint.path.hasPrefix("/related/")
    else { throw .invalidLink }
    return endpoint
  }
}

extension Endpoint where Response == RelationshipDirectory {
  /// Lists the available relationships for a source access identifier.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for an invalid identifier.
  public static func relationships(for accessID: String) throws(GovInfoValidationError) -> Self {
    try Self.builtIn(path: "/related/" + segment(accessID))
  }
}

extension DocumentRequest where Response == RelatedDocuments {
  /// Describes a source-published relationship traversal.
  /// - Throws: `GovInfoValidationError.invalidLink` for an invalid relationship URL.
  public static func relatedDocuments(at url: URL) throws(GovInfoValidationError) -> Self {
    try Self(endpoint: .relatedDocuments(at: url))
  }
}

extension DocumentRequest where Response == RelationshipDirectory {
  /// Describes a source's relationship directory.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for an invalid identifier.
  public static func relationships(for accessID: String) throws(GovInfoValidationError) -> Self {
    try Self(endpoint: .relationships(for: accessID))
  }
}
