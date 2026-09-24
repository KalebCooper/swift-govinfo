# swift-govinfo

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Portable Swift access to official GovInfo documents, metadata, and BILLSTATUS XML.

## Status

The models and SDK implement collection discovery, package/granule metadata and lazy listings,
relationships, advertised representations, required BILLSTATUS XML, and source receipts. Local
qualification and unavailable external gates are recorded in [Implementation readiness](IMPLEMENTATION_READINESS.md).

### Historical scope

The attributed fixtures include WCPD 1993, DCPD 2009/current, PPP 1929 with zero granules, PPP 2009
full XML, FR 1936 PDF, STATUTE-1 metadata, and BILLSTATUS XML. Collection codes remain open; CPD can
contain WCPD and DCPD identifiers. Source fields, unknown values, explicit nulls, and publication versus
modification dates are retained. Book-only publications keep volume/page metadata.

A format link advertises availability; successful retrieval establishes usable bytes. MODS is not
full text, a PDF may be a scan, and BILLSTATUS is not a complete historical bill census or legal-status
resolver. Live two-page package/granule recording is still quota-blocked. Relationship and package-list
examples from official documentation are labeled separately from live API recordings. See
[Source verification](Documentation/SOURCE_VERIFICATION.md) and
[Implementation readiness](IMPLEMENTATION_READINESS.md) for precise evidence and outstanding gates.

## Usage

```swift
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels

let client = GovInfoClient(configuration: try GovInfoConfiguration(apiKey: key))
let book = try await client.package("PPP-1929-book1")
print(book.pages ?? "Unknown")
for try await granule in try client.granules(in: "WCPD-1993-01-11", pageSize: 2) {
  print(granule.title ?? "Untitled")
}
```

Every operation also has a reusable `DocumentRequest` and a typed `Endpoint`. For example,
`value(for: .package(id))` and `send(.package(id))` use the same execution as `package(id)`.
Request construction performs no I/O. Models-only consumers can execute descriptions themselves.

Discover collections with `collections()`. Use `PackageQuery.Window.modified` for repository
modification timestamps or `.published` for publication dates, then traverse `packagePages(matching:)`
or `packages(matching:)`. `relationships(for:)` returns the provider's relationship inventory;
`relatedDocuments(at:)` follows a selected relationship link. These operations preserve source meaning
without reconciling bills, laws, and presidential documents into app-specific identities.

Select advertised content with `metadata.representation(.pdf)` or `.xml`. MODS and PREMIS remain
metadata. Retrieve bounded bytes with `representation(_:)`; parse required bulk XML with
`billStatus(at:)`. `download(for:consume:)` streams large assets to a caller-owned sink and returns a
SHA-256 receipt. Configure an explicit byte ceiling appropriate to the asset; the default is 16 MiB.

`response(for:)` and `pages(for:)` return source URL, status, response headers, byte count, and an
optional exact body from the same request. Enable `captureBody` to keep bounded bodies. Streaming
receipts contain a digest instead. The consumer supplies retrieval timestamps and durable storage.

### Credentials and continuation

Supply an explicit API.data.gov key. It is sent only in the API origin's `X-Api-Key` header, never in a
URL or to public content endpoints. Redirects are refused. Requests send once by default; inject a
bounded retry policy and clock to opt into networking-layer retries. HTTP errors retain quota and
`Retry-After` headers. Streaming operations send once even with a retry policy.

Package/granule iterators follow validated `nextPage`/`offsetMark` links without offset arithmetic,
prefetch, sorting, or deduplication. Each iterator is independent. Invalid, missing, or cyclic
continuation fails before yielding the affected page. A failed or interrupted traversal does not
establish a complete inventory. Single-response request execution remains available.

## Example

The iOS demo in `Examples/SwiftGovInfoDocumentsDemo` loads the recorded historical book offline and
provides opt-in live package/granule retrieval with an in-memory key. See its README for launch steps.

## Products

| Product | Purpose |
| --- | --- |
| SwiftGovInfoDocumentsModels | Dependency-free source models, typed requests/endpoints, pure XML decoding, and receipts |
| SwiftGovInfoDocuments | Authenticated API execution, lazy package/granule traversal, representations, and streamed downloads |

## Requirements

Swift 6, tools 6.2, and iOS, macOS, tvOS, visionOS, or watchOS 26. Portable consumers inject a transport
and can enable the `HTTPPortable` trait. swifty-networking requires public version 1.3.1 or later.
The SDK uses Swift Crypto for portable streaming SHA-256; models have no third-party dependencies.

## Installation

This package is not released yet. Add this directory as a local Swift package dependency and select
either product.

## License

MIT. See [LICENSE](LICENSE). Official fixture URLs, retrieval timestamps, response headers, byte counts,
and SHA-256 digests accompany every body in `Sources/SwiftGovInfoDocumentsTestSupport/Fixtures`.
