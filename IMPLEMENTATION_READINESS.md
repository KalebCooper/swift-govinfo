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

Local validation completed September 23, 2026 (America/Chicago). Apple gates used Xcode 27.0 and
Apple Swift 6.4; Linux used the pinned `swift:6.3-noble` image (Swift 6.3.3). The declared tools floor
remains Swift 6.2 as a manifest declaration. Apple qualification uses Xcode 27 only.

| Gate | Result | Evidence |
| --- | --- | --- |
| Repository/source/strict formatting | Pass | `bash Scripts/verify.sh`, `.build/precommit-source.log` |
| Checker discrimination | Pass | 51 source arms and 7 receipt negative arms; `.build/precommit-selftest.log` |
| Recorded bodies | Pass | 20 receipt/body pairs; byte counts, SHA-256, source URLs, timestamps and extraction parents verified |
| macOS tests through Xcode MCP | Pass | 42 cases, zero failures/skips; `RunAllTests/98940DBE-8DB1-4AAB-97C7-03DC296C744D.txt` |
| iOS package build through Xcode MCP | Pass | iPhone 18 Pro; `BuildProject/BuildProject-Log-20260923-215133.txt` |
| Linux default and HTTPPortable | Pass | 36 test functions in nine suites in each mode, including seven parameterized fixture cases; `.build/linux-final.log`, exit 0 |
| DocC | Pass | 224 models and 111 SDK symbols; both catalogs converted with warnings as errors, merged and transformed for static hosting; `.build/docc-final`, zero diagnostics |
| iOS demo build through Xcode MCP | Pass | iPhone 17 Pro (26.5); `BuildProject/BuildProject-Log-20260923-215424.txt` |
| Demo source/project | Pass | Strict Swift formatting, plist validation, target floor 26.0/Swift 6, local package references, format 77, copied fixture/receipt identical to canonical evidence |
| iOS tests | Unavailable result | Earlier simulator test operation stalled; no passing iOS test result is claimed |
| Demo runtime | Unavailable result | iOS 27 launch timed out earlier; final iOS 26.5 launch produced no result before the 360-second helper deadline; StopProject reported no running app |
| Android | Unavailable | No adb/Android SDK found; `swift sdk list` reports no installed Swift SDKs |
| Hosted CI, release and publication | Not performed | No remote, push, tag, release, Pages publication, or signed external consumer |

Xcode artifact paths above are relative to this machine's temporary `ActionArtifacts/default`
directory. `.build` logs and generated documentation are local artifacts, not committed products.
The macOS count includes each parameterized fixture case; Linux's summary counts its test function
once. The suites exercise three API levels, custom responses, source receipts/capture opt-out,
independent lazy traversal, no prefetch, cancellation, malformed/cyclic continuation, retry headers,
streaming hashes and failures, nulls/unknown fields, book-only metadata, and XML safety limits.

The app connector eventually returned `Transport closed`. A direct MCP bridge and a GovInfo-only
workspace close/reopen plus explicit generated-scheme selection restored final macOS/build checks.
No shared Xcode service was restarted and no sibling workspace was closed. The final cleanup confirmed
that both owned workspaces were closed; only the unrelated Idler workspace remained. Xcode's newer
project format rewrite was restored to 77 after closure because MCP has no project-format setter.
No simulator runtime success is inferred from either a build or that cleanup.

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
workflow definitions retain the Xcode 27 Apple lane, Android pins/cold-boot arguments, and provisional
timeouts, but remain disabled pending outstanding qualification. No remote, push, hosted CI run,
GitHub Pages deployment, tag, release object, or signed external consumer is established by these
local checks. No sibling repository or shared plan is changed by this delivery.
