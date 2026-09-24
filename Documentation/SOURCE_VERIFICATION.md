# GovInfo source verification

Verified September 23, 2026 (America/Chicago), with receipts in UTC on September 24. This is a sampled
source contract review, not a complete collection inventory. The SDK retains source meaning and leaves
cross-provider identity resolution, coverage accounting, retrieval timestamps, and archival policy to
consumers.

## Official contract and dependency

The [GPO API contract](https://github.com/usgpo/api) documents API.data.gov credentials, the collections,
published, packages/granules, and related services. Requests authenticate through `X-Api-Key` on
`api.govinfo.gov`. The key is never part of a recorded URL. Public `www.govinfo.gov` content is fetched
without the API key. The SDK refuses redirects rather than forwarding credentials to another origin.

The documented production ceilings are 36,000 requests/hour, 1,200/minute, and 40/second. A
`DEMO_KEY` response on this host instead reported limit 10 and remaining 0. The saved HTTP 429 receipt
at `2026-09-24T01:47:12.317307+00:00` includes `Retry-After: 79968`. Recording stopped at that response.
The SDK does not impose a guessed global rate limit. Consumers inspect response/error headers and can
inject one bounded networking-layer retry policy and clock. Generated ZIP and MODS can return 503 with
`Retry-After`; the tests verify retained headers and opted-in retry delay. Streaming requests send once.

Listings start with `offsetMark=*`, permit page sizes 1 through 1,000, and continue through the
provider's `nextPage`. The SDK preserves the opaque mark, same origin/path/filters/page size, and query
encoding. A null next link ends a traversal; a missing key, invalid URL, or repeated mark fails.
Publication date and repository modification time are separate query choices. A bounded date window
is useful for checkpoints, but does not promise a stable snapshot.

The public swifty-networking `1.3.1` tag was verified with `git ls-remote` before selecting the floor;
its peeled revision is `04bbf231eabb95b90a5be786034e07cf351ee1d5`. It provides response capture,
caller-decoded pages, and `streamResponse`. The SDK directly depends on Swift Crypto from 4.0.0 for
portable incremental SHA-256; its public tag was also verified. The models product has no third-party
or networking dependencies. FoundationXML is a conditional system import, with Apple's parser supplied
by Foundation. Both platforms decode from bounded bytes, never a URL.

## Attributed sample inventory

Each body has a neighboring `.receipt.json` containing the credential-free source URL, retrieval time,
status, headers, byte count, and SHA-256. `Scripts/verify-fixtures.py` verifies every pair.

| Body | Source evidence | Meaning retained |
| --- | --- | --- |
| collections.json | Live API 200 | Open collection codes, counts, null granule counts |
| dcpd-current.json, dcpd.html | DCPD-202600542, API/public content 200 | Issued August 14, modified September 22, 2026; HTML fetched independently |
| dcpd-historical.json, dcpd-mods.xml | DCPD-200900009, API/public metadata 200 | Historical metadata; MODS is not full text |
| wcpd.json, wcpd-granules.json, wcpd-granule.json | WCPD-1993-01-11, live API 200 | 23 granules, opaque continuation; listing and detail date strings retained separately |
| wcpd-granules-next.json | Next-link request, live API 429 | Incomplete traversal and quota evidence, not a second successful page |
| ppp-book.json, ppp-granules.json | PPP-1929-book1, live API 200 | 870 pages, zero granules, no HTML link; null terminal link |
| ppp.xml | PPP-2009-book1, public content 200 | Full document XML, including deep nesting preserved by the bounded parser |
| fr-historical.json, fr.pdf | FR-1936-03-14, API/public content 200 | Historical Federal Register document bytes, not structured action coverage |
| statute.json | STATUTE-1, live API 200 | Volume 1, source date and Congress metadata without inferred legal status |
| billstatus.xml | BILLSTATUS-119hr1, public bulk XML 200 | Bill identity, version, actions, relationships, unknown elements, and source ordering |
| official-packages.json | Official usgpo/api published example | Historical package envelope with numeric offset; never treated as a current cursor |
| related-document-service.html | [GPO related-service explanation](https://www.govinfo.gov/features/api-related-document-service) | Original documentation used for relationship examples |
| relationships-published.json, related-cpd-published.json | Complete JSON blocks extracted from the preceding official HTML | BILLS-114hr34enr relationships and DCPD-201600845; labeled documentation examples, not live API responses |

The source's historical series boundaries are documented by [CPD help](https://www.govinfo.gov/help/cpd),
[PPP help](https://www.govinfo.gov/help/ppp), and [FR help](https://www.govinfo.gov/help/fr). CPD electronic
holdings begin in 1993 and contain WCPD/DCPD identifiers. PPP covers 1929–1932 and 1945–2016, excludes
FDR, and does not continue after Obama; older holdings are commonly book-only. FR reaches its first
1936 issue. These boundaries are source availability statements, not a product date cutoff.

## Verification boundaries

Tests preserve complete recorded JSON fields, including unknown values and explicit nulls. They also
make clearly identified in-memory envelope mutations to exercise successful continuation, duplicate
items, null termination, missing links, filter changes, cursor cycles, and failures. Those mutations
are test inputs, not fabricated official recordings.

Live two-page and terminal package discovery, a successful second granule page, and modern live
relationship responses remain unrecorded because of the quota response. Finish those probes with an
authorized key or after the permitted reset before claiming complete live pagination qualification.
The pure codec rejects malformed input, DTD/entity declarations, unsupported encodings, excessive depth,
node count, and byte count. BILLSTATUS input is UTF-8; unknown elements and mixed text remain in order.
Original XML comments, lexical spelling, and processing instructions require opt-in body capture.

Bulk directory enumeration, every administration's inventory, and extraction of pre-XML vote tables
are not implemented here. The civic plan's previously identified 1964 Congressional Record page links
remain documentary references pending their own recordings and extraction work. NARA's independent
manifest/JSONL implementation has no dependency on this package. The combined early-Congress and
all-administration inventory remains a later coordinated source-coverage task.
