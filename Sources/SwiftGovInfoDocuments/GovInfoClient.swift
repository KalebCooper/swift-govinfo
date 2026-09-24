#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes
import SwiftGovInfoDocumentsModels

/// A GovInfo client with explicit credentials, typed requests, and lazy collection traversal.
///
/// `try await client.package("PPP-1929-book1")` retrieves metadata, not the book's full text.
/// Redirects are refused before credentials can reach another origin. Transports must honor
/// swifty-networking's redirect options. Retry policy defaults to one attempt.
public struct GovInfoClient: Sendable {
  /// Required credentials and response capture policy.
  public let configuration: GovInfoConfiguration
  let client: HTTPClient

  /// Creates a client with an injected transport and clock.
  ///
  /// A supplied retry policy is handled once by HTTPCore, including numeric Retry-After.
  public init(
    clock: any Clock<Duration> = ContinuousClock(), configuration: GovInfoConfiguration,
    retryPolicy: RetryPolicy = .disabled, transport: any Transport
  ) {
    self.configuration = configuration
    guard let base = URL(string: "https://api.govinfo.gov") else {
      preconditionFailure("The GovInfo API has a fixed valid origin.")
    }
    client = HTTPClient(
      baseURL: base, clock: clock, redirectPolicy: .never, retryPolicy: retryPolicy,
      transport: BoundedTransport(base: transport, limit: configuration.maximumResponseBytes))
  }

  /// Retrieves a granule's metadata.
  /// - Throws: `GovInfoError` for validation, provider, decoding, or transport failures.
  public func granule(_ granuleID: String, in packageID: String) async throws(GovInfoError)
    -> DocumentMetadata
  {
    do { return try await value(for: .granule(granuleID, in: packageID)) } catch let error
      as GovInfoValidationError
    { throw .validation(error) } catch let error as GovInfoError { throw error } catch {
      preconditionFailure("Request construction and execution have typed failures.")
    }
  }

  /// Creates a lazy granule page traversal; construction sends nothing.
  /// - Throws: `GovInfoError.validation` for an invalid identifier or page size.
  public func granulePages(in packageID: String, pageSize: Int = 100) throws(GovInfoError)
    -> GovInfoPageSequence<GranulePage>
  {
    do { return pages(for: try .granules(in: packageID, pageSize: pageSize)) } catch {
      throw .validation(error)
    }
  }

  /// Creates a lazy granule item traversal preserving provider order.
  /// - Throws: `GovInfoError.validation` for invalid request inputs.
  public func granules(in packageID: String, pageSize: Int = 100) throws(GovInfoError)
    -> GovInfoItemSequence<GranulePage>
  {
    GovInfoItemSequence(pages: try granulePages(in: packageID, pageSize: pageSize))
  }

  /// Creates a lazy item traversal for a reusable paginated request.
  public func items<Page: GovInfoPage>(for request: DocumentRequest<Page>) -> GovInfoItemSequence<
    Page
  > {
    GovInfoItemSequence(pages: pages(for: request))
  }

  /// Retrieves a package summary; a book may have no individual granules.
  /// - Throws: `GovInfoError` for validation, provider, decoding, or transport failures.
  public func package(_ packageID: String) async throws(GovInfoError) -> DocumentMetadata {
    do { return try await value(for: .package(packageID)) } catch let error
      as GovInfoValidationError
    { throw .validation(error) } catch let error as GovInfoError { throw error } catch {
      preconditionFailure("Request construction and execution have typed failures.")
    }
  }

  /// Creates a lazy page traversal; custom endpoint requests yield one page only.
  public func pages<Page: GovInfoPage>(for request: DocumentRequest<Page>) -> GovInfoPageSequence<
    Page
  > {
    GovInfoPageSequence(client: self, request: request)
  }

  /// Executes a JSON request once and returns its value and source receipt.
  /// - Throws: `GovInfoError` for provider, decoding, transport, or response size failures.
  public func response<Value: Decodable & Sendable>(for request: DocumentRequest<Value>)
    async throws(GovInfoError) -> SourceResponse<Value>
  {
    let endpoint = request.endpoint
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    do throws(TransportError) {
      let response: Response = try await httpClient(for: endpoint).execute(networkRequest(endpoint))
      return try await decoded(response, endpoint: endpoint)
    } catch { throw GovInfoError(error) }
  }

  /// Executes a single independently usable JSON endpoint.
  /// - Throws: `GovInfoError` for provider, decoding, transport, or response size failures.
  public func send<Value: Decodable & Sendable>(_ endpoint: Endpoint<Value>)
    async throws(GovInfoError) -> Value
  {
    try await response(for: DocumentRequest(endpoint: endpoint)).value
  }

  /// Executes a reusable JSON operation; paginated descriptions retrieve only their first page.
  /// - Throws: The same `GovInfoError` as `send(_:)`.
  public func value<Value: Decodable & Sendable>(for request: DocumentRequest<Value>)
    async throws(GovInfoError) -> Value
  {
    try await send(request.endpoint)
  }

  func decoded<Value: Decodable & Sendable>(_ response: Response, endpoint: Endpoint<Value>)
    async throws(TransportError) -> SourceResponse<Value>
  {
    guard response.body.count <= configuration.maximumResponseBytes else {
      throw .decode(underlying: GovInfoError.bodyTooLarge)
    }
    let value = try await response.decode(Value.self, with: JSONDecoder())
    return SourceResponse(
      body: configuration.captureBody ? response.body : nil, byteCount: response.body.count,
      headers: response.headers.reduce(into: [:]) { $0[$1.name.canonicalName] = $1.value },
      status: response.status.code, url: endpoint.url, value: value)
  }

  func networkRequest<Value>(_ endpoint: Endpoint<Value>) -> Request {
    var headers = HTTPFields()
    headers[.accept] = endpoint.accept
    headers[.userAgent] = "(swift-govinfo, https://github.com/KalebCooper/swift-govinfo)"
    if endpoint.origin == "https://api.govinfo.gov", let keyName = HTTPField.Name("X-Api-Key") {
      headers[keyName] = configuration.apiKey
    }
    return Request(
      headers: headers, options: RequestOptions(redirectPolicy: .never), path: endpoint.path)
  }
}
