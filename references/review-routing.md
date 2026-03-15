# Swift Review Routing

Use this file to decide which review tracks to run and how to score them. Start narrow,
then add tracks only when the code or the request clearly requires them.

## Track Selection

| Signal | Track | Load | Focus |
|---|---|---|---|
| `async`, `await`, `Task`, `actor`, `Sendable`, `@MainActor`, `AsyncSequence` | Concurrency | This file + `review-checklist.md` Concurrency | Isolation boundaries, task lifetime, cancellation, Sendable correctness |
| `View`, `body`, `@State`, `@Binding`, `@Observable`, `ForEach`, `.task` | SwiftUI & Performance | This file + `swiftui-review.md` | State ownership, identity stability, invalidation pressure, view lifecycle |
| Repositories, services, DI, protocols, modules, large PRs | Architecture & API Design | This file + `review-checklist.md` Architecture | Dependency direction, abstraction discipline, module boundaries, access control |
| `throws`, `Result`, `catch`, retry logic, logging | Error Handling & Observability | `review-checklist.md` Error Handling + `remediation-playbooks.md` | Error typing, propagation, retries, diagnostics |
| Closures, delegates, reference types | Ownership & Memory | `review-checklist.md` Ownership + `remediation-playbooks.md` | Retain cycles, weak/unowned safety, reference vs value semantics |
| Tests, CI, formatter, SwiftLint | Testing & Tooling | `review-checklist.md` Tests + `tooling.md` | Risk-driven coverage, determinism, CI enforcement |
| Naming, imports, organization, comments | Correctness or Architecture & API Design | `swift-style-guide.md` | Clarity, consistency, and code organization |

## Mandatory Escalation Rules

Always run the Architecture & API Design track when any of the following is true:

- the PR spans multiple layers or packages
- the diff is roughly larger than 500 changed lines
- the change introduces new protocols, services, repositories, or navigation roots
- the review contains repeated similar findings that indicate a systemic design issue

Always run the Concurrency track when shared mutable state or UI-bound async work is
present, even if the user only asked for a generic review.

## Scorecard Rules

- `PASS`: No meaningful issues in the track, or only one low-value nit.
- `WARN`: One or more minor issues, or a design smell that deserves follow-up.
- `FAIL`: Any blocker or major issue, or repeated minor issues that expose a broken
  pattern.
- `N/A`: The track is genuinely out of scope for the reviewed code.

The scorecard is not a summary of how much code was touched. It is a risk signal.

## Track Questions

### Correctness

- Can the code crash, corrupt state, or silently violate invariants?
- Are force unwraps, force tries, unchecked casts, or unsafe indexes justified?
- Do type conformances preserve semantics?

### Concurrency

- Where is mutable state owned, and who is allowed to mutate it?
- Is actor isolation explicit and narrow?
- Do tasks have a parent, cancellation story, and safe lifetime?
- Is `Sendable` true, or merely asserted?

### SwiftUI & Performance

- Is state owned by the correct layer?
- Does the view body do expensive or repeated work?
- Is identity stable in `ForEach`, `List`, and async reload paths?
- Are side effects tied to view lifecycle instead of hidden in `body`?

### Architecture & API Design

- Are dependencies injected from the composition root?
- Does the abstraction reduce coupling, or just add indirection?
- Are access control and module boundaries as narrow as possible?
- Will this pattern scale if repeated in three more features?

### Ownership & Memory

- Can closures, delegates, or async callbacks retain objects unexpectedly?
- Is `unowned` actually safe?
- Would value semantics remove shared mutable state entirely?

### Error Handling & Observability

- Are thrown errors typed, meaningful, and preserved?
- Are retries, fallbacks, and logging intentional and bounded?
- Does the failure reach the correct layer?

### Testing & Tooling

- Do tests cover the risky behavior, not just the happy path?
- Are concurrency and cancellation semantics exercised?
- Does CI enforce formatter, linter, and warnings-as-errors policies?
