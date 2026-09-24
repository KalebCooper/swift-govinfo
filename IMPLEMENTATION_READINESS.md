# Implementation readiness

## Implemented source boundary

`SwiftGovInfoDocumentsModels` and `SwiftGovInfoDocuments` are implemented independent products.
The models target has no third-party dependencies. The SDK uses public swifty-networking 1.3.1,
swift-http-types, and Swift Crypto for incremental SHA-256. Default and HTTPPortable graphs resolve
from public sources; the checked-in lockfile retains the portable superset.

Implemented vertical slices include package/granule detail; lazy package/granule pages and items;
collection discovery; modification/publication windows; relationship directories and linked records;
advertised metadata/content representations; pure BILLSTATUS/source XML decoding; bounded response
receipts and streamed asset receipts. All operations have everyday, request, and endpoint access.

Current/historical source bodies, complete provenance receipts, deterministic Swift Testing targets,
models-first DocC catalogs, and a local-package iOS demo are present. Test-support resources are not
part of either public library product. SDK code contains no environment access, wall-clock reads,
unsafe code, UI framework, persistence, cross-provider joins, or eager whole-history fetch.

## Verification record

Library verification passed: source/receipt checks, 51 source-checker planted-violation arms and
7 receipt-checker negative arms, 42 macOS cases through Xcode MCP, and 36 test functions in nine
suites in each Linux trait configuration. The fresh iOS package build and models-first DocC
conversion/merge/static output passed, with zero documentation warnings. The iOS demo builds for
26.5; its runtime check remains in progress. Final evidence paths and unavailable gates will be
recorded with the demo qualification commit.

## Source qualification and coverage

See [Source verification](Documentation/SOURCE_VERIFICATION.md) for official API links, verified
public dependency tags, credentials, quotas, format availability, exact sample inventory, and the
recorded 429. Additional API recording must honor its Retry-After or use an authorized key.

A successful current second package/granule page and modern live relationships remain unavailable;
official published examples and explicit in-memory envelope mutations are labeled accordingly.
BILLSTATUS and document samples do not establish every bill, vote, law, presidential action, or
historical format. Bulk-directory enumeration and the combined NARA/GovInfo all-administration and
early-Congress source inventory remain separate coordinated work. Neither SDK depends on the other.

## Delivery boundaries

The repository-check CI lane validates actual source and fixture receipts. Platform/documentation
workflow definitions retain the two Apple entries, Android pins/cold-boot arguments, and provisional
timeouts, but remain disabled pending outstanding qualification. No remote, push, hosted CI run,
GitHub Pages deployment, tag, release object, or signed external consumer is established by these
local checks. No sibling repository or shared plan is changed by this delivery.
