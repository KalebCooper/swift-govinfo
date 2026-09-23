#!/usr/bin/env bash
set -euo pipefail
root="${VERIFY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
for module in SwiftGovInfoDocuments SwiftGovInfoDocumentsModels; do
  if [[ ! -d "$root/Sources/$module" ]] || ! find "$root/Sources/$module" -name '*.swift' -type f | grep -q .; then
    echo "Not ready: $module source is not implemented. See IMPLEMENTATION_READINESS.md." >&2
    exit 1
  fi
done
if [[ ! -d "$root/Tests" ]] || ! find "$root/Tests" -name '*.swift' -type f | grep -q .; then
  echo 'Not ready: recorded-fixture tests are not implemented.' >&2
  exit 1
fi
