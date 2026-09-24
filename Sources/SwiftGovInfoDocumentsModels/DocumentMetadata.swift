#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Package or granule metadata, with all collection-specific fields retained.
///
/// `metadata.dateIssued` describes publication; `metadata.lastModified` describes a repository
/// revision. Neither establishes the date of every action within a historical volume.
/// Download links advertise formats, not successful retrieval or complete historical coverage.
public struct DocumentMetadata: Codable, Hashable, Sendable {
  /// Every source field, including unknown keys and explicit nulls.
  public let fields: [String: JSONValue]

  /// The summary's collection code, which may differ from its discovery collection.
  public var collectionCode: CollectionCode? {
    fields["collectionCode"]?.string.map(CollectionCode.init(rawValue:))
  }
  /// The source publication date, without timezone or calendar inference.
  public var dateIssued: String? { fields["dateIssued"]?.string }
  /// Available format links, preserving future formats and explicit null values.
  public var download: [String: JSONValue]? {
    if case .object(let values) = fields["download"] { return values }
    return nil
  }
  /// The optional granule identity; packages are not assigned invented granules.
  public var granuleID: String? { fields["granuleId"]?.string }
  /// The source's repository modification instant, unmodified.
  public var lastModified: String? { fields["lastModified"]?.string }
  /// The package identity, absent from some granule listing entries.
  public var packageID: String? { fields["packageId"]?.string }
  /// The number of pages as source text; no numeric conversion or default.
  public var pages: String? { fields["pages"]?.string }
  /// The source title.
  public var title: String? { fields["title"]?.string }
  /// The source volume label, independent of contents-level dates.
  public var volume: String? { fields["volume"]?.string }

  /// Creates metadata while preserving every supplied field.
  public init(fields: [String: JSONValue]) { self.fields = fields }
  /// Decodes a metadata object without discarding collection-specific fields.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
  }
  /// Encodes the original metadata fields.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
