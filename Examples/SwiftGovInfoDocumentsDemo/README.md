# GovInfo document example

Open `SwiftGovInfoDocumentsDemo.xcodeproj`, select the generated app scheme and an iOS 26 or newer
simulator, then run. Close the standalone package workspace first so Xcode resolves one package copy.
The app depends on the repository by local path and demonstrates both public products.

At launch it loads the attributed `PPP-1929-book1` recording without network access. The screen shows
publication date, modification timestamp, and page count, with book-only content kept distinct from
granules. The copied fixture and its receipt match the canonical test-support recording.

To make live requests, enter your API.data.gov key and a package identifier, then choose Retrieve
metadata and first granule page. Keys remain in memory and are never saved or logged. A failed request
shows an error rather than claiming a complete granule inventory. This example intentionally requests
only the first page; use the package's lazy traversal APIs for ingestion.

Build and runtime evidence, including any unavailable simulator gate, is recorded in the repository's
`IMPLEMENTATION_READINESS.md`. A successful build alone does not establish a successful app launch.
