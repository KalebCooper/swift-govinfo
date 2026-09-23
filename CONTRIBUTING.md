# Contributing to swift-govinfo

This repository currently contains infrastructure only. Keep changes focused and preserve the
empty manifest until a working service can be delivered with recorded fixtures and documentation.

## Infrastructure checks

Run `bash Scripts/verify.sh --scaffold` before a scaffold commit and
`bash Scripts/verify.sh --self-test` after changes to checks. The scaffold gate validates only
infrastructure. The default `bash Scripts/verify.sh` fails until real source and tests exist.

## Implementation requirements

The planned independent product pair is `SwiftGovInfoDocuments` and
`SwiftGovInfoDocumentsModels`. The models product must have no transport dependencies. Deliver each
operation through a client convenience, typed request factory, and typed endpoint with shared
execution. Required credentials have no defaults. Preserve unknown values, nulls, source identifiers,
provider continuation semantics, and publication versus modification dates.

Use Swift Testing and recorded official fixtures; tests never use the live API. All targets use the
shared strict Swift settings. Order declarations alphabetically within logical groups. Each public
symbol needs DocC documentation. Use Conventional Commits and update the changelog with public changes.

## Source validation

See [implementation readiness](IMPLEMENTATION_READINESS.md) before enabling source jobs. Required
validation includes Apple builds/tests through Xcode's generated `swift-govinfo-Package` scheme,
Linux with default and portable traits, Android, strict source lint, zero-warning DocC, and a working
demo. Agent-driven Xcode operations use the Xcode MCP tools. Hosted workflow commands are templates,
not evidence of completed local or hosted checks.

The active CI job checks infrastructure only. Every source and documentation job is explicitly
disabled until its real inputs exist. Timeout ceilings are provisional pending measured hosted runs.
