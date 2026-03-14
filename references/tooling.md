# Swift Tooling Reference

## Official Formatter: swift-format

The official Swift formatter ships with the Swift 6 toolchain (Xcode 16+).

### Invocation

The primary CLI entrypoint is `swift format`:

```bash
# Format in place, recursively
swift format format --in-place --recursive .

# Check without modifying (CI mode)
swift format lint --recursive .
```

### Locating the Binary

The underlying binary is `swift-format`. To find its path:

```bash
xcrun --find swift-format
```

This is useful for diagnostics and for editors that need an explicit binary path.

### Alternative Installation

If the toolchain does not include `swift-format` (older Xcode versions):

```bash
brew install swift-format
```

After installation, `swift-format` is available directly. The `swift format` subcommand
requires the Swift 6+ toolchain.

### Configuration

`swift-format` reads `.swift-format` (JSON) from the project root. Key options:

- `indentation`: spaces or tabs
- `maximumBlankLines`: controls vertical whitespace
- `lineLength`: default 100

Generate a default config:

```bash
swift-format dump-configuration > .swift-format
```

## SwiftLint

SwiftLint enforces style rules beyond what the formatter handles.

### Installation

```bash
brew install swiftlint
```

### Usage

```bash
# Lint with strict mode (warnings become errors)
swiftlint --strict

# Auto-fix correctable violations
swiftlint --fix

# Use a specific config
swiftlint --config .swiftlint.yml --strict
```

### Configuration

Place `.swiftlint.yml` at the repo root. Recommended starting point:

```yaml
opt_in_rules:
  - closure_body_length
  - empty_count
  - explicit_init
  - fatal_error_message
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - multiline_arguments
  - multiline_parameters
  - overridden_super_call
  - private_outlet
  - sorted_imports
  - unowned_variable_capture
  - vertical_whitespace_closing_braces

disabled_rules: []

excluded:
  - .build
  - DerivedData
  - Packages
```

## CI Recommendations

1. **Run the formatter in check mode** as an early CI step:
   ```bash
   swift format lint --recursive --strict . || { echo "Run 'swift format format --in-place --recursive .' to fix."; exit 1; }
   ```

2. **Run SwiftLint in strict mode** after the formatter:
   ```bash
   swiftlint --strict
   ```

3. **Fail the build on warnings** with `-warnings-as-errors` in the Swift compiler flags.

4. **Pin tool versions** in CI to avoid drift between local and CI environments.

## Local Workflow

The scripts in `scripts/` automate the common local workflow:

| Script              | Purpose                                      |
|---------------------|----------------------------------------------|
| `check_prereqs.sh`  | Verify swift-format and SwiftLint are installed |
| `format_swift.sh`   | Format all Swift sources in place            |
| `lint_swift.sh`     | Run SwiftLint in strict mode                 |
| `fix_and_lint.sh`   | Format → auto-fix → strict lint (full cleanup) |

All scripts accept an optional target path argument (defaults to `.`).
