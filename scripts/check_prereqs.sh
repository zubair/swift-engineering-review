#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Usage: check_prereqs.sh

Verify that swift-format and SwiftLint are installed and available on PATH.
Prints tool paths and versions on success. Exits with code 1 if any tool is missing.

Prerequisites:
  - Swift 6+ toolchain (Xcode 16+) or swift-format via Homebrew
  - SwiftLint via Homebrew

Examples:
  ./scripts/check_prereqs.sh
  bash scripts/check_prereqs.sh
HELP
  exit 0
fi

say() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

have_swift_format() {
  if command -v swift >/dev/null 2>&1 && swift format --help >/dev/null 2>&1; then
    return 0
  fi

  if command -v xcrun >/dev/null 2>&1 && xcrun --find swift-format >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

if ! command -v swift >/dev/null 2>&1; then
  err "Swift is not installed or not on PATH."
  say "Install Xcode 16+ or a Swift 6 toolchain."
  exit 1
fi

if ! have_swift_format; then
  err "swift-format is not available."
  say "Preferred options:"
  say "  1) Use the Swift 6 toolchain/Xcode 16+ and run: swift format"
  say "  2) Install via Homebrew: brew install swift-format"
  exit 1
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  err "SwiftLint is not installed."
  say "Install via Homebrew: brew install swiftlint"
  exit 1
fi

say "All required tooling is available."
say "swift: $(swift --version 2>&1 | head -n 1)"
if command -v xcrun >/dev/null 2>&1; then
  if xcrun --find swift-format >/dev/null 2>&1; then
    say "swift-format: $(xcrun --find swift-format)"
  fi
fi
say "swiftlint: $(command -v swiftlint)"
