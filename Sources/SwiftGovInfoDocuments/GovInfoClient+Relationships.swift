#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftGovInfoDocumentsModels

extension GovInfoClient {
  /// Retrieves records from a source-published relationship link.
  /// - Throws: `GovInfoError` for link validation, source, transport, or decoding failures.
  public func relatedDocuments(at url: URL) async throws(GovInfoError) -> RelatedDocuments {
    let request: DocumentRequest<RelatedDocuments>
    do { request = try .relatedDocuments(at: url) } catch { throw .validation(error) }
    return try await value(for: request)
  }

  /// Retrieves relationship kinds for a package or granule access identifier.
  /// - Throws: `GovInfoError` for identifier validation, source, transport, or decoding failures.
  public func relationships(for accessID: String) async throws(GovInfoError)
    -> RelationshipDirectory
  {
    let request: DocumentRequest<RelationshipDirectory>
    do { request = try .relationships(for: accessID) } catch { throw .validation(error) }
    return try await value(for: request)
  }
}
