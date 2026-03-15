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

## Triage Workflow

1. Identify the review unit: single file, PR, module, or architecture discussion.
2. Scan for signals and load only the matching references:
   - SwiftUI signals: `View`, `body`, `@State`, `@Bindable`, `@Environment`,
     `@Observable`, `ForEach`, `.task`, `.sheet`
     - Load `references/swiftui-review.md` and `references/review-routing.md`.
   - Concurrency signals: `async`, `await`, `Task`, `TaskGroup`, `actor`, `Sendable`,
     `Mutex`, `@MainActor`, `nonisolated`, `AsyncSequence`
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
