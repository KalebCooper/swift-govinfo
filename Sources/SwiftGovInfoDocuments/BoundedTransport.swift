#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes

struct BoundedTransport: Transport {
  let base: any Transport
  let limit: Int

  func stream(_ request: HTTPRequest, body: TransportBody, options: TransportOptions)
    async throws(TransportError) -> StreamedResponse
  {
    let response = try await base.stream(request, body: body, options: options)
    return StreamedResponse(
      body: StreamedBody(BoundedBody(base: response.body, limit: limit), mapFailure: { $0 }),
      headers: response.headers, status: response.status)
  }
}

private struct BoundedBody: AsyncSequence, Sendable {
  typealias Element = Data
  typealias Failure = TransportError

  struct Iterator: AsyncIteratorProtocol {
    var base: StreamedBody.Iterator
    var finished = false
    var remaining: Int

    mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(TransportError) -> Data?
    {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .cancelled }
      guard let chunk = try await base.next(isolation: actor) else { return nil }
      guard chunk.count <= remaining else { throw .decode(underlying: GovInfoError.bodyTooLarge) }
      remaining -= chunk.count
      finished = false
      return chunk
    }
  }

  let base: StreamedBody
  let limit: Int

  func makeAsyncIterator() -> Iterator {
    Iterator(base: base.makeAsyncIterator(), remaining: limit)
  }
}
