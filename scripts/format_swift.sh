#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Usage: format_swift.sh [TARGET]

Format all Swift source files in TARGET directory using swift-format.
Runs in-place recursively.

Arguments:
  TARGET    Directory to format (default: current directory)

Prerequisites:
  swift-format must be available. Run check_prereqs.sh to verify.

Examples:
  ./scripts/format_swift.sh
  ./scripts/format_swift.sh Sources/
HELP
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

"$SCRIPT_DIR/check_prereqs.sh" >/dev/null

if ! command -v swift >/dev/null 2>&1; then
  printf 'error: swift is not available on PATH.\n' >&2
  exit 1
fi

printf 'Formatting Swift sources in %s\n' "$TARGET"
swift format format --in-place --recursive "$TARGET"
printf 'Formatting complete.\n'
