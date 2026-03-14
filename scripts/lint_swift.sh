#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Usage: lint_swift.sh [TARGET]

Run SwiftLint in strict mode on TARGET directory.
Uses .swiftlint.yml from TARGET if present, otherwise uses SwiftLint defaults.

Arguments:
  TARGET    Directory to lint (default: current directory)

Exit codes:
  0    No warnings or errors
  1    Prerequisites missing or SwiftLint found violations

Prerequisites:
  SwiftLint must be installed. Run check_prereqs.sh to verify.

Examples:
  ./scripts/lint_swift.sh
  ./scripts/lint_swift.sh Sources/
HELP
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

"$SCRIPT_DIR/check_prereqs.sh" >/dev/null

printf 'Running SwiftLint in strict mode on %s\n' "$TARGET"

if [ -f "$TARGET/.swiftlint.yml" ]; then
  swiftlint --strict --config "$TARGET/.swiftlint.yml"
else
  (
    cd "$TARGET"
    swiftlint --strict
  )
fi

printf 'SwiftLint completed.\n'
