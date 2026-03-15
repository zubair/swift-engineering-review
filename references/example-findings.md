# Example Review Output

Use this file to mirror the expected structure and tone of the final review.

## Review Scorecard

- Correctness: FAIL
- Concurrency: FAIL
- SwiftUI & Performance: WARN
- Architecture & API Design: PASS
- Ownership & Memory: PASS
- Error Handling & Observability: WARN
- Testing & Tooling: WARN

## Findings

### [blocker] Shared cache is mutated from unstructured tasks

**File:** `Services/CacheManager.swift:47`
**Confidence:** high
**Evidence:** observed
**Why it matters:** `cache` is written from multiple `Task {}` blocks without a
synchronization boundary. Under Swift 6 strict concurrency this is a real data race and
can corrupt state or crash unpredictably.
**Fix:** Move the cache behind an `actor`, or guard the mutation surface with a `Mutex`
and a narrow API.
**Playbook:** `actor isolation`

### [major] Unstable list identity triggers duplicate fetches

**File:** `Features/Inbox/InboxView.swift:63`
**Confidence:** high
**Evidence:** observed
**Why it matters:** `ForEach(messages.indices, id: \.self)` couples row identity to list
position. Inserts or deletes will invalidate the wrong rows, which can re-run `.task`
work and write stale results into the UI.
**Fix:** Iterate over stable `Message.ID` values and move async row loading to a
view-model method keyed by that stable identity.
**Playbook:** `identity stability`

### [minor] Bare catch block hides backend failures

**File:** `Networking/APIClient.swift:95`
**Confidence:** high
**Evidence:** observed
**Why it matters:** `catch {}` discards the original failure, making retry behavior and
production debugging guesswork.
**Fix:** Throw a typed error or log the original error before mapping it to a user-facing
failure.
**Playbook:** `typed errors`

### [minor] ViewModel may retain network client beyond expected lifetime

**File:** `Features/Inbox/InboxViewModel.swift:22`
**Confidence:** medium
**Evidence:** inferred
**Why it matters:** The view model stores a strong reference to `NetworkClient`, which
holds an active `URLSession`. If the view model outlives its screen (e.g. held by a
navigation cache), the session remains open unnecessarily.
**Fix:** Verify the view model's lifecycle matches the screen. If it does, no change
needed. If not, inject the client as a protocol and scope the session to the request.
**Playbook:** `dependency injection`

### [nit] Message model may need Sendable conformance for future actor usage

**File:** `Models/Message.swift:8`
**Confidence:** low
**Evidence:** needs-confirmation
**Why it matters:** `Message` is a struct used in async contexts. If it is ever passed
across actor boundaries, the compiler will require `Sendable`. Currently all usage is
within a single isolation domain, so this is informational.
**Fix:** Confirm whether `Message` crosses isolation boundaries in other modules. If so,
add `Sendable` conformance.
**Playbook:** `sending parameters`

## Remediation Plan

- Quick wins: replace index-based identity, remove the bare catch, and add a concurrent
  write regression test.
- Structural fixes: isolate cache mutation behind an actor and move list-side async work
  into a model that owns cancellation.
- Tests to add: a concurrent store/read stress test and a list update test that inserts
  and deletes rows while async work is in flight.

## Overall Verdict

Not ready to merge as-is. The highest-risk issue is the shared mutable cache because it
can fail nondeterministically in production. Fix the isolation boundary first, then
stabilize list identity and add regression coverage around both behaviors.
