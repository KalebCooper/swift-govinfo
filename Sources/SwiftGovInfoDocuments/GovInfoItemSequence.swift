import SwiftGovInfoDocumentsModels

/// Lazy items in provider order, without sorting, deduplication, or prefetch.
///
/// `for try await granule in client.granules(in: id)` drains one page before requesting another.
public struct GovInfoItemSequence<Page: GovInfoPage>: AsyncSequence, Sendable {
  /// One item from a provider page.
  public typealias Element = Page.Item
  /// The typed service failure.
  public typealias Failure = GovInfoError

  /// An independent iterator with cancellation checks even while a page is buffered.
  public struct Iterator: AsyncIteratorProtocol {
    /// One item in source order.
    public typealias Element = Page.Item
    /// The typed service failure.
    public typealias Failure = GovInfoError
    private var current = [Page.Item]().makeIterator()
    private var finished = false
    private var pages: GovInfoPageSequence<Page>.Iterator

    init(pages: GovInfoPageSequence<Page>.Iterator) { self.pages = pages }

    /// Returns an item, fetching a new page only after the previous page is exhausted.
    /// - Throws: `GovInfoError`, including cancellation while items remain buffered.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(GovInfoError) -> Element?
    {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      if let item = current.next() { finished = false; return item }
      while let page = try await pages.next(isolation: actor) {
        current = page.value.items.makeIterator()
        if let item = current.next() { finished = false; return item }
      }
      return nil
    }
  }
  private let pages: GovInfoPageSequence<Page>
  init(pages: GovInfoPageSequence<Page>) { self.pages = pages }

  /// Creates a traversal without sending a request.
  public func makeAsyncIterator() -> Iterator { Iterator(pages: pages.makeAsyncIterator()) }
}
