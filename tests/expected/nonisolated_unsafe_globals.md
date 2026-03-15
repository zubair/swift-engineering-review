# Expected Output: nonisolated_unsafe_globals.swift

## Required Scorecard Entries

- Concurrency: FAIL

## Required Findings

### Finding 1: Mutable global state — featureFlags

- **Severity:** blocker or major
- **Playbook:** `nonisolated(unsafe)` or `actor isolation`
- **Must mention:** `nonisolated(unsafe) var featureFlags` is mutable and written from multiple tasks
- **Must suggest:** protect with `actor`, `Mutex`, or make immutable

### Finding 2: Mutable static state — AppConfig.apiBaseURL

- **Severity:** major
- **Playbook:** `nonisolated(unsafe)` or `actor isolation`
- **Must mention:** `nonisolated(unsafe) static var apiBaseURL` writable from any isolation domain
- **Must suggest:** synchronization or immutable configuration

### Finding 3: Missing safety comment — logger

- **Severity:** nit or minor
- **Playbook:** `nonisolated(unsafe)`
- **Must mention:** `nonisolated(unsafe) let logger` lacks safety-invariant comment
- **Must suggest:** add inline comment documenting why this is safe

## Must NOT

- Rate the mutable `var featureFlags` below `major` — it's a real data race
- Conflate the safe immutable `let logger` with the unsafe mutable `var featureFlags`
- Miss the `TaskGroup` writing to `featureFlags` concurrently
