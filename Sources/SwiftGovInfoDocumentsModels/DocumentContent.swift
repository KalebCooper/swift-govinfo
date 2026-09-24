#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The complete bytes of a bounded document representation, distinct from metadata.
///
/// Decode text with its source encoding or use `GovInfoXML.decode` for an XML tree.
public struct DocumentContent: GovInfoSourceDecodable, Hashable, Sendable {
  /// Exact source bytes.
  public let data: Data
  /// Retains the source bytes without pretending that metadata is full text.
  public static func decode(_ data: Data) throws(GovInfoDecodingError) -> Self { Self(data: data) }
}

/// The provider's bounded, documented format choices.
///
/// A format link advertises availability. Only successful retrieval establishes usable bytes.
public enum RepresentationFormat: String, CaseIterable, Codable, Hashable, Sendable {
  /// HTML or text as advertised by txtLink.
  case html
  /// MODS descriptive metadata, not document full text.
  case mods
  /// A PDF document, potentially a historical scan.
  case pdf
  /// PREMIS preservation metadata, not document full text.
  case premis
  /// United States Legislative Markup XML.
  case uslm
  /// Full document XML where supplied.
  case xml
  /// A ZIP archive, potentially generated on demand.
  case zip

  /// Whether this format describes the publication rather than supplying full text.
  public var isMetadata: Bool { self == .mods || self == .premis }

  /// The Accept media type for this representation.
  public var mediaType: String {
    switch self {
    case .html: "text/html"
    case .mods, .premis, .uslm, .xml: "application/xml"
    case .pdf: "application/pdf"
    case .zip: "application/zip"
    }
  }

  var linkKey: String { self == .html ? "txtLink" : rawValue + "Link" }
}

extension DocumentMetadata {
  /// Resolves a format actually advertised by this source summary.
  /// - Returns: A validated representation endpoint, or nil for a missing or explicit null link.
  /// - Throws: `GovInfoValidationError.invalidLink` when an advertised link is unusable.
  public func representation(_ format: RepresentationFormat) throws(GovInfoValidationError)
    -> Endpoint<DocumentContent>?
  {
    guard let value = download?[format.linkKey], value != .null else { return nil }
    guard let string = value.string,
      let url = URL(string: string, encodingInvalidCharacters: false),
      let endpoint = Endpoint<DocumentContent>(accept: format.mediaType, link: url)
    else { throw .invalidLink }
    return endpoint
  }
}

extension Endpoint where Response == BillStatus {
  /// Describes a published BILLSTATUS bulk XML file without inventing a date or bill version.
  /// - Throws: `GovInfoValidationError.invalidLink` for another origin or path.
  public static func billStatus(at url: URL) throws(GovInfoValidationError) -> Self {
    guard let endpoint = Self(accept: "application/xml", link: url),
      endpoint.origin == "https://www.govinfo.gov",
      endpoint.path.hasPrefix("/bulkdata/BILLSTATUS/"), endpoint.path.hasSuffix(".xml")
    else { throw .invalidLink }
    return endpoint
  }
}

extension DocumentRequest where Response == BillStatus {
  /// Describes a verified BILLSTATUS source link.
  /// - Throws: `GovInfoValidationError.invalidLink` for another origin or path.
  public static func billStatus(at url: URL) throws(GovInfoValidationError) -> Self {
    try Self(endpoint: .billStatus(at: url))
  }
}

extension DocumentRequest where Response == DocumentContent {
  /// Describes a representation already selected from published metadata.
  public static func representation(_ endpoint: Endpoint<DocumentContent>) -> Self {
    Self(endpoint: endpoint)
  }
}
