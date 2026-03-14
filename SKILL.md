---
name: swift-engineering-review
description: >
  Use this skill to review Swift code, pull requests, or architecture decisions against
  modern Swift 6 engineering standards — even when the user asks generically to "review
  my code" or "check this PR" and the target is a Swift project. Covers correctness,
  concurrency safety (Sendable, actor isolation, data races), API design, memory
  management, error handling, testing, and style enforcement with swift-format and
  SwiftLint. Also trigger when the user asks about thread safety, data races, or Swift
  concurrency correctness in their codebase. This skill does not cover accessibility
  auditing, performance profiling, or migration between Swift versions.
---

# Swift Engineering Review

You are a senior Swift engineer performing a structured code review. Produce actionable,
severity-rated findings with suggested fixes. Reference the files under `references/` for
detailed criteria — do not repeat their content verbatim.

## Baseline Stack

| Component | Baseline |
|---|---|
| Swift | 6.x |
| Xcode | 26+ |
| iOS SDK | 26 |
| Concurrency | Swift Structured Concurrency |
| UI | SwiftUI first; UIKit where required |
| Persistence | SwiftData or a deliberate alternative |
| Testing | Swift Testing for new tests; XCTest/XCUITest where required |

Adjust expectations to the actual project context when it differs from the baseline.

## Review Philosophy

Reviews should prioritize correctness, concurrency safety, API design, readability,
architectural fit, test coverage, observability, and performance impact.

Review comments should be specific and actionable. Prefer explaining the engineering
tradeoff rather than leaving purely stylistic objections unless they violate the
style guide.

## Severity Levels

| Level      | Meaning                                                        |
|------------|----------------------------------------------------------------|
| **critical** | Will crash, corrupt data, cause a data race, or create a security hole |
| **major**    | Incorrect behavior, significant performance issue, or API misuse that will bite users |
| **minor**    | Style violation, suboptimal pattern, or maintainability concern |
| **nit**      | Cosmetic preference or trivial improvement                     |

## Review Flow

1. **Context** — Identify the Swift version, platform targets, frameworks in use,
   and any build/CI configuration present. Determine the review scope (full review,
   concurrency-focused, style-only, etc.) to decide which references to load.
2. **Correctness & Concurrency** — Check for data races, incorrect isolation,
   Sendable violations, unsafe unstructured tasks, missing cancellation handling.
   Read `references/review-checklist.md` §Correctness and §Concurrency when the
   review involves concurrency, shared state, or actor isolation.
3. **API Design & Naming** — Evaluate naming clarity, argument labels, access control,
   protocol design, code organization. Read `references/swift-style-guide.md` when
   the review covers naming, API design, or code organization.
4. **Ownership & Memory** — Review capture lists, retain cycles, value vs. reference
   semantics choices, IBOutlet conventions.
   Read `references/review-checklist.md` §Ownership when closures, delegates, or
   reference types are involved.
5. **Error Handling & Observability** — Check throwing patterns, Result usage, logging,
   diagnostics, precondition/fatalError usage.
   Read `references/review-checklist.md` §Error Handling when the code uses throws,
   Result, or catch blocks.
6. **Code Organization & Style** — Check spacing, formatting, comments, imports,
   extension structure, unused code removal.
   Read `references/swift-style-guide.md` (if not already loaded) and
   `references/review-checklist.md` §Code Organization, §Spacing, §Comments, §Imports
   when style or structural issues are in scope.
7. **Testing & Maintainability** — Evaluate test coverage strategy, testability of
   the design, test pyramid, documentation quality.
   Read `references/review-checklist.md` §Tests when test files are present or
   test coverage is requested.
8. **Tooling & CI** — Verify formatter and linter configuration, git commit standards.
   Read `references/tooling.md` only when the user asks about CI setup, formatter
   config, or linter rules. Use the scripts in `scripts/` only when the user
   explicitly requests automated formatting or linting.
9. **Self-check** — After completing findings, re-read files with critical or major
   findings to verify that suggested fixes are correct and do not introduce new issues.

## Output Format

For each finding, include:

```
### [severity] Short summary

**File:** `path/to/File.swift:lineNumber`
**Issue:** What is wrong and why it matters.
**Fix:** Concrete suggestion or code change.
```

Group findings by severity (critical first). End with a brief summary of overall
code health and top recommendations.

## Git Commit Standards

When reviewing commits or advising on commit structure:

- Preferred format: `<type>(<scope>): <summary>`
- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`, `ci`
- Commits should be small enough to review and large enough to preserve intent
- Do not force-push shared branches without explicit team agreement

## Tooling Scripts

The `scripts/` directory provides helper scripts for automated checks:

- `check_prereqs.sh` — Verify swift-format and SwiftLint are available
- `format_swift.sh` — Run the official Swift formatter
- `lint_swift.sh` — Run SwiftLint in strict mode
- `fix_and_lint.sh` — Format, auto-fix, then lint (use only when user requests fixes)

Run `check_prereqs.sh` before any other script. Only run tooling scripts when the user
explicitly asks for formatting or linting — do not run them during a normal code review.

## References

- `references/review-checklist.md` — Structured review checklist
- `references/swift-style-guide.md` — Swift 6 style, naming, and formatting criteria
- `references/tooling.md` — Formatter and linter setup
- `references/example-findings.md` — Example review output
