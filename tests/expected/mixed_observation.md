# Expected Output: mixed_observation.swift

## Required Scorecard Entries

- SwiftUI & Performance: FAIL
- Concurrency: N/A or PASS

## Required Findings

### Finding 1: Mixed observation — double invalidation

- **Severity:** major
- **Playbook:** `observable migration`
- **Must mention:** `ObservableObject` (`UserSettings`) mixed with `@Observable` (`AppState`) in same view hierarchy
- **Must mention:** double-invalidation risk
- **Must suggest:** migrate `UserSettings` to `@Observable` to unify observation

### Finding 2: State ownership (optional)

- **Severity:** minor or nit
- **Playbook:** `state ownership`
- **May mention:** `@StateObject` used alongside `@State` for `@Observable`

## Must NOT

- Rate the mixed observation as `nit` — this is a real bug causing double-invalidation
- Miss that both observation systems are active in the same hierarchy
- Suggest the issue is cosmetic or toolchain-level
