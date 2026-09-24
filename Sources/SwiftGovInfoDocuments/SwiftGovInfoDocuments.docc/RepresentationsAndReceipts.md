# Retrieving representations and preserving receipts

Distinguish metadata, full document bytes, and the receipt of a completed download.

## Advertised representations

```swift
let book = try await client.package("PPP-1929-book1")
if let pdf = try book.representation(.pdf) {
  let content = try await client.representation(pdf)
  print(content.data.count)
}
```

A missing or null format link returns nil. Malformed links fail validation. MODS and PREMIS describe
or preserve a publication; they are not its full text. HTML, PDF, document XML, USLM, and ZIP retain
their distinct format choices. A historical PDF may be a scan. A format is usable only after a
successful response supplies bytes; an advertised link alone does not prove that.

For a published `www.govinfo.gov/bulkdata/BILLSTATUS/...xml` link, `billStatus(at:)` decodes a bounded
source-specific XML document. `value(for: .billStatus(at: url))` and `send(.billStatus(at: url))`
provide equivalent typed execution. Bill identity and the complete ordered source tree remain
available. No JSON decoder is used for XML.

## Bounded receipts

Configure `captureBody: true` to retain the exact bytes used for a decoded response. Then
`response(for:)` returns the source URL, status, headers, byte count, decoded value, and body without
an extra request. Page sequences return the same receipt shape for each actual page URL. With capture
disabled, body is nil; the receipt still describes the response. A consumer owns its clock, retrieval
time, archival hashes, and durable storage. Source bytes can contain information absent from a parsed
tree, including XML comments and original lexical spelling.

`maximumResponseBytes` defaults to 16 MiB and is enforced while reading the transport stream. Select
a larger explicit limit for a known large asset. JSON and parsed XML operations buffer their bounded
body; the XML decoder independently caps input at 16 MiB, 256 nested elements, and 250,000 elements.

## Streaming an asset

```swift
if let pdf = try book.representation(.pdf) {
  let receipt = try await client.download(for: .representation(pdf)) { chunk in
    try await destination.append(chunk)
  }
  print(receipt.value.sha256, receipt.byteCount)
}
```

`destination` above is a caller-owned actor or another Sendable sink. The SDK holds a transport chunk
and a bounded signature prefix, computes SHA-256 incrementally, and returns a digest only after the
whole response and every consumer write succeed. Body capture stays nil for streaming. Format checks
reject common HTML error pages returned for XML/PDF/ZIP. They do not constitute full PDF/ZIP/XML
validation. Failure or cancellation may leave partial output in the sink; the consumer owns rollback
and atomic publication. Streaming sends once, regardless of the client's retry policy.

## Failure and retry

`GovInfoError.httpStatus` retains status and headers, including quota and Retry-After. Generated assets
may return 503. Default execution sends once. Callers can opt into a bounded HTTPCore retry policy and
inject a clock; only the networking layer retries. Do not treat a quota failure, malformed response,
cancelled download, or partial traversal as a successful complete source record.
