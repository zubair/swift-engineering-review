---
name: swift-engineering-review
description: >
  Use this skill to review Swift code, pull requests, or architecture decisions against
  modern Swift 6 engineering standards. Trigger even when the user asks generically to
  "review this PR" or "check my code" and the target is Swift. Handles correctness,
  Swift 6 concurrency, SwiftUI state and lightweight performance heuristics, API design,
  memory management, error handling, testing, and CI/tooling. Also use for thread
  safety, actor isolation, data races, large Swift PR triage, and patch-ready refactor
  guidance. Do not use it for accessibility audits, Instruments-based profiling, or
  cross-version migration planning.
---

# Swift Engineering Review

Perform a repeatable engineering audit, not a checklist dump. Triage the change, load
only the relevant tracks, then produce a deterministic scorecard, severity-ranked
findings, and concrete remediation steps.

## Activation

Use this skill when:

- reviewing Swift, SwiftUI, UIKit, Package.swift, or Apple-platform code
- the user asks for code review, PR review, architecture review, thread-safety review,
  concurrency audit, API review, test review, or SwiftUI state/performance feedback
- the request is generic but the repo or files clearly indicate Swift

Do not use this skill for:

- accessibility audits
- benchmark or Instruments profiling
- migration planning between Swift language versions unless the user is reviewing
  already-migrated code

## Operating Rules

- Classify the change before loading references.
- Route to the smallest relevant set of review tracks.
- Prioritize blocker and major risks over style commentary.
- Every finding must explain why it matters and how to fix it.
- Report PASS/WARN/FAIL for relevant tracks even when there are no findings.
- Avoid repeating reference text verbatim; use the references to drive judgment.

### Evidence Discipline

Every finding must be classified by evidence level:

- **observed** — the defect is directly visible in the reviewed code (e.g. bare `catch {}`,
  `@unchecked Sendable` on a class with mutable stored properties).
- **inferred** — the risk is likely based on visible patterns but depends on unseen code
  (e.g. a `Task {}` probably outlives its owner, but the full lifecycle is not visible).
- **needs-confirmation** — the finding is a hypothesis that requires checking additional
  files, runtime behavior, or team context before acting on it.

Rules:

- Only `observed` findings can be rated `blocker`.
- `inferred` findings cap at `major` unless corroborating evidence raises confidence.
- `needs-confirmation` findings cap at `minor` and must state what needs checking.
- Do not assert runtime behavior that cannot be supported by the visible code.
- Do not claim line-level certainty when the full file or PR context is unavailable.
- When reviewing a snippet rather than a complete file, state this limitation in the
  Overall Verdict and downgrade confidence accordingly.
- Ask for missing files only when a finding depends on unseen definitions — do not
  speculatively request context.

### Patch Suggestion Policy

When suggesting code changes:

- Prefer minimally invasive fixes that address the finding without restructuring
  surrounding code.
- Structural refactors are appropriate only when the finding is `major` or `blocker` and
  the fix cannot be isolated.
- Do not introduce new abstractions, protocols, or indirection unless the finding
  specifically calls for it.
- Style-only findings (`nit`, `minor`) should suggest the smallest edit that resolves the
  issue — not a rewrite of the surrounding function.

### False-Positive Controls

- Style-only reviews (naming, formatting, organization) must not produce `blocker` or
  `major` findings unless a correctness or performance issue is genuinely present.
- If the review scope is explicitly style-only, cap all findings at `minor`.
- Do not invent concurrency or correctness risks to justify a higher severity when the
  actual issue is cosmetic.

## Triage Workflow

1. Identify the review unit: single file, PR, module, or architecture discussion.
2. Scan for signals and load only the matching references:
   - SwiftUI signals: `View`, `body`, `@State`, `@Bindable`, `@Environment`,
     `@Observable`, `ForEach`, `.task`, `.sheet`, `ObservableObject`, `@Published`,
     `@StateObject`, `@ObservedObject`
     - Load `references/swiftui-review.md` and `references/review-routing.md`.
   - Concurrency signals: `async`, `await`, `Task`, `TaskGroup`, `actor`, `Sendable`,
     `Mutex`, `@MainActor`, `nonisolated`, `AsyncSequence`, `sending`,
     `@isolated(any)`, `nonisolated(unsafe)`
     - Load `references/review-routing.md` and the Concurrency section of
       `references/review-checklist.md`.
   - Architecture signals: many touched directories, DI, repositories, services,
     protocols, package boundaries, navigation composition, or PRs larger than about
     500 changed lines
     - Load `references/review-routing.md` and the Architecture section of
       `references/review-checklist.md`.
   - Error-handling or networking signals: `throws`, `Result`, `catch`, retry logic,
     logging, URLSession, decoding
     - Load the Error Handling section of `references/review-checklist.md` and
       `references/remediation-playbooks.md`.
   - Naming, style, or organization signals
     - Load `references/swift-style-guide.md`.
   - Tests, formatter, or CI signals
     - Load the Tests section of `references/review-checklist.md` and
       `references/tooling.md`.
3. Build a scorecard from the relevant tracks only.
4. Emit findings grouped by severity.
5. End with a remediation plan split into quick wins, structural fixes, and tests to
   add.
6. Re-check every blocker or major finding against the code before finalizing.

## Severity Policy

| Level | Use when |
|---|---|
| `blocker` | Data race, crash, corruption, security issue, broken isolation boundary, or guaranteed lifetime bug |
| `major` | Incorrect behavior, high-risk API misuse, architectural flaw that will spread, or serious SwiftUI state/performance issue |
| `minor` | Maintainability problem, localized performance smell, missing tests, or suboptimal ownership/design |
| `nit` | Cosmetic or low-impact polish |

Use the highest defensible severity. Do not inflate style findings to hide the absence
of real risk.

## Review Modes

The skill defaults to a **full review**. When the user specifies a narrower scope, route
into the matching mode to avoid loading unnecessary tracks.

| Mode | Trigger | Tracks loaded | Severity cap |
|---|---|---|---|
| Full review | "review this PR", "check my code", generic request | All matching tracks | No cap |
| Concurrency audit | "thread safety", "data race", "concurrency audit", "actor isolation" | Concurrency + Correctness | No cap |
| SwiftUI review | "SwiftUI review", "state management", "view performance" | SwiftUI & Performance + Correctness | No cap |
| Architecture review | "architecture review", "API design", "dependency review" | Architecture & API Design + Correctness | No cap |
| Test review | "test review", "test coverage", "test strategy" | Testing & Tooling | No cap |
| Style review | "style review", "naming review", "formatting check" | Correctness (style subset) | `minor` |

When in a narrowed mode, still flag `blocker` correctness issues if encountered — they
are never silenced by mode selection.

## Output Contract

Use this exact section order:

```markdown
## Review Scorecard
- Correctness: PASS | WARN | FAIL
- Concurrency: PASS | WARN | FAIL | N/A
- SwiftUI & Performance: PASS | WARN | FAIL | N/A
- Architecture & API Design: PASS | WARN | FAIL | N/A
- Ownership & Memory: PASS | WARN | FAIL | N/A
- Error Handling & Observability: PASS | WARN | FAIL | N/A
- Testing & Tooling: PASS | WARN | FAIL | N/A

## Findings
### [blocker|major|minor|nit] Short summary

**File:** `path/to/File.swift:line`
**Confidence:** high | medium | low
**Evidence:** observed | inferred | needs-confirmation
**Why it matters:** Concrete risk and user impact.
**Fix:** Concrete code or design change.
**Playbook:** One label from `references/remediation-playbooks.md` when a reusable fix
path applies.

## Remediation Plan
- Quick wins: immediate, low-risk edits
- Structural fixes: larger design changes
- Tests to add: behavior, concurrency, or regression coverage

## Overall Verdict
1-3 sentences on readiness, highest-risk area, and next step.
```

### Confidence Levels

- **high** — the defect is visible in the code with no ambiguity; the fix is clear.
- **medium** — the pattern strongly suggests a problem, but full confirmation requires
  additional context (e.g. checking a caller, a test, or a deployment target).
- **low** — the finding is a plausible risk based on heuristics, but the reviewer cannot
  confirm it from the available code. Always pair with `needs-confirmation` evidence.

### Confidence–Severity Matrix

| Evidence | Max severity | Confidence |
|---|---|---|
| observed | blocker | high |
| inferred | major | medium or high |
| needs-confirmation | minor | low |

If a track is not relevant, mark it `N/A`. If there are no findings in a relevant
track, leave the track as `PASS` and say so briefly in the verdict.

## Reference Map

- `references/review-routing.md` — decision tree, track selection, and scorecard rules
- `references/review-checklist.md` — deep checklist for correctness, concurrency,
  architecture, tests, and review hygiene
- `references/swiftui-review.md` — SwiftUI state ownership and lightweight performance
  heuristics
- `references/swift-style-guide.md` — naming, organization, and style criteria
- `references/remediation-playbooks.md` — patch-ready fix patterns for common findings
- `references/tooling.md` — formatter, linter, and CI guidance
- `references/example-findings.md` — example scorecard and finding layout

## Tooling Scripts

Use the scripts in `scripts/` only when the user explicitly asks for formatting,
linting, or automated cleanup:

- `scripts/check_prereqs.sh` — verify `swift format` and `swiftlint`
- `scripts/format_swift.sh` — run the Swift formatter
- `scripts/lint_swift.sh` — run SwiftLint in strict mode
- `scripts/fix_and_lint.sh` — format, auto-fix, then lint

Run `scripts/check_prereqs.sh` before any other script. Do not run formatting or
linting during a normal review unless the user asked for it.
