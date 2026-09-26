# Contributing to swift-govinfo

Keep changes focused on the GovInfo source contract. The independent models product has no
third-party dependencies. The SDK executes typed descriptions through swifty-networking. Every public
operation should have an everyday method, reusable request, and single-operation endpoint with shared
execution. Required API credentials have no defaults.

Preserve unknown values, nulls, source identifiers, publication versus modification dates, and the
provider's continuation links. MODS/PREMIS are metadata. Historical book-only content may have no
granules. Do not derive legal status, fabricate source coverage, or perform app-specific joins here.
FoundationXML is a system XML parsing dependency, conditionally imported by the pure models decoder;
Apple uses Foundation's parser. Disable entities, validate byte/depth/node limits, and retain raw bytes.

Order declarations alphabetically within logical groupings and document public symbols with DocC.
Use Swift Testing with the shared time limit and attributed official recordings, never a live API in
unit tests. All targets carry the shared strict Swift settings. The test-support target is not a
library product. Use Conventional Commits and update the changelog for public behavior.

## Local gates

Run `bash Scripts/verify.sh` before every commit and `bash Scripts/verify.sh --self-test` after changes
to verification. The gate checks source conventions, strict formatting, and fixture receipts. Raw
recordings alone are exempt from prose vocabulary rules; authored Swift and documentation remain
checked even beside fixtures. Receipt self-tests prove byte/hash, origin, credentials, and attribution
checks detect planted errors.

Run Apple builds and tests through Xcode MCP using the generated `swift-govinfo-Package` scheme.
Run `bash Scripts/linux-test.sh` for default and HTTPPortable traits with the pinned Swift 6.3 image.
Build both DocC catalogs with `Scripts/build-docs.sh`, models first, from built iOS simulator modules.
Android, iOS simulator tests, the Release demo build, demo runtime and hosted workflows are separate gates.
See [Implementation readiness](IMPLEMENTATION_READINESS.md) for current evidence and unavailable gates.

Repository checks, formatting, Linux tests with both trait configurations, Android emulator tests,
iOS simulator tests, the Release demo build and DocC builds run on pushes to main and pull requests.
Pages deployment remains disabled. Job timeout ceilings reflect measured hosted qualification runs.

## Recording sources

`Scripts/record-fixtures.py NAME...` is an opt-in network tool. Supply `GOVINFO_API_KEY` only to this
recorder, or it uses the documented demonstration key. It refuses to overwrite evidence and stops on
401, 403, or 429. Honor a recorded `Retry-After` before retrying. Do not check in credentials, cookies,
or URLs containing API keys. Tests read committed bytes without secrets or network access.
