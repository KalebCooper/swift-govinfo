# Implementation readiness

## Current state

This repository has infrastructure only: an empty manifest, formatting policy, license, documentation,
scaffold validation, guarded source scripts, and disabled source workflow templates. There are no
products, targets, dependencies, version pins, fixtures, DocC catalogs, demos, releases, or remote.
The explicit empty default trait is intentional; HTTPPortable is not exposed before integration.

## Networking prerequisite

Complete and validate the separate swifty-networking work before implementing this service. Select
released dependency floors only after its required response receipt, pagination, content, and
portable transport contracts are available. Add HTTPPortable forwarding and the trait-on resolved
superset with the first real SDK targets; do not fabricate pins or placeholder targets.

## Planned service boundary

`SwiftGovInfoDocumentsModels` describes collection discovery, packages, granules, related records,
representations, and required bulk formats without dependencies. `SwiftGovInfoDocuments` executes
those descriptions. These names are planned, not implemented products.

Before API work, reverify [GovInfo's official contract](https://github.com/usgpo/api). Required facts
include explicit API.data.gov credentials, quota headers, `nextPage`/`offsetMark`, collection page
bounds, and generated assets returning 503 with Retry-After. Modification timestamps and publication
dates describe different facts. MODS metadata is not full document text. Book-only publications can
have zero granules; preserve volume/page access. Collection identifiers remain open. API coverage
must not be presented as a complete census of historical documents or authoritative legal status.

## Gates before source CI is enabled

- Implement real models, SDK, and recorded-fixture Swift Testing targets with shared strict settings.
- Verify origin and credential handling, lazy pagination, cancellation, invalid continuation, source
  receipts, historical/current records, XML portability, unknown values, and null preservation.
- Add both DocC catalogs and real Swift Package Index documentation targets, models first.
- Add a working demo; preserve Xcode 26 compatible project format 77 and generated package schemes.
- Run the complete repository gate and planted-violation checks, Apple MCP builds/tests, Linux default
  and HTTPPortable suites, Android, zero-warning DocC, and demo build/run.
- Review and enable CI with the retained two-entry Apple matrix and pinned Android cold boot options.
  Measure hosted timings before replacing provisional timeout ceilings. Configure documentation
  publication only after real products pass validation.

`bash Scripts/verify.sh --scaffold` cannot satisfy any source, transport, runtime, or publication gate.
