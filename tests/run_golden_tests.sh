#!/usr/bin/env bash
# Golden test runner for swift-engineering-review skill.
# Runs the skill on each fixture and checks structural assertions from expected/ files.
#
# Usage: ./tests/run_golden_tests.sh [fixture_name]
#   fixture_name: optional — run only this fixture (without extension)
#
# Exit codes:
#   0 — all assertions passed
#   1 — one or more assertions failed
#
# Prerequisites:
#   - claude CLI available on PATH
#   - jq available on PATH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
EXPECTED_DIR="$SCRIPT_DIR/expected"
OUTPUT_DIR="$SCRIPT_DIR/output"

mkdir -p "$OUTPUT_DIR"

PASS=0
FAIL=0
SKIP=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_assertion() {
    local output_file="$1"
    local pattern="$2"
    local description="$3"

    if grep -qi "$pattern" "$output_file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $description (pattern: $pattern)"
        ((FAIL++))
    fi
}

check_negative_assertion() {
    local output_file="$1"
    local pattern="$2"
    local description="$3"

    if grep -qi "$pattern" "$output_file" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} MUST NOT: $description (pattern found: $pattern)"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} MUST NOT: $description"
        ((PASS++))
    fi
}

run_fixture() {
    local fixture="$1"
    local name
    name="$(basename "$fixture" .swift)"
    local expected="$EXPECTED_DIR/$name.md"
    local output="$OUTPUT_DIR/$name.md"

    if [[ ! -f "$expected" ]]; then
        echo -e "${YELLOW}SKIP${NC} $name — no expected output file"
        ((SKIP++))
        return
    fi

    echo ""
    echo "━━━ $name ━━━"

    # Run the skill if output doesn't exist or --rerun flag
    if [[ ! -f "$output" || "${RERUN:-}" == "1" ]]; then
        echo "  Running skill on $name..."
        if command -v claude &>/dev/null; then
            claude --print "Review this Swift file for engineering issues using the swift-engineering-review skill: $(cat "$fixture")" > "$output" 2>/dev/null || true
        else
            echo -e "  ${YELLOW}⚠${NC} claude CLI not found — skipping generation, checking existing output"
            if [[ ! -f "$output" ]]; then
                echo -e "  ${YELLOW}SKIP${NC} no output to check"
                ((SKIP++))
                return
            fi
        fi
    else
        echo "  Using cached output (set RERUN=1 to regenerate)"
    fi

    # Structural assertions — scorecard
    check_assertion "$output" "Review Scorecard" "Contains Review Scorecard"

    # Check required playbook labels from expected file
    while IFS= read -r line; do
        local playbook
        playbook="$(echo "$line" | sed 's/.*`\(.*\)`.*/\1/')"
        check_assertion "$output" "$playbook" "References playbook: $playbook"
    done < <(grep -i '^\- \*\*Playbook:\*\*' "$expected" 2>/dev/null || true)

    # Check required severity levels
    while IFS= read -r line; do
        local severity
        severity="$(echo "$line" | sed 's/.*\*\*Severity:\*\* \(.*\)/\1/' | tr -d '*' | awk '{print $1}')"
        check_assertion "$output" "$severity" "Contains severity: $severity"
    done < <(grep -i '^\- \*\*Severity:\*\*' "$expected" 2>/dev/null || true)

    # Check scorecard entries from expected file
    while IFS= read -r line; do
        local track
        track="$(echo "$line" | sed 's/^- //')"
        # Extract track name (before the colon)
        local track_name
        track_name="$(echo "$track" | cut -d: -f1)"
        check_assertion "$output" "$track_name" "Scorecard includes: $track_name"
    done < <(grep -i '^- .*: .*\(WARN\|FAIL\|PASS\|N/A\)' "$expected" 2>/dev/null || true)

    echo ""
}

# Main
echo "Swift Engineering Review — Golden Tests"
echo "========================================"

FILTER="${1:-}"

for fixture in "$FIXTURES_DIR"/*.swift; do
    [[ -f "$fixture" ]] || continue
    name="$(basename "$fixture" .swift)"
    if [[ -n "$FILTER" && "$name" != "$FILTER" ]]; then
        continue
    fi
    run_fixture "$fixture"
done

echo ""
echo "━━━ Results ━━━"
echo -e "  ${GREEN}Passed:${NC} $PASS"
echo -e "  ${RED}Failed:${NC} $FAIL"
echo -e "  ${YELLOW}Skipped:${NC} $SKIP"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo -e "${RED}FAIL${NC} — $FAIL assertion(s) failed"
    exit 1
else
    echo -e "${GREEN}PASS${NC} — all assertions passed"
    exit 0
fi
