# ``SwiftGovInfoDocumentsModels``

Portable GovInfo source models, typed endpoints, immutable requests, and pure XML decoding.

## Overview

Package summaries describe publications; granules describe their constituent records. Historical
books may expose no granules. Preserve publication and modification dates separately, and use
volume/page metadata for book-only access. JSON models keep all source fields and explicit nulls.
Collection codes are open RawRepresentable values, so future provider codes survive decoding.

```swift
let request = try DocumentRequest.package("PPP-1929-book1")
let endpoint = try Endpoint<GranulePage>.granules(in: "WCPD-1993-01-11", pageSize: 2)
```

Construction performs no I/O. A custom executor can inspect the public request resolution and
endpoint. API credentials belong in SDK configuration and HTTP headers, never in model URLs.
Unknown JSON fields are retained as `JSONValue`; numeric values use Decimal instead of a lossy
Double conversion. Missing fields and explicit nulls remain distinguishable in the original fields.

## XML and historical content

`BillStatus.decode(_:)` reads the required UTF-8 bulk document with typed bill identity and a complete
ordered XML tree. `GovInfoXML.decode(_:)` reads MODS or full-document XML into a bounded tree without
pretending Codable decodes XML. FoundationXML is a conditional system import on portable platforms;
Apple uses the Foundation parser. Neither decoder has networking dependencies or performs I/O.

Both reject DTD/entity declarations, malformed input, unsupported encodings, and byte/depth/node limit
violations. Mixed text, CDATA text, attributes, empty elements, and unknown source elements are kept.
The original body is needed for exact lexical reconstruction, comments, and processing instructions.

A `DocumentContent` holds representation bytes rather than a metadata record. `RepresentationFormat`
distinguishes MODS/PREMIS metadata from full-document formats. In the historical samples, PPP 1929 has
870 pages and zero granules, PPP 2009 provides deeply nested document XML, and FR 1936 supplies PDF.
STATUTE metadata and BILLSTATUS XML remain source evidence rather than a legal-status resolver.

## Topics

### Discovery and metadata

- ``CollectionCode``
- ``CollectionDirectory``
- ``CollectionInfo``
- ``DocumentMetadata``
- ``DocumentRelationship``
- ``GranulePage``
- ``JSONValue``
- ``PackagePage``
- ``PackageQuery``
- ``RelatedDocuments``
- ``RelationshipDirectory``

### Requests and receipts

- ``ContentDigest``
- ``DocumentRequest``
- ``Endpoint``
- ``GovInfoPage``
- ``GovInfoValidationError``
- ``SourceResponse``

### Representations and source XML

- ``BillStatus``
- ``DocumentContent``
- ``GovInfoDecodingError``
- ``GovInfoSourceDecodable``
- ``GovInfoXML``
- ``GovInfoXMLNode``
- ``RepresentationFormat``
