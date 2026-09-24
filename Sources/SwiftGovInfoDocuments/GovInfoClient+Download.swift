#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Crypto
import HTTPCore
import SwiftGovInfoDocumentsModels

extension GovInfoClient {
  /// Streams a representation to a consumer and returns its complete SHA-256 receipt.
  ///
  /// The response size limit still applies, but memory holds only the current transport chunk.
  /// A failed or cancelled stream never produces a successful receipt. The consumer owns file
  /// creation, rollback, retrieval timestamps, and durable storage. Streaming requests send once.
  ///
  /// - Parameters:
  ///   - request: The advertised representation request.
  ///   - consume: A caller-provided sink for each ordered chunk.
  /// - Returns: A receipt with a digest and total byte count; body capture is always nil.
  /// - Throws: `GovInfoError` for source, consumer, transport, or cancellation failures.
  public func download(
    for request: DocumentRequest<DocumentContent>, consume: @Sendable (Data) async throws -> Void
  ) async throws(GovInfoError) -> SourceResponse<ContentDigest> {
    try await download(request.endpoint, consume: consume)
  }

  /// Streams one validated content endpoint with the same receipt and errors as download(for:consume:).
  public func download(
    _ endpoint: Endpoint<DocumentContent>, consume: @Sendable (Data) async throws -> Void
  ) async throws(GovInfoError) -> SourceResponse<ContentDigest> {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    do {
      let response = try await httpClient(for: endpoint).streamResponse(networkRequest(endpoint))
      var byteCount = 0
      var digest = SHA256()
      var prefix = Data()
      var validatedPrefix = false
      for try await chunk in response.body {
        guard !Task.isCancelled else { throw GovInfoError.transport(.cancelled) }
        if !validatedPrefix {
          prefix.append(chunk.prefix(512 - prefix.count))
          if prefix.count == 512 {
            try Self.validateContentPrefix(prefix, accept: endpoint.accept)
            validatedPrefix = true
          }
        }
        try await consume(chunk)
        byteCount += chunk.count
        digest.update(data: chunk)
      }
      guard !Task.isCancelled else { throw GovInfoError.transport(.cancelled) }
      if !validatedPrefix { try Self.validateContentPrefix(prefix, accept: endpoint.accept) }
      let hash = digest.finalize().map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
      return SourceResponse(
        body: nil, byteCount: byteCount,
        headers: response.headers.reduce(into: [:]) { $0[$1.name.canonicalName] = $1.value },
        status: response.status.code, url: endpoint.url, value: ContentDigest(sha256: hash))
    } catch let error as GovInfoError {
      throw error
    } catch let error as TransportError {
      throw GovInfoError(error)
    } catch {
      throw .consumerFailure
    }
  }
}
