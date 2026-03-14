# Swift 6 Style & Naming Review Criteria

Review code against these criteria. Flag deviations as findings with appropriate severity.

---

## Naming

- **Types** (`struct`, `class`, `enum`, `protocol`, `actor`): UpperCamelCase nouns.
  Protocols describing capability use `-able`, `-ible`, or `-ing` suffix.
  Protocols describing what something is use nouns (`UserRepository`, `Shape`).
- **Functions and methods**: lowerCamelCase verbs or verb phrases.
  Mutating methods read as imperative (`sort()`, `append(_:)`).
  Non-mutating variants use past participle or `-ing` (`sorted()`, `appending(_:)`).
- **Properties and variables**: lowerCamelCase nouns. Boolean properties read as
  assertions (`isEmpty`, `canExecute`, `hasChildren`).
- **Argument labels**: form grammatical English phrases at the call site.
  Omit the first label when the argument is the direct object of the method name.
  Use prepositions (`to`, `with`, `from`, `in`) to clarify the role of subsequent arguments.
- **Acronyms**: uppercase when they start a type name (`URLSession`), lowercase in
  non-leading positions (`baseURL`, `htmlParser`).
- **Factory methods**: use `make` prefix (`makeIterator()`).
- **Type aliases**: prefer descriptive names over abbreviations.
- **Do not** use obscure terminology or abbreviations unless they are industry-standard
  and unambiguous.

### Generics

Generic type parameters should be descriptive when the role matters. Use single-letter
names only when the relationship is obvious and conventional.

**Preferred:**
```swift
struct Stack<Element> { }
func write<Target: TextOutputStream>(to target: inout Target)
func swap<T>(_ a: inout T, _ b: inout T)
```

**Not Preferred:**
```swift
struct Stack<T> { }
func write<target: TextOutputStream>(to target: inout target)
func swap<Thing>(_ a: inout Thing, _ b: inout Thing)
```

---

## API Design

- **Clarity at the point of use** over brevity at the point of definition.
- **Omit needless words** — every word in a name must carry information.
- **Document complexity**: if a method is O(n) where O(1) might be expected, document it.
- **Prefer methods over free functions** unless the function has no meaningful `self`.
  Reasonable free-function exceptions: `zip(a, b)`, `max(x, y, z)`.
- **Use default parameter values** over method overloads when behavior is the same.
- **Mark `@discardableResult`** only when ignoring the result is a common, valid use case.

---

## Code Organization

### Extensions

Use extensions to organize code into logical blocks of functionality.

- Extensions can live in the same file or separate files.
- For extensions in their own files, use: `<TypeBeingExtended>+<Feature>.swift`
  (e.g., `UIViewController+Keyboard.swift`, `URLSession+Decoding.swift`).
- For extensions in the same file, separate sections with `// MARK: -`.

### Protocol Conformance

Prefer separate extensions for protocol conformances.

**Preferred:**
```swift
final class MyViewController: UIViewController {
    // core type definition
}

// MARK: - UITableViewDataSource
extension MyViewController: UITableViewDataSource {
    // data source methods
}

// MARK: - UIScrollViewDelegate
extension MyViewController: UIScrollViewDelegate {
    // delegate methods
}
```

**Not Preferred:**
```swift
final class MyViewController: UIViewController, UITableViewDataSource, UIScrollViewDelegate {
    // everything mixed together
}
```

### Unused Code

Remove unused code, including:

- commented-out code
- unused properties
- empty delegate methods
- methods that only forward to the superclass without adding value

### Minimal Imports

Do not import `UIKit` when `Foundation` is sufficient.
Do not import `Combine` or `Observation` unless the file actually uses them.

---

## Spacing

### Braces

Same-line opening braces (`func foo() {`), closing brace on its own line.
Single-line early exits are acceptable: `guard isReady else { return }`

### Newlines

Use exactly one blank line between methods. Whitespace inside methods should separate
logical operations. If a method requires many visual sections, it is usually a signal
to refactor.

### Colons

No space on the left, one space on the right: `var counts: [String: Int]`

### Line Length

Wrap lines around 120 characters when practical. Avoid trailing whitespace.

---

## Comments

When comments are needed, explain **why**, not **what**. Comments must be kept up to
date or deleted.

**Preferred:**
```swift
// Use a monotonic clock here to avoid wall-clock drift during retry backoff.
```

**Not Preferred:**
```swift
// Increment retry delay.
retryDelay += 1
```

### Documentation Comments

Use `///` documentation comments for public APIs and any internal APIs that benefit
from explicit contracts.

```swift
/// Fetches the user profile from the backend.
///
/// - Parameter id: The stable backend identifier for the user.
/// - Returns: A hydrated user profile.
/// - Throws: `NetworkError` when the request fails or decoding is invalid.
func fetchUserProfile(id: User.ID) async throws -> UserProfile
```

---

## Types

Always use Swift native types when available.

### Constants

Use `let` unless mutation is required. Start with `let` and change to `var` only
when the compiler proves mutation is necessary.

Prefer type-scoped constants over global constants:

**Preferred:**
```swift
enum Math {
    static let e = 2.718281828459045235360287
    static let root2 = 1.4142135623730951
}
```

**Not Preferred:**
```swift
let e = 2.718281828459045235360287
let root2 = 1.4142135623730951
```

### Optionals

- Declare as optional with `?` when `nil` is a valid state.
- Avoid implicitly unwrapped optionals (`!`) except for `IBOutlet`s or test setup
  where initialization order is guaranteed.
- Use optional chaining for short flows: `textContainer?.textLabel?.setNeedsDisplay()`
- Use optional binding when the unwrapped value is used more than once.
- Do not encode optionality in the name.

**Preferred:**
```swift
var imageView: UIImageView?
if let imageView {
    imageView.tintColor = .red
}
```

**Not Preferred:**
```swift
var optionalImageView: UIImageView?
if let unwrappedImageView = optionalImageView {
    unwrappedImageView.tintColor = .red
}
```

### Lazy Initialization

Use lazy initialization for finer control over object lifetime or expensive setup:

```swift
lazy var locationManager: CLLocationManager = makeLocationManager()

private func makeLocationManager() -> CLLocationManager {
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.delegate = self
    manager.requestWhenInUseAuthorization()
    return manager
}
```

### Type Inference

Prefer inferred types when the type is obvious and the expression is simple.
For empty arrays and dictionaries, use explicit type annotation.

**Preferred:**
```swift
let title = "Profile"
var names: [String] = []
var lookup: [String: Int] = [:]
let maximumWidth: CGFloat = 106.5
```

**Not Preferred:**
```swift
let title: String = "Profile"
var names = [String]()
var lookup = [String: Int]()
```

### Syntactic Sugar

Prefer shorthand type syntax (`[String]` over `Array<String>`, `Int?` over `Optional<Int>`).

### Inferred Context

Use compiler-inferred context (`.red` over `UIColor.red`, `.zero` over `CGRect.zero`).

---

## Classes and Structures

### Which one to use?

Prefer `struct` by default. Structs have value semantics and reduce accidental
shared mutable state.

Use a `class` when:
- identity matters
- inheritance is required
- reference semantics are required
- interoperability with Objective-C or framework APIs requires it

Use `actor` when shared mutable state must be protected across concurrency domains.

### Use of `self`

Avoid `self` unless required for:
- disambiguation (properties vs. initializer parameters)
- making capture semantics explicit in closures
- compiler requirement

### Computed Properties

If a computed property is read-only, omit `get`.

**Preferred:**
```swift
var diameter: Double {
    radius * 2
}
```

**Not Preferred:**
```swift
var diameter: Double {
    get {
        radius * 2
    }
}
```

### Final

Mark classes `final` by default unless inheritance is a deliberate API decision.

---

## Functions

### Formatting

Keep short declarations on one line. For longer signatures, place each parameter
on its own line:

```swift
func reticulateSplines(
    spline: [Double],
    adjustmentFactor: Double,
    translateConstant: Int,
    comment: String
) -> Bool {
    true
}
```

Use the same rule for long call sites:

```swift
let john = Person(
    fullName: "John Doe",
    gender: .male,
    location: "San Francisco, CA",
    occupation: .doctor
)
```

### Method Organization

Break large methods into private helpers when it improves readability:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setupUpdatesButton()
    setupDismissGestureRecognizer()
    setupTableView()
}
```

---

## Closure Expressions

For method calls with closures as named arguments, prefer one parameter per line.

**Preferred:**
```swift
UIView.animate(withDuration: 1.0) {
    myView.alpha = 0
}

UIView.animate(
    withDuration: 1.0,
    animations: {
        myView.alpha = 0
    },
    completion: { [weak myView] finished in
        guard finished else { return }
        myView?.removeFromSuperview()
    }
)
```

Chained closures should remain readable:

```swift
let value = numbers
    .map { $0 * 2 }
    .filter { $0 > 50 }
    .map { $0 + 10 }
```

---

## Access Control

Use the narrowest access level possible: `private → fileprivate → internal → public → open`

- Default to `private`. Escalate to `internal` only when needed by other types
  in the same module. Use `public` only for module API surface.
- Use `package` access for cross-module visibility within a package.
- Use `open` only when subclassing or overriding from other modules is deliberate.
- Mark classes `final` unless designed for subclassing.
- Prefer `private(set)` over fully `private` when read access is needed externally.
- Avoid explicitly writing `internal` unless it aids clarity.
- Access control appears before mutation modifiers, unless an attribute must come first.

**Preferred:**
```swift
private static let cacheLimit = 100
@IBOutlet private var titleLabel: UILabel!
```

---

## Control Flow

Prefer `for-in` over index-driven loops. Use `enumerated()` when the index is needed.

---

## Guard Statements

Keep the happy path left-aligned. Prefer compound optional binding to reduce nesting.

**Preferred:**
```swift
func computeFFT(context: Context?, inputData: InputData?) throws -> Frequencies {
    guard let context else {
        throw FFTError.noContext
    }
    guard let inputData else {
        throw FFTError.noInputData
    }
    return try makeFrequencies(context: context, inputData: inputData)
}
```

**Not Preferred:**
```swift
func computeFFT(context: Context?, inputData: InputData?) throws -> Frequencies {
    if let context {
        if let inputData {
            return try makeFrequencies(context: context, inputData: inputData)
        } else {
            throw FFTError.noInputData
        }
    } else {
        throw FFTError.noContext
    }
}
```

Guard statements must exit clearly: `return`, `throw`, `break`, `continue`,
`fatalError()`, `preconditionFailure()`. Use `defer` for cleanup.

---

## Switch Statements

Avoid `default` when switching over enums. Exhaustive switches let the compiler
catch newly added cases.

**Preferred:**
```swift
switch someDirection {
case .west:
    print("Go west")
case .north, .south, .east:
    print("Go somewhere else")
}
```

---

## Concurrency Style

- Annotate types with `Sendable` when they cross isolation boundaries.
  Use `@unchecked Sendable` only with a documented justification.
- Prefer `async`/`await` over callback-based APIs.
- Prefer `async let` and `TaskGroup` over `Task {}` for structured work.
- Avoid `Task.detached` unless its semantics are explicitly required.
- Use `@MainActor` on types/methods that touch UI, not on entire modules.
- Isolate mutation behind actors — do not use `DispatchQueue` for new code.
- Use `nonisolated` only when the API is truly safe from any context and semantics are clear.
- When bridging legacy callback APIs, use continuations and resume exactly once.

---

## SwiftUI Specifics

- Views should be small and focused — extract subviews when a body exceeds ~30 lines.
- Use `@State` for view-local state, `@Binding` for parent-owned state.
- Prefer `@Observable` (Observation framework) over `ObservableObject` for new code.
- Use environment values and preferences over deep prop drilling.
- Avoid `AnyView` — use `@ViewBuilder`, `some View`, or conditional modifiers.
- Animations should respect `accessibilityReduceMotion`.
- Choose architecture based on app constraints, not fashion. A stable `ObservableObject`
  design does not need rewriting without clear benefit.

### Modern Observation

```swift
import Observation

@Observable
final class CounterModel {
    var count = 0

    func increment() {
        count += 1
    }
}
```

---

## Error Handling Style

- Model errors precisely with domain-specific `Error` types.
- Throw specific error types conforming to `Error` (and `LocalizedError` for user-facing).
- Prefer `throws` over `Result` for internal APIs.
- Never swallow errors with empty `catch {}` — at minimum, log them.
- Do not use `try?` unless loss of error detail is intentional and harmless.
- Use `guard` for early exit on precondition failures.
- Preserve underlying errors when they carry diagnostic value.

### Preconditions and Fatal Errors

Use `preconditionFailure()` and `fatalError()` sparingly — only when the application
reaches a state that is impossible under the contract of the code. For recoverable
production failures, prefer logging, diagnostics, and graceful fallback.

---

## Memory Management

### Closure Capture Rules

Use `[weak self]` when the closure may outlive `self`:

```swift
resource.request().onComplete { [weak self] response in
    guard let self else { return }
    let model = updateModel(response)
    updateUI(model)
}
```

Use `[unowned self]` only when lifetime ordering is guaranteed and obvious.

### IBOutlets

IBOutlets should generally be `private` and may remain implicitly unwrapped when
Interface Builder lifecycle guarantees initialization before use:

```swift
@IBOutlet private var notificationsView: UIView!
```

---

## General Syntax

### Parentheses

Omit parentheses around conditionals (`if name == "Hello"` not `if (name == "Hello")`).
Optional parentheses are acceptable when they materially improve readability of complex expressions.

---

## Formatting Expectations

- Code should pass `swift format` with default configuration.
- One type per file (with small private helpers allowed in the same file).
- Imports sorted alphabetically, system frameworks first.
- Trailing commas in multi-line collection literals and parameter lists.
- Braces on the same line as the declaration (`func foo() {`).
