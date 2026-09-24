import HTTPCore
import SwiftGovInfoDocumentsModels

/// Independent, nonprefetching pages with the receipt of each exact response.
///
/// Use `for try await response in client.pages(for: request)` to retain provenance during import.
/// Invalid continuation is rejected before yielding the affected page. Failures terminate iteration.
public struct GovInfoPageSequence<Page: GovInfoPage>: AsyncSequence, Sendable {
  /// One provider page with its response receipt.
  public typealias Element = SourceResponse<Page>
  /// The typed service failure.
  public typealias Failure = GovInfoError

  /// An independent traversal retaining only its cursor history and current page.
  public struct Iterator: AsyncIteratorProtocol {
    /// A page with its response receipt.
    public typealias Element = SourceResponse<Page>
    /// The typed service failure.
    public typealias Failure = GovInfoError

    private var base: PageSequence<CapturedPage<Page>>.Iterator
    private var endpoint: Endpoint<Page>
    private var finished = false
    private let followsLinks: Bool
    private var seen: Set<String>

    init(sequence: GovInfoPageSequence) {
      base = sequence.base.makeAsyncIterator()
      endpoint = sequence.endpoint
      followsLinks = sequence.followsLinks
      seen = [Self.cursor(in: sequence.endpoint)]
    }

    /// Fetches one page, validating its continuation before returning it.
    /// - Throws: `GovInfoError.validation` for invalid or repeated continuation and service failures.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(GovInfoError) -> Element?
    {
      guard !finished else { return nil }
      finished = true
      let captured: CapturedPage<Page>
      do throws(TransportError) {
        guard let response = try await base.next(isolation: actor) else { return nil }
        captured = response.value
      } catch { throw GovInfoError(error) }
      let receipt = SourceResponse(
        body: captured.body, byteCount: captured.byteCount, headers: captured.headers,
        status: captured.status, url: endpoint.url, value: captured.value)
      if followsLinks {
        do throws(GovInfoValidationError) {
          if let next = try endpoint.continuation(after: captured.value) {
            guard seen.insert(Self.cursor(in: next)).inserted else { throw .repeatedContinuation }
            endpoint = next
            finished = false
          }
        } catch { throw .validation(error) }
      }
      return receipt
    }

    private static func cursor(in endpoint: Endpoint<Page>) -> String {
      URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)?.queryItems?
        .first(where: { $0.name == "offsetMark" })?.value ?? ""
    }
  }

  private let base: PageSequence<CapturedPage<Page>>
  private let endpoint: Endpoint<Page>
  private let followsLinks: Bool

  init(client: GovInfoClient, request: DocumentRequest<Page>) {
    endpoint = request.endpoint
    let followsLinks: Bool
    switch request.resolution {
    case .endpoint: followsLinks = false;
    case .pages: followsLinks = true
    }
    self.followsLinks = followsLinks
    let initial = request.endpoint
    base = client.httpClient(for: initial).pages(
      client.networkRequest(initial), as: CapturedPage<Page>.self,
      decode: { response in
        let receipt = try await client.decoded(response, endpoint: initial)
        return CapturedPage(
          body: receipt.body, byteCount: receipt.byteCount, headers: receipt.headers,
          status: receipt.status, value: receipt.value)
      }
    ) { page, request in
      guard followsLinks, let current = Endpoint<Page>(path: request.path),
        let next = try? current.continuation(after: page.value.value)
      else { return nil }
      var request = request
      request.path = next.path
      return .request(request)
    }
  }

  /// Creates a traversal without sending a request.
  public func makeAsyncIterator() -> Iterator { Iterator(sequence: self) }
}

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct CapturedPage<Page: GovInfoPage>: Sendable {
  let body: Data?
  let byteCount: Int
  let headers: [String: String]
  let status: Int
  let value: Page
}
