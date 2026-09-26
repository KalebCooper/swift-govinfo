# Changelog

## Unreleased

### Added

- Independent SwiftGovInfoDocumentsModels and SwiftGovInfoDocuments products, using public
  swifty-networking 1.3.1 and optional HTTPPortable transport support.
- Package and granule detail, collection discovery, modified/published package listings, related
  records, and advertised content/metadata representations through three typed API levels.
- Independent lazy package/granule pages and items, validated opaque continuation, cancellation,
  typed errors, explicit credentials, bounded receipts, and streamed SHA-256 downloads.
- Pure bounded BILLSTATUS and source XML decoding that retains the source tree and bill identity.
- Attributed current/historical fixtures, deterministic tests, models-first DocC, and an iOS demo.
- Source and receipt verification with planted violations, plus a non-overwriting opt-in recorder.

### Changed

- The default repository gate now validates implemented source and recorded evidence instead of
  scaffold infrastructure. Platform and hosted delivery limitations remain explicitly documented.

### Fixed

- Link system zlib on Android so FoundationXML can load when decoding document XML.
