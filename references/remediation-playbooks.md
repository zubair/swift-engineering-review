# Swift Remediation Playbooks

Use this file when a finding needs a concrete fix path. Reference the playbook label in
the review output so the fix recommendation is reusable and easy to scan.

## actor isolation

Use when shared mutable state is accessed from multiple tasks or threads.

- Prefer converting the owner to an `actor` when the state and behavior belong together.
- Otherwise protect the narrow mutation surface with `Mutex` or another explicit lock.
- Remove `@unchecked Sendable` unless the synchronization story is provably correct.
- After the change, verify all callers cross the isolation boundary intentionally.

## task lifetime

Use when work is launched with `Task {}` or `Task.detached {}` without a clear owner.

- Prefer structured concurrency, `.task(id:)`, or model-owned async methods.
- Propagate cancellation and handle it explicitly.
- Prevent stale writes by checking task identity or current input before mutating state.

## state ownership

Use when SwiftUI state lives in the wrong layer or too many layers own the same truth.

- Keep view-local toggles and ephemeral UI state in `@State`.
- Use `@Binding` for parent-owned mutation.
- Move shared mutable state into a long-lived observable model.
- Keep side effects out of `body`.

## identity stability

Use when `ForEach`, `List`, or selection state depends on unstable identity.

- Use stable domain IDs instead of `UUID()` generated during rendering.
- Avoid index-based identity for mutable collections.
- Make equality and hashing match the true identity contract.

## retain-cycle removal

Use when closures, delegates, or tasks capture owners too strongly.

- Capture `[weak self]` when the closure outlives the owner.
- Use `unowned` only when the lifetime relationship is guaranteed by construction.
- Make delegates weak unless ownership is intentionally strong.

## typed errors

Use when failures are swallowed, stringly typed, or lose context.

- Prefer domain-specific `Error` enums or well-defined error wrappers.
- Preserve the underlying error when it helps debugging or retry logic.
- Replace bare `catch {}` and casual `try?` with explicit handling.
- Keep retry and fallback behavior bounded and observable.

## dependency injection

Use when singletons or global state make testing and evolution difficult.

- Inject dependencies from the composition root.
- Start concrete; extract a protocol when multiple implementations or testing pressure
  justify it.
- Keep module and access-control boundaries narrow.

## test hardening

Use when risky behavior lacks regression coverage.

- Add tests for the failure mode, not just the happy path.
- Add cancellation and concurrency tests for async code where feasible.
- Isolate time, randomness, storage, and network boundaries.
- Prefer small deterministic tests over broad flaky integration tests.
