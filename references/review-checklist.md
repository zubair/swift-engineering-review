# Swift Engineering Review Checklist

## Correctness

- [ ] Code compiles without warnings
- [ ] Code passes all relevant tests
- [ ] Swift 6 concurrency checks are satisfied
- [ ] No force-unwraps (`!`) unless the invariant is provably guaranteed and documented — crashes in production with no recovery path
- [ ] No force-try (`try!`) in production paths — same crash risk as force-unwraps
- [ ] Guard/precondition assumptions are validated at the call site
- [ ] Optional chaining is preferred over force-unwrapping
- [ ] Switch statements are exhaustive or have a justified `default` — exhaustive switches let the compiler catch newly added cases
- [ ] Numeric conversions handle overflow (use `exactly:` initializers where needed)
- [ ] Collection index access is bounds-checked or uses safe patterns
- [ ] `Equatable`/`Hashable` conformances are consistent and correct
- [ ] `let` is used unless mutation is required

## Concurrency

- [ ] No data races: mutable shared state is protected by an actor or `Mutex`
- [ ] `@MainActor` is applied to UI-touching code and not over-applied elsewhere — over-applying serializes work unnecessarily and hides the real isolation boundary
- [ ] `Sendable` conformance is correct — no false `@unchecked Sendable` which hides real data races that surface in production
- [ ] Structured concurrency (`async let`, `TaskGroup`) preferred over unstructured `Task {}` — provides automatic cancellation propagation and structured error handling
- [ ] `Task {}` and `Task.detached {}` have explicit cancellation handling
- [ ] `Task.detached` is only used when its semantics are explicitly required
- [ ] `nonisolated` is used intentionally, not to silence compiler warnings — reflexive use removes safety guarantees the compiler is trying to provide
- [ ] Continuation-based bridging (`withCheckedContinuation`) is resumed exactly once — resuming zero times leaks; resuming twice crashes
- [ ] `AsyncSequence` usage handles cancellation and termination
- [ ] Global actors are not used as a lazy synchronization mechanism — serializes unrelated work and masks missing isolation design
- [ ] Isolation boundaries are narrow and well-documented
- [ ] `async`/`await` preferred over callback-based APIs
- [ ] `Mutex` is used only for small synchronous critical sections — do not hold across `await`; prefer `actor` for complex state
- [ ] `sending` parameters are used when values cross isolation boundaries — prevents accidental shared-mutable-state transfer
- [ ] `@isolated(any)` is used for closure parameters that should inherit caller isolation — avoids forcing unnecessary actor hops
- [ ] `nonisolated(unsafe)` has an inline comment documenting the safety invariant — escape hatch that silently reintroduces data races if the invariant changes

## Architecture

- [ ] Value types (`struct`, `enum`) preferred unless reference semantics are required
- [ ] `class` usage is justified (identity, inheritance, reference-counting interop)
- [ ] Classes are marked `final` unless inheritance is a deliberate API decision — enables compiler devirtualization and makes the API contract explicit
- [ ] `actor` usage is justified (shared mutable state that needs isolation)
- [ ] Protocol design follows "start with concrete, extract when needed" — premature protocol extraction adds abstraction without proven need
- [ ] Dependencies are injected, not hard-coded singletons — singletons make unit testing impossible and hide coupling
- [ ] Module/target boundaries are clean — no circular dependencies
- [ ] Access control is as restrictive as possible (`private` > `internal` > `public`)
- [ ] SwiftUI views are small, focused, and compose well
- [ ] View models (if used) do not leak UIKit/SwiftUI types across layers
- [ ] Protocol conformances are in separate extensions where practical

## Code Organization

- [ ] Extensions use `Type+Feature.swift` naming for separate files
- [ ] Sections separated with `// MARK: -` within files
- [ ] One type per file (small private helpers allowed in same file)
- [ ] No unused code (commented-out code, empty delegate methods, dead properties)
- [ ] No methods that only forward to superclass without adding value

## Naming & Style

- [ ] Types use UpperCamelCase, properties/methods use lowerCamelCase
- [ ] Boolean properties read as assertions (`isEmpty`, `canExecute`)
- [ ] Argument labels form grammatical phrases at the call site
- [ ] Generic type parameters are descriptive when role matters
- [ ] Constants are type-scoped, not global
- [ ] Optionality is not encoded in variable names
- [ ] `self` is avoided unless required for disambiguation or capture semantics

## Spacing & Formatting

- [ ] Braces open on the same line, close on a new line
- [ ] Exactly one blank line between methods
- [ ] Colons: no space left, one space right
- [ ] Lines wrap around 120 characters
- [ ] No trailing whitespace
- [ ] Shorthand type syntax used (`[String]` not `Array<String>`)
- [ ] Compiler-inferred context used (`.red` not `UIColor.red`)
- [ ] Parentheses omitted around conditionals

## Comments & Documentation

- [ ] Comments explain **why**, not **what**
- [ ] Comments are up to date or deleted
- [ ] Public APIs have `///` documentation comments
- [ ] Documentation includes parameters, returns, and throws where applicable

## Ownership & Memory

- [ ] Closures capture `[weak self]` when the closure outlives the owner
- [ ] `unowned` is only used when the lifetime relationship is guaranteed — use `weak` when in doubt; `unowned` crashes on access after deallocation
- [ ] No retain cycles between delegates, closures, and parent objects
- [ ] Value semantics are used to avoid unintended shared mutation
- [ ] Copy-on-write types (`Array`, `Dictionary`) are not mutated through shared references
- [ ] `withExtendedLifetime` or `defer` used where premature deallocation is possible
- [ ] IBOutlets are `private`

## Error Handling

- [ ] Errors are typed and meaningful — not stringly-typed
- [ ] Errors use domain-specific `Error` types (enum-based where practical)
- [ ] `throws` functions document what errors they can throw
- [ ] Errors are handled at the appropriate level — not swallowed silently
- [ ] `catch` blocks are specific, not bare `catch {}` — bare catch blocks make production failures invisible
- [ ] `try?` is only used when loss of error detail is intentional — silently discards diagnostic information needed for debugging
- [ ] `Result` is used at API boundaries, `throws` internally
- [ ] Retry and fallback logic is explicit and bounded
- [ ] User-facing errors are localized and actionable
- [ ] `preconditionFailure`/`fatalError` used sparingly, only for impossible states — kills the process; recoverable failures should use throws
- [ ] Underlying errors are preserved when they carry diagnostic value

## Tests

- [ ] Public API has test coverage for happy path and key edge cases
- [ ] Concurrency code has tests that exercise race conditions (where feasible)
- [ ] Tests use Swift Testing (`@Test`, `#expect`, `#require`) for new code
- [ ] XCTest/XCUITest used where platform tooling requires it
- [ ] Tests are deterministic — no flaky timing dependencies; flaky tests erode trust in the suite and slow CI
- [ ] Test names describe the scenario and expected outcome
- [ ] Tests test behavior, not implementation details — implementation-coupled tests break on every refactor without catching real bugs
- [ ] Dependencies are injected explicitly (no network in unit tests)
- [ ] Mocks/stubs are protocol-based and minimal
- [ ] Factories and fixtures used for complex test data
- [ ] Time, randomness, storage, and network boundaries are isolated
- [ ] Test pyramid honored: many unit, fewer integration, fewer E2E
- [ ] Snapshot/UI tests exist for critical UI flows (when applicable)

## Imports

- [ ] Import statements are sorted and minimal
- [ ] System frameworks listed first
- [ ] No `UIKit` when `Foundation` suffices
- [ ] No unused framework imports

## Formatting & Linting

- [ ] Code passes `swift format` without changes
- [ ] Code passes `swiftlint --strict` without warnings
- [ ] `.swiftlint.yml` is present and configured for the project
- [ ] No disabled linter rules without a documented reason

## CI Hygiene

- [ ] CI runs formatter and linter checks
- [ ] CI runs tests on all supported platforms
- [ ] Warnings are treated as errors in release builds (`-warnings-as-errors`)
- [ ] Build settings do not disable safety checks (`-Ounchecked`, etc.)

## Git Commit Standards

- [ ] Commits follow `<type>(<scope>): <summary>` format
- [ ] Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`, `ci`
- [ ] Commits are small enough to review, large enough to preserve intent
- [ ] No force-pushes to shared branches without team agreement
