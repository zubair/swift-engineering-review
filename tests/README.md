# Review Output Stability Tests

Golden test fixtures for the `swift-engineering-review` skill. Each fixture is a Swift
file with known issues. The expected output files define structural assertions — which
playbooks should fire, at what severity, and what must not happen.

## Structure

```
tests/
├── fixtures/          # Swift files with known issues
│   ├── concurrency_data_race.swift
│   ├── mixed_observation.swift
│   ├── nonisolated_unsafe_globals.swift
│   ├── retain_cycle_delegate.swift
│   └── swiftui_observable_migration.swift
├── expected/          # Structural assertions for each fixture
│   ├── concurrency_data_race.md
│   ├── mixed_observation.md
│   ├── nonisolated_unsafe_globals.md
│   ├── retain_cycle_delegate.md
│   └── swiftui_observable_migration.md
└── run_golden_tests.sh
```

## How to Use

### Manual Review

Run the skill on a fixture and compare against the expected output:

```bash
# Review a fixture with the skill
claude "Review this file for Swift engineering issues: tests/fixtures/concurrency_data_race.swift"

# Then compare the output against tests/expected/concurrency_data_race.md
```

### Automated (CI)

```bash
./tests/run_golden_tests.sh
```

The script runs the skill on each fixture and checks structural assertions (scorecard
entries, playbook labels, severity levels). It does **not** compare exact prose — only
structure and routing correctness.

## Adding a New Fixture

1. Create a Swift file in `tests/fixtures/` with a descriptive name.
2. Add a comment header documenting the expected findings.
3. Create a matching file in `tests/expected/` with:
   - Required scorecard entries
   - Required findings (severity, playbook, must-mention, must-suggest)
   - Must-NOT assertions (prevents over-triggering)
4. Run the tests to verify.

## What These Tests Catch

- Playbook label renames or removals (backward compatibility)
- Severity drift (e.g. blocker downgraded to minor across model updates)
- Missing findings (signal not routed to correct playbook)
- Over-triggering (findings generated for issues not in the code)
- Routing regression (wrong track activated)
