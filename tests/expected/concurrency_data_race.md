# Expected Output: concurrency_data_race.swift

## Required Scorecard Entries

- Concurrency: FAIL
- Ownership & Memory: WARN or N/A

## Required Findings

### Finding 1: Actor isolation

- **Severity:** blocker
- **Playbook:** `actor isolation`
- **Must mention:** `@unchecked Sendable`, shared mutable `store`, `DispatchQueue` synchronization
- **Must suggest:** convert `ImageCache` to an `actor` or use `Mutex`

### Finding 2: Task lifetime

- **Severity:** major
- **Playbook:** `task lifetime`
- **Must mention:** unstructured `Task {}` in loop, `Task.detached` with strong `self` capture
- **Must suggest:** structured concurrency or stored task handles with cancellation

## Must NOT

- Rate the `@unchecked Sendable` issue below `blocker`
- Miss the `Task.detached` capturing `self` strongly
- Suggest only adding `Sendable` without fixing the underlying synchronization
