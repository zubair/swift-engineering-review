# SwiftUI Review Heuristics

Use this file when code contains SwiftUI views, Observation, bindings, or view-driven
async work. This is a heuristic review for state ownership and invalidation risk, not an
Instruments profiling guide.

## State Ownership

- Use `@State` for view-local value state.
- Use `@Binding` for state owned by a parent and mutated by a child.
- Use `@Observable` or another long-lived model for shared mutable feature state.
- Do not create long-lived reference types inside `body`.
- UI-facing mutable models should usually be isolated to `@MainActor`; avoid
  `@MainActor` on unrelated background work just to quiet warnings.

## View Composition

- Flag views that mix layout, business logic, formatting, and side effects in one body.
- Treat very large `body` implementations as a design smell, not an automatic failure.
- Move derived collections, formatting, and branching logic into helpers or models when
  the body becomes hard to scan or repeats expensive work.
- Extract child views when identity or state boundaries become unclear.

## Invalidation and Performance Smells

- Avoid sorting, filtering, decoding, image processing, or formatter creation in `body`.
- Avoid `UUID()` or other transient identifiers in `body`.
- Prefer stable `Identifiable` values for `ForEach` and `List`.
- Avoid using collection indices as identity when the collection is mutable.
- Avoid side effects in computed view properties or modifiers that run on every render.

## Async Lifecycle

- Prefer `.task(id:)` when async work should follow view identity.
- Avoid fire-and-forget `Task {}` from views when the model should own the work.
- Guard against stale writes when user input changes while a task is in flight.
- Tie cancellation to lifecycle where possible.

## Severity Guidance

- `major`: unstable identity causing duplicate fetches or writes, heavy work inside hot
  rendering paths, or lifecycle bugs that write stale state back into the UI
- `minor`: oversized bodies, misplaced derived state, or moderate invalidation pressure
- `nit`: small composition or naming polish with no meaningful runtime impact

Escalate to `blocker` only when the SwiftUI issue also creates a crash, corruption, or
true concurrency bug.

## Common Fix Patterns

- Extract a child view to narrow state and identity boundaries.
- Precompute derived data before entering `body`.
- Move async orchestration into a `@MainActor` model.
- Replace index-based identity with stable model identity.
- Convert one giant screen model into smaller feature-scoped state holders.
