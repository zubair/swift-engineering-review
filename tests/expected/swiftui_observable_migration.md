# Expected Output: swiftui_observable_migration.swift

## Required Scorecard Entries

- SwiftUI & Performance: WARN or FAIL
- Concurrency: WARN (task lifetime issue)

## Required Findings

### Finding 1: Observable migration

- **Severity:** nit (unless mixed with @Observable — then major)
- **Playbook:** `observable migration`
- **Must mention:** `ObservableObject`, `@Published`, `@StateObject`
- **Must suggest:** migration to `@Observable` macro

### Finding 2: Task lifetime

- **Severity:** major
- **Playbook:** `task lifetime`
- **Must mention:** `Task {}` in `onAppear`, fire-and-forget
- **Must suggest:** `.task` modifier or model-owned async method

## Must NOT

- Rate observable migration as `blocker` or `major` (no mixed observation in this file)
- Miss the task lifetime issue in `onAppear`
- Fabricate findings not present in the code
