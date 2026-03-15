# Swift Review Routing

Use this file to decide which review tracks to run and how to score them. Start narrow,
then add tracks only when the code or the request clearly requires them.

## Track Selection

| Signal | Track | Load | Focus |
|---|---|---|---|
| `async`, `await`, `Task`, `TaskGroup`, `actor`, `Sendable`, `@MainActor`, `AsyncSequence`, `Mutex`, `sending`, `@isolated(any)`, `nonisolated(unsafe)` | Concurrency | This file + `review-checklist.md` Concurrency | Isolation boundaries, task lifetime, cancellation, Sendable correctness, mutex usage, sending safety |
| `View`, `body`, `@State`, `@Bindable`, `@Binding`, `@Environment`, `@Observable`, `ForEach`, `.task`, `.sheet`, `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject` | SwiftUI & Performance | This file + `swiftui-review.md` | State ownership, identity stability, invalidation pressure, view lifecycle, observable migration |
| Repositories, services, DI, protocols, modules, large PRs | Architecture & API Design | This file + `review-checklist.md` Architecture | Dependency direction, abstraction discipline, module boundaries, access control |
| `throws`, `Result`, `catch`, retry logic, logging | Error Handling & Observability | `review-checklist.md` Error Handling + `remediation-playbooks.md` | Error typing, propagation, retries, diagnostics |
| Closures, delegates, reference types | Ownership & Memory | `review-checklist.md` Ownership + `remediation-playbooks.md` | Retain cycles, weak/unowned safety, reference vs value semantics |
| Tests, CI, formatter, SwiftLint | Testing & Tooling | `review-checklist.md` Tests + `tooling.md` | Risk-driven coverage, determinism, CI enforcement |
| Naming, imports, organization, comments | Correctness or Architecture & API Design | `swift-style-guide.md` | Clarity, consistency, and code organization |

## Detection Predicates

Use these predicates to route detected signals to the correct remediation playbook.

### Concurrency Predicates

| Signal | Condition | Playbook |
|---|---|---|
| `@unchecked Sendable`, shared `var` across tasks, `DispatchQueue` protecting state | Mutable state accessed from multiple isolation domains | `actor isolation` |
| `DispatchQueue.sync` guarding single property, `os_unfair_lock`, `NSLock` for trivial section | Small synchronous critical section that does not suspend | `mutex usage` |
| Parameter passed into `Task {}` or across actor boundary, non-`Sendable` value transfer | Value crosses isolation boundary without `sending` | `sending parameters` |
| `@MainActor () -> Void` closure param, forced actor hop on generic callback | Closure forced to specific actor when caller isolation varies | `@isolated(any)` |
| `nonisolated(unsafe)` without safety-invariant comment | Escape hatch used without documented rationale | `nonisolated(unsafe)` |
| `Task {}` without stored handle, no `.cancel()`, fire-and-forget in view | Unstructured task with no owner or cancellation path | `task lifetime` |

### SwiftUI Predicates

| Signal | Condition | Playbook |
|---|---|---|
| `@State` holding reference type, model created in `body` | State owned by the wrong layer or duplicated | `state ownership` |
| `ForEach(indices)`, `UUID()` in `body`, `id: \.self` on mutable collection | Unstable identity causing spurious invalidation | `identity stability` |
| `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, mixed old/new observation | Legacy observation pattern or mixed-observation double-invalidation | `observable migration` |

### General Predicates

| Signal | Condition | Playbook |
|---|---|---|
| Closure on `self` without `[weak self]`, strong `var delegate` | Closure or delegate retains owner beyond its lifetime | `retain-cycle removal` |
| Bare `catch {}`, `try?` discarding error, string-based error messages | Error information lost or swallowed | `typed errors` |
| `.shared` singleton, `init()` creating own dependencies | Hidden coupling preventing testing and evolution | `dependency injection` |
| No test for public type, happy-path-only test suite | Risky behavior lacks regression coverage | `test hardening` |

## Finding Confidence Scoring

When a file contains signals for multiple playbooks, use signal weights to determine the
primary finding. This prevents over-triggering and ensures the most relevant playbook is
recommended first.

### How It Works

1. For each detected signal in the file, add the weight to the matching playbook's score.
2. The playbook with the highest score becomes the **primary finding**.
3. Secondary playbooks (score ≥ 3) may be mentioned as additional recommendations.
4. Playbooks scoring below 3 should not generate standalone findings — fold them into the
   primary finding's fix guidance if relevant.

### Signal Weights

#### Observable Migration

| Signal | Weight |
|---|---|
| `ObservableObject` conformance | +3 |
| `@Published` property | +2 |
| `@StateObject` usage | +2 |
| `@ObservedObject` usage | +2 |
| `objectWillChange.send()` | +2 |
| Mixed `ObservableObject` + `@Observable` in same hierarchy | +4 (and escalate to `major`) |

#### Actor Isolation

| Signal | Weight |
|---|---|
| `@unchecked Sendable` on class with mutable state | +4 |
| Shared `var` mutated inside `Task {}` | +3 |
| `DispatchQueue` used solely for property synchronization | +2 |
| Non-sendable type crossing isolation boundary | +2 |

#### Task Lifetime

| Signal | Weight |
|---|---|
| `Task {}` inside `body` or `onAppear` without `.task` | +4 |
| `Task {}` with no stored handle or `.cancel()` | +3 |
| Fire-and-forget writing back to `@State` | +3 |

#### State Ownership

| Signal | Weight |
|---|---|
| `@State` holding a reference type | +4 |
| Model created inside `body` | +3 |
| Multiple views holding `@State` for same data | +2 |

#### Identity Stability

| Signal | Weight |
|---|---|
| `ForEach(indices, id: \.self)` on mutable collection | +4 |
| `UUID()` in `body` or computed property | +3 |
| `id: \.self` on non-`Identifiable` duplicable values | +2 |

#### Mutex Usage

| Signal | Weight |
|---|---|
| `DispatchQueue.sync` guarding single property | +3 |
| `os_unfair_lock` or `NSLock` for trivial section | +3 |
| Synchronous-only critical section (no `await` inside) | +2 |

#### Retain-Cycle Removal

| Signal | Weight |
|---|---|
| Closure capturing `self` without `[weak self]`, closure outlives owner | +4 |
| Strong `var delegate` | +3 |
| `Timer` or `NotificationCenter` observer without weak reference | +2 |

#### Typed Errors

| Signal | Weight |
|---|---|
| Bare `catch {}` | +4 |
| `try?` discarding diagnostic error | +3 |
| String-based error messages instead of typed enum | +2 |

### Scoring Example

A file containing a SwiftUI `View` with `@StateObject`, `@Published` model,
`Task {}` in `onAppear`, and `ForEach(indices, id: \.self)`:

```
observable migration:  @StateObject(+2) + @Published(+2) = 4  ← secondary
task lifetime:         Task{} in onAppear(+4) = 4             ← tied primary
identity stability:    ForEach indices(+4) = 4                 ← tied primary
state ownership:       (no direct signals) = 0
```

When scores tie, prefer the higher-severity finding (blocker > major > minor). If
severity also ties, lead with the concurrency finding — data races are harder to debug
than UI issues.

## Cross-File Reasoning

Single-file analysis misses module-level and architecture-level issues. When the review
scope is a PR, module, or repo, apply these cross-file checks in addition to per-file
analysis.

### When to Apply

- PR spans 3+ files across different layers (view, model, service, network)
- Review scope is explicitly a module, package, or architecture review
- Per-file analysis produces repeated similar findings across files (systemic pattern)

### Cross-File Checks

#### Shared Mutable State Across Actors

- **What to look for:** A model or service defined in one file is mutated from actor-isolated
  code in another file without going through the actor's isolation boundary.
- **Detection:** `actor` defined in file A; direct property access (not `await`) on that
  actor's state from file B. Or: class marked `@unchecked Sendable` in file A, mutated
  from `Task {}` in file B.
- **Playbook:** `actor isolation`

#### Global Mutable State

- **What to look for:** `var` at module scope or `static var` on a type, accessed from
  multiple files without synchronization.
- **Detection:** `nonisolated(unsafe) var` or unprotected `static var` referenced in 2+
  files.
- **Playbook:** `nonisolated(unsafe)` or `actor isolation`

#### Cross-Module Dependency Inversion

- **What to look for:** A lower-level module imports and depends on a higher-level module,
  or concrete types from one feature module are used directly in another.
- **Detection:** `import FeatureX` in a shared/core module; concrete type from module A
  used as a parameter in module B's public API without a protocol boundary.
- **Playbook:** `dependency injection`

#### Observation Consistency Across View Hierarchy

- **What to look for:** Parent view uses `@Observable` while child view still uses
  `@ObservedObject` or `@EnvironmentObject`, causing mixed observation and
  double-invalidation.
- **Detection:** `@Observable` in model file A; `@ObservedObject` or `@StateObject` in
  view file B referencing the same model type.
- **Playbook:** `observable migration` (escalate to `major`)

#### Shared Model Without Sendable Safety

- **What to look for:** A model type used across actor boundaries (e.g. passed from a
  background service to a `@MainActor` view model) without `Sendable` conformance or
  `sending` annotation.
- **Detection:** Type defined in file A without `Sendable`; passed across `await` boundary
  in file B.
- **Playbook:** `sending parameters` or `actor isolation`

### Reporting Cross-File Findings

Cross-file findings use the same output format as per-file findings, but the `File:` field
lists all relevant files:

```markdown
**File:** `Services/CacheActor.swift:12`, `ViewModels/ProfileVM.swift:45`
```

Cross-file findings are inherently higher risk. Default to `major` severity unless the
pattern is clearly a `nit`.

## Mandatory Escalation Rules

Always run the Architecture & API Design track when any of the following is true:

- the PR spans multiple layers or packages
- the diff is roughly larger than 500 changed lines
- the change introduces new protocols, services, repositories, or navigation roots
- the review contains repeated similar findings that indicate a systemic design issue

Always run the Concurrency track when shared mutable state or UI-bound async work is
present, even if the user only asked for a generic review.

## Scorecard Rules

| Grade | Criteria | Examples |
|---|---|---|
| `PASS` | No meaningful issues, or only one low-value nit | Clean concurrency with correct isolation; well-structured SwiftUI state |
| `WARN` | One or more minor issues, or a design smell that deserves follow-up but does not block merge | Missing cancellation handling in a non-critical path; oversized `body` without correctness risk |
| `FAIL` | Any blocker or major issue, or 3+ minor issues that expose a broken pattern | Data race on shared state; mixed observation causing double-invalidation; no tests for public API with side effects |
| `N/A` | The track is genuinely out of scope for the reviewed code | No concurrency in a pure formatting utility; no SwiftUI in a CLI tool |

The scorecard is not a summary of how much code was touched. It is a risk signal.

Escalation rules:
- A single `blocker` in any track → that track is `FAIL`.
- A single `major` in any track → that track is `FAIL`.
- 3+ `minor` issues in the same track → escalate to `WARN` at minimum; `FAIL` if they
  expose a systemic pattern.
- `nit`-only tracks remain `PASS` regardless of count.

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
- Is `Mutex` held only for synchronous sections (never across `await`)?
- Is `sending` used at isolation boundaries where values transfer ownership?
- Does every `nonisolated(unsafe)` have a documented safety invariant?

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
- Is the dependency direction correct (lower modules do not import higher modules)?
- Are feature boundaries clean (no cross-feature concrete type references)?
- Are protocol abstractions justified by multiple implementations or proven test pressure?
- Is state ownership clear (who creates, holds, and mutates each shared model)?
- Is navigation composition centralized or scattered across feature modules?
- Are async boundaries placed at the right layer (not leaking into views or pure models)?
- Do test seams exist for every external dependency (network, storage, time, randomness)?

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
