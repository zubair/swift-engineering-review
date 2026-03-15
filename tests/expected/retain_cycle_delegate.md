# Expected Output: retain_cycle_delegate.swift

## Required Scorecard Entries

- Ownership & Memory: FAIL
- Error Handling & Observability: WARN

## Required Findings

### Finding 1: Retain cycle — strong delegate

- **Severity:** major
- **Playbook:** `retain-cycle removal`
- **Must mention:** `var delegate: DataManagerDelegate?` is strong, should be `weak`
- **Must suggest:** `weak var delegate` and making the protocol `: AnyObject`

### Finding 2: Retain cycle — closure capture

- **Severity:** major or minor
- **Playbook:** `retain-cycle removal`
- **Must mention:** closure captures `self` without `[weak self]`
- **Must suggest:** `[weak self]` capture

### Finding 3: Error swallowing

- **Severity:** minor
- **Playbook:** `typed errors`
- **Must mention:** `try?` discarding decode error, nil error branch doing nothing
- **Must suggest:** typed error handling or at minimum logging

## Must NOT

- Miss the strong delegate pattern
- Rate the closure capture as `nit` (it outlives the owner via `asyncAfter`)
- Ignore the swallowed error in the nil data branch
