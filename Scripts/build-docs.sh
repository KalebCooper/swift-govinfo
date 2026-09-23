#!/usr/bin/env bash
# Convert only this package's two products from already-built iOS simulator modules.
# Dependencies must compile, but their documentation is not part of this site.
set -euo pipefail

# Infrastructure is present; source validation requires an implemented service.
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/require-source.sh" || exit 1

modules="${1:?Usage: bash Scripts/build-docs.sh MODULES_DIRECTORY OUTPUT_DIRECTORY [TARGET]}"
output="${2:?Supply a new output directory}"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
target="${3:-$(uname -m)-apple-ios26.0-simulator}"

if [[ -e "$output" ]]; then
  echo "Output already exists: $output. Supply a new directory." >&2
  exit 1
fi
mkdir -p "$output/models-symbols" "$output/sdk-symbols" "$output/module-cache"

xcrun swift-symbolgraph-extract -module-name SwiftGovInfoDocumentsModels \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/models-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftGovInfoDocumentsModels/SwiftGovInfoDocumentsModels.docc \
  --additional-symbol-graph-dir "$output/models-symbols" \
  --output-dir "$output/SwiftGovInfoDocumentsModels.doccarchive" \
  --enable-experimental-external-link-support --warnings-as-errors

xcrun swift-symbolgraph-extract -module-name SwiftGovInfoDocuments \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/sdk-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftGovInfoDocuments/SwiftGovInfoDocuments.docc \
  --additional-symbol-graph-dir "$output/sdk-symbols" \
  --output-dir "$output/SwiftGovInfoDocuments.doccarchive" \
  --enable-experimental-external-link-support \
  --dependency "$output/SwiftGovInfoDocumentsModels.doccarchive" --warnings-as-errors

xcrun docc merge "$output/SwiftGovInfoDocumentsModels.doccarchive" "$output/SwiftGovInfoDocuments.doccarchive" \
  --synthesized-landing-page-name swift-govinfo --synthesized-landing-page-kind Package \
  --output-path "$output/merged.doccarchive"
xcrun docc process-archive transform-for-static-hosting "$output/merged.doccarchive" \
  --output-path "$output/site" --hosting-base-path swift-govinfo

# The archive's app shell has no root route under the Pages subpath.
cat > "$output/site/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=documentation/">
    <link rel="canonical" href="https://kalebcooper.github.io/swift-govinfo/documentation/">
    <title>swift-govinfo</title>
  </head>
  <body>
    <p>Redirecting to the <a href="documentation/">swift-govinfo documentation</a>.</p>
  </body>
</html>
HTML
