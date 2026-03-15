# Swift Engineering Review Skill

Structured code review skill for any AI coding tool that supports the Agent Skills open format: Swift 6, Xcode 26, iOS 26 SDK, concurrency safety, API design, and tooling enforcement.

## Important Disclaimers

### Work in Progress

This skill is a work in progress and has not been exhaustively tested. It is provided as-is, and **it is the responsibility of the developer** to thoroughly test and validate any changes suggested through the use of this skill. Ensure that all review findings and suggested fixes are correct and appropriate for your codebase before applying them.

### Engineering Review Is Not Deterministic

Unlike mechanical linting, code review involves **judgment**. There is rarely a single "correct" fix for an engineering concern. Multiple approaches can be valid, each with different trade-offs. Evaluate suggestions in context and choose what works best for your team.

**This skill is an aid, not a substitute for thoughtful engineering.** Use it to surface issues and guide decisions, but do not treat it as infallible. Real code quality requires continuous learning, peer review, and testing.

**Your feedback helps improve this skill.** If you run into issues, share your prompt and a sample of the output (whatever you are comfortable sharing) so we can refine these guidelines. Positive feedback is also useful to understand what is working well.

## Who This Is For

- Developers building Swift apps who want structured, consistent code reviews
- Teams wanting to enforce Swift 6 concurrency safety, naming conventions, and style standards
- Anyone reviewing Swift pull requests, auditing architecture decisions, or enforcing tooling standards with swift-format and SwiftLint

## How to Use This Skill

### Option A: Using skills.sh (recommended)

Install this skill with a single command:

```bash
npx skills add https://github.com/bairisland/swift-engineering-review
```

Then use the skill in your AI agent, for example:

> Use the swift-engineering-review skill to review this pull request for concurrency safety and API design issues.

### Option B: Manual Install

1. **Clone** this repository
2. **Install or symlink** the skill folder following your tool's skills installation docs
3. **Use your AI tool** and ask it to use the "swift-engineering-review" skill for review tasks

#### Where to Save Skills

- **Codex:** [Where to save skills](https://codex.openai.com/docs/skills)
- **Claude Code:** [Using Skills](https://docs.anthropic.com/claude-code/skills)
- **Cursor:** [Enabling Skills](https://docs.cursor.com/skills)

## What This Skill Covers

### Review Areas

- **Correctness**: Force-unwraps, force-try, optional safety, exhaustive switches, compile warnings
- **Concurrency Safety**: Data races, actor isolation, Sendable correctness, structured concurrency, MainActor usage, cancellation handling, `Mutex` usage, `sending` parameters, `@isolated(any)`, `nonisolated(unsafe)` auditing
- **SwiftUI & State**: State ownership, identity stability, view composition, observable migration (`ObservableObject` → `@Observable`), invalidation pressure
- **API Design & Naming**: Swift API Design Guidelines, argument labels, access control, generics naming
- **Code Organization**: Extensions, protocol conformance structure, MARK sections, unused code removal, minimal imports
- **Memory Management**: Capture lists, retain cycles, weak/unowned semantics, IBOutlet conventions
- **Error Handling**: Typed errors, catch specificity, precondition/fatalError usage, error preservation
- **Testing**: Swift Testing framework, test pyramid, determinism, dependency injection, behavior-driven tests
- **Style & Formatting**: Spacing, braces, colons, line length, syntactic sugar, inferred context, guard patterns
- **Tooling**: swift-format enforcement, SwiftLint strict mode, CI configuration
- **Git Standards**: Conventional commit format, commit sizing

### Severity Model

| Level | Meaning |
|---|---|
| **blocker** | Will crash, corrupt data, cause a data race, or create a security hole |
| **major** | Incorrect behavior, significant performance issue, or API misuse |
| **minor** | Style violation, suboptimal pattern, or maintainability concern |
| **nit** | Cosmetic preference or trivial improvement |

### Remediation Playbooks

Every finding links to a remediation playbook — a structured fix pattern with detection signals, before/after code examples, and risk notes. The skill includes 13 playbooks organized by domain:

**Concurrency** — `actor isolation`, `mutex usage`, `sending parameters`, `@isolated(any)`, `nonisolated(unsafe)`, `task lifetime`

**SwiftUI & State** — `state ownership`, `identity stability`, `observable migration`

**General** — `retain-cycle removal`, `typed errors`, `dependency injection`, `test hardening`

### Finding Confidence Scoring

When a file contains signals for multiple playbooks, the routing layer uses signal weights to determine the primary finding. Each detected pattern adds a weight to the matching playbook's score. The highest-scoring playbook becomes the primary finding, preventing over-triggering when signals overlap.

### Cross-File Reasoning

For PR-level and module-level reviews, the skill applies cross-file checks that single-file analysis would miss:

- Shared mutable state accessed across actor boundaries in different files
- Global mutable state (`nonisolated(unsafe) var`) referenced from multiple files
- Cross-module dependency inversion (lower module importing higher module)
- Mixed observation patterns (`ObservableObject` + `@Observable`) across a view hierarchy
- Non-`Sendable` models passed across isolation boundaries between files

### Tooling Scripts

The `scripts/` directory provides helper scripts for automated checks:

- `check_prereqs.sh` — Verify swift-format and SwiftLint are available
- `format_swift.sh` — Run the official Swift formatter
- `lint_swift.sh` — Run SwiftLint in strict mode
- `fix_and_lint.sh` — Format, auto-fix, then lint

## Output Stability Testing

The `tests/` directory contains golden test fixtures for verifying the skill produces consistent, correct output across model updates.

Each fixture is a Swift file with known issues paired with an expected output file that defines structural assertions — which playbooks should fire, at what severity, and what must not happen.

| Fixture | Tests |
|---|---|
| `concurrency_data_race.swift` | `@unchecked Sendable` race → `actor isolation` (blocker) |
| `swiftui_observable_migration.swift` | Legacy `ObservableObject` → `observable migration` (nit) |
| `mixed_observation.swift` | Mixed old/new observation → `observable migration` (major) |
| `retain_cycle_delegate.swift` | Strong delegate + closure → `retain-cycle removal` (major) |
| `nonisolated_unsafe_globals.swift` | Mutable unsafe globals → `nonisolated(unsafe)` (blocker) |

Run the golden tests:

```bash
./tests/run_golden_tests.sh
```

See [`tests/README.md`](tests/README.md) for details on adding new fixtures.

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

## Scope and Non-Goals

This skill is focused on Swift engineering review: code correctness, concurrency safety, style enforcement, and tooling validation.

This skill does not try to be:

- A replacement for peer review by experienced engineers
- A legal compliance service
- A guide for non-Swift platforms
- An accessibility audit tool (see complementary skills below)

## Complementary Skills

- [iOS-Accessibility-Agent-Skill](https://github.com/dadederk/iOS-Accessibility-Agent-Skill) by Daniel Devesa Derksen-Staats — Expert iOS accessibility guidance
- [swift-accessibility-skill](https://github.com/PasqualeVittoriosi/swift-accessibility-skill) by Pasquale Vittoriosi — Swift accessibility with macOS and WCAG coverage
- [SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) by Antoine van der Lee — SwiftUI best practices

## Inspiration and Acknowledgements

This skill was inspired by the Agent Skills open format and the growing ecosystem of reusable AI knowledge for development workflows.

- [Agent Skills: Replacing AGENTS.md with reusable AI knowledge](https://www.avanderlee.com/ai-development/agent-skills-replacing-agents-md-with-reusable-ai-knowledge/) by Antoine van der Lee

## Skill Structure

```text
swift-engineering-review/
├── SKILL.md                            # Entry point and review workflow
├── agents/
│   └── openai.yaml                     # Public-facing display metadata
├── evals/
│   └── evals.json                      # Evaluation assertions (14 evals)
├── references/
│   ├── review-routing.md               # Track selection, confidence scoring, cross-file reasoning
│   ├── review-checklist.md             # Structured review checklist
│   ├── remediation-playbooks.md        # 13 playbooks with examples and risk notes
│   ├── swiftui-review.md              # SwiftUI heuristics and observable migration
│   ├── swift-style-guide.md            # Swift 6 style, naming, and formatting criteria
│   ├── tooling.md                      # swift-format and SwiftLint setup
│   └── example-findings.md             # Example review output at each severity
├── scripts/
│   ├── check_prereqs.sh                # Verify tooling availability
│   ├── format_swift.sh                 # Run swift format in-place
│   ├── lint_swift.sh                   # Run SwiftLint --strict
│   └── fix_and_lint.sh                 # Format → auto-fix → strict lint
└── tests/
    ├── README.md                       # Test infrastructure docs
    ├── run_golden_tests.sh             # Structural assertion runner
    ├── fixtures/                       # Swift files with known issues
    │   ├── concurrency_data_race.swift
    │   ├── mixed_observation.swift
    │   ├── nonisolated_unsafe_globals.swift
    │   ├── retain_cycle_delegate.swift
    │   └── swiftui_observable_migration.swift
    └── expected/                       # Structural assertions per fixture
        ├── concurrency_data_race.md
        ├── mixed_observation.md
        ├── nonisolated_unsafe_globals.md
        ├── retain_cycle_delegate.md
        └── swiftui_observable_migration.md
```

## Contributing

Contributions are welcome! This repository follows the [Agent Skills open format](https://agentskills.io).

## License

This skill is open-source and available under the MIT License. See [LICENSE](LICENSE) for details.
