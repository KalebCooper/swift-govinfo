#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import SwiftGovInfoDocumentsModels

extension GovInfoClient {
  /// Retrieves and parses a BILLSTATUS bulk XML document.
  /// - Throws: `GovInfoError` for source validation, XML, size, provider, or transport failures.
  public func billStatus(at url: URL) async throws(GovInfoError) -> BillStatus {
    let request: DocumentRequest<BillStatus>
    do { request = try .billStatus(at: url) } catch { throw .validation(error) }
    return try await value(for: request)
  }

  /// Retrieves bounded representation bytes from an advertised, validated endpoint.
  /// - Throws: `GovInfoError` for content, size, provider, or transport failures.
  public func representation(_ endpoint: Endpoint<DocumentContent>) async throws(GovInfoError)
    -> DocumentContent
  {
    try await value(for: .representation(endpoint))
  }

  /// Executes a non-JSON source operation once with a receipt for the decoded bytes.
  /// - Throws: `GovInfoError.decoding` for source codec failures, or transport/provider failures.
  public func response<Value: GovInfoSourceDecodable>(for request: DocumentRequest<Value>)
    async throws(GovInfoError) -> SourceResponse<Value>
  {
    let endpoint = request.endpoint
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    let response: Response
    do throws(TransportError) {
      response = try await httpClient(for: endpoint).execute(networkRequest(endpoint))
    } catch { throw GovInfoError(error) }
    try Self.validateContentPrefix(response.body.prefix(512), accept: endpoint.accept)
    let value: Value
    do { value = try Value.decode(response.body) } catch { throw .decoding(error) }
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    return SourceResponse(
      body: configuration.captureBody ? response.body : nil, byteCount: response.body.count,
      headers: response.headers.reduce(into: [:]) { $0[$1.name.canonicalName] = $1.value },
      status: response.status.code, url: endpoint.url, value: value)
  }

  /// Executes a non-JSON source endpoint using its explicit pure codec.
  /// - Throws: The same `GovInfoError` as `response(for:)`.
  public func send<Value: GovInfoSourceDecodable>(_ endpoint: Endpoint<Value>)
    async throws(GovInfoError) -> Value
  {
    try await response(for: DocumentRequest(endpoint: endpoint)).value
  }

  /// Executes a reusable non-JSON source operation.
  /// - Throws: The same `GovInfoError` as `send(_:)`.
  public func value<Value: GovInfoSourceDecodable>(for request: DocumentRequest<Value>)
    async throws(GovInfoError) -> Value
  {
    try await send(request.endpoint)
  }

  func httpClient<Value>(for endpoint: Endpoint<Value>) -> HTTPClient {
    var source = client
    guard let url = URL(string: endpoint.origin) else {
      preconditionFailure("Validated endpoints have fixed GovInfo origins.")
    }
    source.baseURL = url
    return source
  }

  // Signature checks reject common provider error pages. XML tree validation belongs to its codec.
  static func validateContentPrefix(_ prefix: Data, accept: String) throws(GovInfoError) {
    switch accept {
    case "application/pdf":
      guard prefix.starts(with: Data("%PDF-".utf8)) else { throw .unexpectedContent }
    case "application/xml":
      var text = String(
        String(decoding: prefix, as: UTF8.self).drop {
          $0.isWhitespace || $0 == "\u{feff}"
        }
      ).lowercased()
      if text.hasPrefix("<?xml"), let end = text.range(of: "?>") {
        text = String(text[end.upperBound...].drop(while: \.isWhitespace))
      }
      guard text.hasPrefix("<"), !text.hasPrefix("<html"), !text.hasPrefix("<!doctype html"),
        !text.hasPrefix("<body"), !text.hasPrefix("<head")
      else { throw .unexpectedContent }
    case "application/zip":
      guard
        [
          [UInt8](arrayLiteral: 0x50, 0x4B, 0x03, 0x04), [0x50, 0x4B, 0x05, 0x06],
          [0x50, 0x4B, 0x07, 0x08],
        ].contains(where: prefix.starts(with:))
      else { throw .unexpectedContent }
    default: break
    }
  }
}
