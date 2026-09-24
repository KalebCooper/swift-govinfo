# Discovering and traversing documents

Keep publication dates, modification timestamps, and source continuation distinct.

## Collections and date windows

```swift
let directory = try await client.collections()
let query = try PackageQuery(
  pageSize: 100,
  window: .modified(
    collection: .cpd,
    from: "2026-09-01T00:00:00Z",
    through: "2026-09-23T00:00:00Z"))
for try await package in client.packages(matching: query) {
  print(package.packageID ?? "Unknown")
}
```

Use `.published(collections:from:through:)` for YYYY-MM-DD publication windows. `.modified` takes
whole-second UTC ISO 8601 timestamps and describes repository updates, including corrections to old
publications. Both require a finite ordered range and a page size from 1 through 1,000. Collection
identifiers are open values; retain the provider's collection directory instead of assuming the known
conveniences exhaust it. CPD packages can use WCPD or DCPD identifiers.

## Three API levels

```swift
let request = try DocumentRequest.package("PPP-1929-book1")
let a = try await client.package("PPP-1929-book1")
let b = try await client.value(for: request)
let c = try await client.send(request.endpoint)
```

Each call above sends once. For a listing, `value(for:)` and `send(_:)` retrieve one page.
`DocumentRequest.packages(matching:)` and `.granules(in:pageSize:)` also describe lazy traversal:
`pages(for:)` returns page receipts and `items(for:)` returns ordered records. A consumer-created
`DocumentRequest(endpoint:)` remains a single response even when its decoded value contains a next
link. Consumers can add constrained factories for their own Decodable and Sendable response types.

## Lazy traversal

Construction and iterator creation send nothing. Advancing a page iterator makes the next request;
an item iterator drains its buffered page first. Independent iterators start independently. The SDK
does not prefetch, sort, deduplicate, retry at another layer, or derive an offset from the count.
It follows the validated `nextPage` URL and opaque `offsetMark`, preserving filters and page size.

A null next link is terminal. Missing, malformed, cross-origin, credential-bearing, changed-filter,
or cyclic continuation produces a typed validation error before the affected page is yielded.
Failures terminate the iterator. Cancellation is checked before I/O and while draining buffered items.
Breaking early stops future requests. None of these interrupted states establishes complete holdings.

## Relationships

`relationships(for:)` returns the provider's relationship directory. Pass a selected
`DocumentRelationship.relationshipLink` to `relatedDocuments(at:)`. Both also have matching request
and endpoint factories. A CPD relationship may identify a presidential signing statement, but the
SDK preserves the provider's label and identifiers without inferring a comprehensive legal status.
Related responses are single documents; the SDK does not impose package pagination on them.

The current fixtures include successful initial and terminal granule responses. A live second-page
request hit a recorded quota error. Current successful two-page package/granule recording and modern
relationship recordings remain separate qualification work. Deterministic continuation tests use
explicit mutations of recorded envelopes; they do not imply additional live-source observations.
