/// An immutable GovInfo operation, inspectable and executable with any networking stack.
///
/// `let request = try DocumentRequest.package("PPP-1929-book1")` performs no I/O.
/// Consumer-defined factories use `init(endpoint:)` and retain their concrete response type.
public struct DocumentRequest<Response>: Hashable, Sendable {
  /// The operation a source executor performs.
  public enum Resolution: Hashable, Sendable {
    /// A single HTTP request, without automatic pagination.
    case endpoint(Endpoint<Response>)
    /// A first page whose validated nextPage links may be followed.
    case pages(Endpoint<Response>)
  }
  /// The pure operation description.
  public let resolution: Resolution

  /// Creates a consumer-defined single-response operation.
  public init(endpoint: Endpoint<Response>) { resolution = .endpoint(endpoint) }
  init(pages: Endpoint<Response>) { resolution = .pages(pages) }

  /// The initial independently usable HTTP endpoint.
  public var endpoint: Endpoint<Response> {
    switch resolution {
    case .endpoint(let value), .pages(let value): value
    }
  }
}

extension DocumentRequest where Response == DocumentMetadata {
  /// Describes a granule summary lookup.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for invalid identifiers.
  public static func granule(_ granuleID: String, in packageID: String)
    throws(GovInfoValidationError) -> Self
  {
    try Self(endpoint: .granule(granuleID, in: packageID))
  }
  /// Describes a package summary lookup.
  /// - Throws: `GovInfoValidationError.invalidIdentifier` for an invalid identifier.
  public static func package(_ packageID: String) throws(GovInfoValidationError) -> Self {
    try Self(endpoint: .package(packageID))
  }
}

extension DocumentRequest where Response == GranulePage {
  /// Describes a lazy granule traversal, or its first page when executed with value(for:).
  /// - Throws: `GovInfoValidationError` for an invalid identifier or page size.
  public static func granules(in packageID: String, pageSize: Int = 100)
    throws(GovInfoValidationError) -> Self
  {
    try Self(pages: .granules(in: packageID, pageSize: pageSize))
  }
}
