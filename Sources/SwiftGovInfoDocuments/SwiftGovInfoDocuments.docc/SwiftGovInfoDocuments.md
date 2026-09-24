# ``SwiftGovInfoDocuments``

Retrieve official GovInfo documents and metadata with typed operations and source receipts.

## Overview

```swift
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels

let client = GovInfoClient(configuration: try GovInfoConfiguration(apiKey: key))
let book = try await client.package("PPP-1929-book1")
for try await granule in try client.granules(in: "WCPD-1993-01-11", pageSize: 2) {
  print(granule.title ?? "Untitled")
}
```

Everyday methods, `DocumentRequest` factories, and `Endpoint` values share execution. One-response
execution remains available for every listing. The independent models product can be used with a
consumer's own executor. On Apple platforms the convenience initializer uses URLSession; portable
consumers inject an HTTPCore transport, optionally enabling the package's HTTPPortable trait.

Required credentials have no default. API requests use X-Api-Key on the API origin only; public content
requests carry no API key. Redirects are refused. Configuration never reads environment variables or
stores a key persistently. The library performs no I/O until execution or iterator advancement.

## Topics

### Client and execution

- ``GovInfoClient``
- ``GovInfoConfiguration``
- ``GovInfoError``

### Discovery and source capture

- <doc:DiscoveryAndPagination>
- <doc:RepresentationsAndReceipts>
- ``GovInfoItemSequence``
- ``GovInfoPageSequence``
