#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Usage: fix_and_lint.sh [TARGET]

Three-step cleanup: format with swift-format, auto-fix with SwiftLint, then
validate with SwiftLint in strict mode.

Arguments:
  TARGET    Directory to process (default: current directory)

Steps:
  1. Format all Swift sources (swift-format --in-place)
  2. Apply SwiftLint auto-fixes (swiftlint --fix)
  3. Validate with SwiftLint strict mode (swiftlint --strict)

Prerequisites:
  swift-format and SwiftLint must be installed. Run check_prereqs.sh to verify.

Examples:
  ./scripts/fix_and_lint.sh
  ./scripts/fix_and_lint.sh Sources/
HELP
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

"$SCRIPT_DIR/check_prereqs.sh" >/dev/null

printf 'Step 1/3: formatting %s\n' "$TARGET"
"$SCRIPT_DIR/format_swift.sh" "$TARGET"

printf 'Step 2/3: applying SwiftLint fixes\n'
if [ -f "$TARGET/.swiftlint.yml" ]; then
  swiftlint --fix --config "$TARGET/.swiftlint.yml"
else
  (
    cd "$TARGET"
    swiftlint --fix
  )
fi

printf 'Step 3/3: validating with SwiftLint strict mode\n'
"$SCRIPT_DIR/lint_swift.sh" "$TARGET"

printf 'Fix-and-lint workflow complete.\n'
