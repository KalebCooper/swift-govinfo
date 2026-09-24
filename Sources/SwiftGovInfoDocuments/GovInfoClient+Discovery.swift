import SwiftGovInfoDocumentsModels

extension GovInfoClient {
  /// Retrieves the current collection inventory in provider order.
  /// - Throws: The provider, transport, or decoding `GovInfoError` from `value(for:)`.
  public func collections() async throws(GovInfoError) -> CollectionDirectory {
    try await value(for: .collections)
  }

  /// Creates a lazy package page traversal for a validated date window.
  public func packagePages(matching query: PackageQuery) -> GovInfoPageSequence<PackagePage> {
    pages(for: .packages(matching: query))
  }

  /// Creates a lazy package item traversal without sorting or deduplication.
  public func packages(matching query: PackageQuery) -> GovInfoItemSequence<PackagePage> {
    items(for: .packages(matching: query))
  }
}
