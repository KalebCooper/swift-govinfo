#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Response metadata and the exact bounded body used to decode a value.
///
/// Byte capture is opt-in. Supply a retrieval instant from your application when persisting a
/// receipt; this package never reads the wall clock. Header names are lowercase.
public struct SourceResponse<Value: Sendable>: Sendable {
  /// Complete response bytes when capture was requested, otherwise nil.
  public let body: Data?
  /// The body byte count before decoding.
  public let byteCount: Int
  /// Response fields, including media type, validators, quotas, and Retry-After when provided.
  public let headers: [String: String]
  /// HTTP status code.
  public let status: Int
  /// The validated credential-free request URL.
  public let url: URL
  /// The value decoded from this response, without a second request.
  public let value: Value

  /// Creates a receipt from one completed response.
  public init(
    body: Data?, byteCount: Int, headers: [String: String], status: Int, url: URL, value: Value
  ) {
    self.body = body
    self.byteCount = byteCount
    self.headers = headers
    self.status = status
    self.url = url
    self.value = value
  }
}
