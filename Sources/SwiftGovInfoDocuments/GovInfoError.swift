// Consumers can name the transport types used by the public client initializer and failures.
@_exported import HTTPCore
import SwiftGovInfoDocumentsModels

/// A typed GovInfo execution failure.
///
/// Inspect `httpStatus` for quotas or generated-asset Retry-After. No retry is implicit.
public enum GovInfoError: Error, Sendable {
  /// The response exceeds the configured byte limit.
  case bodyTooLarge
  /// The streaming consumer could not persist a chunk; no completed receipt is returned.
  case consumerFailure
  /// An XML or other non-JSON source codec rejected the body.
  case decoding(GovInfoDecodingError)
  /// The provider rejected the request; response metadata is retained.
  case httpStatus(code: Int, headers: [String: String])
  /// Credentials are empty or contain control characters.
  case invalidCredentials
  /// The networking layer failed, including cancellation and decoding.
  case transport(TransportError)
  /// The returned bytes do not match the requested representation.
  case unexpectedContent
  /// A request or continuation failed validation.
  case validation(GovInfoValidationError)

  init(_ error: TransportError) {
    if case .httpStatus(_, let code, let headers) = error {
      self = .httpStatus(
        code: code, headers: headers.reduce(into: [:]) { $0[$1.name.canonicalName] = $1.value })
    } else if case .decode(let underlying) = error, let service = underlying as? GovInfoError {
      self = service
    } else {
      self = .transport(error)
    }
  }
}
