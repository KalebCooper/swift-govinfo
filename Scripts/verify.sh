#!/usr/bin/env bash
# Run the source gate and its planted-violation checks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --self-test) bash "$ROOT/Scripts/verify-source.sh" --self-test; python3 "$ROOT/Scripts/verify-fixtures.py" --self-test ;;
  "") bash "$ROOT/Scripts/verify-source.sh"; python3 "$ROOT/Scripts/verify-fixtures.py" ;;
  *) echo "Usage: $0 [--self-test]" >&2; exit 2 ;;
esac
