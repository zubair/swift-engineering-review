# Swift Remediation Playbooks

Use this file when a finding needs a concrete fix path. Reference the playbook label in
the review output so the fix recommendation is reusable and easy to scan.

---

# Concurrency

## actor isolation

**Problem** — Shared mutable state is accessed from multiple tasks or threads without an isolation boundary.

**Detection Signals**
- `@unchecked Sendable` on a class with mutable stored properties
- shared `var` mutated inside `Task {}` or `Task.detached {}` without actor protection
- `DispatchQueue` used solely to protect property access (synchronization-only queue)
- compiler warning about non-sendable type crossing isolation boundary

**Fix**
- Prefer converting the owner to an `actor` when the state and behavior belong together.
- Otherwise protect the narrow mutation surface with `Mutex` or another explicit lock.
- Remove `@unchecked Sendable` unless the synchronization story is provably correct.
- After the change, verify all callers cross the isolation boundary intentionally.

**Example**
```swift
// Before
class Cache: @unchecked Sendable {
    private var store: [String: Data] = [:]
    private let queue = DispatchQueue(label: "cache")

    func set(_ key: String, _ value: Data) {
        queue.sync { store[key] = value }
    }
    func get(_ key: String) -> Data? {
        queue.sync { store[key] }
    }
}

// After
actor Cache {
    private var store: [String: Data] = [:]

    func set(_ key: String, _ value: Data) {
        store[key] = value
    }
    func get(_ key: String) -> Data? {
        store[key]
    }
}
```

**Risk Notes** — Converting to an `actor` makes every call-site `await`. Audit callers for unintentional suspension points and ensure no synchronous code paths depend on immediate access.

## mutex usage

**Problem** — Actor overhead is unnecessary for a small synchronous critical section, but raw `DispatchQueue.sync` or `os_unfair_lock` lacks compiler-checked safety.

**Detection Signals**
- `DispatchQueue.sync { ... }` used only to guard a single property read/write
- `os_unfair_lock` or `NSLock` wrapping a trivial critical section
- property needs thread-safe access but has no async methods or suspension points

**Fix**
- Replace the lock with `Mutex<ProtectedState>` and access via `withLock`.
- Never hold a `Mutex` across an `await` — if the critical section suspends, use an `actor` instead.
- Keep the locked region as small as possible.

**Example**
```swift
// Before
class Counter: @unchecked Sendable {
    private var _count = 0
    private let queue = DispatchQueue(label: "counter")

    var count: Int {
        queue.sync { _count }
    }
    func increment() {
        queue.sync { _count += 1 }
    }
}

// After
import Synchronization

struct Counter: Sendable {
    private let _count = Mutex(0)

    var count: Int {
        _count.withLock { $0 }
    }
    func increment() {
        _count.withLock { $0 += 1 }
    }
}
```

**Risk Notes** — `Mutex` requires the `Synchronization` module, available from Swift 6 toolchain onward. Platform availability may vary as the module evolves — verify against the project's deployment target before adopting. Holding the lock across `await` deadlocks.

## sending parameters

**Problem** — Values crossing task or isolation boundaries without `sending` allow the compiler to miss shared-mutable-state transfers.

**Detection Signals**
- function parameter passed into `Task {}` or across actor boundary without `sending`
- compiler error about sending non-sendable value
- closure capturing a non-`Sendable` value and passed to another isolation domain

**Fix**
- Add `sending` to parameters that transfer ownership across isolation boundaries.
- Ensure the caller does not retain a reference to the sent value after the call.
- If the type cannot be sent, make it `Sendable` or copy it before transfer.

**Example**
```swift
// Before
func process(_ item: WorkItem) {
    Task {
        await handler.handle(item) // compiler error: sending non-sendable
    }
}

// After
func process(_ item: sending WorkItem) {
    Task {
        await handler.handle(item) // OK: ownership transferred
    }
}
```

**Risk Notes** — `sending` enforces move semantics at the call site. The caller cannot use the value after passing it. Audit call sites to ensure no post-call access exists.

## @isolated(any)

**Problem** — A closure parameter is forced to a specific actor (e.g. `@MainActor`) when it should inherit the caller's isolation context.

**Detection Signals**
- `@MainActor () -> Void` or `@MainActor @Sendable () -> Void` on a closure parameter that runs in multiple contexts
- unnecessary actor hop when the closure runs on the same actor as the caller
- API that forces callers onto an actor they don't need

**Fix**
- Replace the explicit actor annotation with `@isolated(any)` to let the closure inherit caller isolation.
- Use `@isolated(any)` on stored closure properties only when the isolation context is truly dynamic.
- Keep `@MainActor` when the closure must always run on the main actor (e.g. UI updates).

**Example**
```swift
// Before
func onComplete(_ handler: @MainActor @Sendable () -> Void) {
    Task { @MainActor in
        handler() // always hops to main actor
    }
}

// After
func onComplete(_ handler: @isolated(any) @Sendable () -> Void) {
    Task {
        await handler() // runs on caller's isolation
    }
}
```

**Risk Notes** — `@isolated(any)` closures require `await` at the call site even when the isolation matches. This is a Swift 6 feature; verify toolchain support. Misuse can obscure which actor a closure actually runs on — use only when dynamic isolation is the intent.

## nonisolated(unsafe)

**Problem** — An escape hatch is needed for global or static state that the compiler cannot verify as safe, but incorrect use silently reintroduces data races.

**Detection Signals**
- `nonisolated(unsafe)` without an adjacent safety-invariant comment
- global mutable `var` or `static var` marked `nonisolated(unsafe)` — highest risk
- global `let` or `static let` that is genuinely immutable after initialization but the compiler flags it
- logger, configuration, or feature-flag singleton accessed from multiple isolation domains

**Fix**
- Add an inline comment documenting the safety invariant (why this is race-free).
- Prefer `Mutex`, `actor`, or `Sendable` conformance if the invariant is not trivially obvious.
- Audit the invariant whenever the surrounding code changes.

**Example**
```swift
// Before
nonisolated(unsafe) let logger = Logger(label: "app")
// No explanation — reviewer cannot verify safety

// After
// Safety: Logger is initialized once before any concurrent access
// and is internally thread-safe (os_log-backed).
nonisolated(unsafe) let logger = Logger(label: "app")
```

**Risk Notes** — `nonisolated(unsafe)` completely disables compiler isolation checking for the declaration. If the safety invariant becomes invalid (e.g. the value becomes mutable), data races return silently with no compiler warning. Treat every use as a code-review checkpoint.

## task lifetime

**Problem** — Work is launched with `Task {}` or `Task.detached {}` without a clear owner, cancellation path, or lifecycle tie.

**Detection Signals**
- `Task {}` inside a SwiftUI `body` or `init` without stored handle
- `Task {}` with no `.cancel()` call anywhere in the type
- fire-and-forget async work that writes back to `@State` or a model

**Fix**
- Prefer structured concurrency, `.task(id:)`, or model-owned async methods.
- Propagate cancellation and handle it explicitly.
- Prevent stale writes by checking task identity or current input before mutating state.

**Example**
```swift
// Before — fire-and-forget in view
struct ProfileView: View {
    @State private var profile: Profile?

    var body: some View {
        Text(profile?.name ?? "Loading")
            .onAppear {
                Task {
                    profile = try? await api.fetchProfile()
                }
            }
    }
}

// After — lifecycle-tied task
struct ProfileView: View {
    @State private var profile: Profile?

    var body: some View {
        Text(profile?.name ?? "Loading")
            .task {
                profile = try? await api.fetchProfile()
            }
    }
}
```

**Risk Notes** — `.task` cancels automatically when the view disappears or its `id` changes. If the async work has side effects beyond updating local state (e.g. writing to a database), ensure those side effects are idempotent or guarded against cancellation.

---

# SwiftUI & State

## state ownership

**Problem** — SwiftUI state lives in the wrong layer or too many layers own the same truth, causing unexpected invalidation or stale UI.

**Detection Signals**
- `@State` holding a reference type (class instance) — `@State` is designed for value types
- model object created inside `body` (re-created on every render)
- multiple views holding `@State` for the same piece of data

**Fix**
- Keep view-local toggles and ephemeral UI state in `@State`.
- Use `@Binding` for parent-owned mutation.
- Move shared mutable state into a long-lived observable model.
- Keep side effects out of `body`.

**Example**
```swift
// Before — reference type in @State
struct SettingsView: View {
    @State private var model = SettingsModel() // class — @State won't track mutations

    var body: some View {
        Toggle("Dark mode", isOn: $model.isDarkMode)
    }
}

// After — injected observable model
@Observable class SettingsModel {
    var isDarkMode = false
}

struct SettingsView: View {
    var model: SettingsModel // injected from parent

    var body: some View {
        Toggle("Dark mode", isOn: $model.isDarkMode)
    }
}
```

**Risk Notes** — Moving from `@State` to an injected model changes the ownership contract. Ensure the parent creates and holds the model for the expected lifetime. With `@Observable`, use `@Bindable` when you need bindings from a non-`@State` property.

## identity stability

**Problem** — `ForEach`, `List`, or selection state depends on unstable identity, causing duplicate work or stale UI on collection changes.

**Detection Signals**
- `ForEach(array.indices, id: \.self)` on a mutable collection
- `UUID()` generated inside `body` or in a computed property (new ID each render)
- `id: \.self` on a collection of non-`Identifiable` value types that can duplicate

**Fix**
- Use stable domain IDs instead of `UUID()` generated during rendering.
- Avoid index-based identity for mutable collections.
- Make equality and hashing match the true identity contract.

**Example**
```swift
// Before — index-based identity
ForEach(items.indices, id: \.self) { index in
    ItemRow(item: items[index])
        .task { await loadDetails(for: items[index]) }
}

// After — stable domain identity
ForEach(items) { item in
    ItemRow(item: item)
        .task(id: item.id) { await loadDetails(for: item) }
}
```

**Risk Notes** — Switching to stable IDs may change SwiftUI's animation and diffing behavior. Test list mutations (insert, delete, reorder) to verify transitions remain correct.

## observable migration

**Problem** — View hierarchy uses `ObservableObject`/`@Published` which causes over-invalidation compared to the `@Observable` macro.

**Detection Signals**
- `ObservableObject` conformance with `@Published` properties
- `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` property wrappers
- `objectWillChange.send()` manual calls
- mixed `ObservableObject` and `@Observable` in the same view hierarchy

**Fix**
1. Remove `ObservableObject` conformance and add `@Observable` macro.
2. Remove `@Published` from all stored properties — `@Observable` tracks them automatically.
3. Replace `@StateObject` → `@State`, `@ObservedObject` → direct property or `@Bindable` (prefer `@Bindable` when the view needs write access via `$binding`), `@EnvironmentObject` → `@Environment`.
4. Use `@Bindable` when you need a `Binding` from a non-`@State` observable property — this is the standard replacement for `@ObservedObject` when bindings are used.
5. Remove `objectWillChange.send()` calls — no longer needed.

**Example**
```swift
// Before — ObservableObject
class ProfileModel: ObservableObject {
    @Published var name: String = ""
    @Published var isLoading: Bool = false
}

struct ProfileView: View {
    @StateObject private var model = ProfileModel()

    var body: some View {
        TextField("Name", text: $model.name)
    }
}

// After — @Observable
@Observable class ProfileModel {
    var name: String = ""
    var isLoading: Bool = false
}

struct ProfileView: View {
    @State private var model = ProfileModel()

    var body: some View {
        @Bindable var model = model
        TextField("Name", text: $model.name)
    }
}
```

**Risk Notes** — `@Observable` requires iOS 17+ / macOS 14+. Mixing `ObservableObject` and `@Observable` in the same view hierarchy causes double-invalidation — migrate entire chains together. The compiler and Xcode will flag basic `ObservableObject` usage, so default severity is `nit`; escalate to `major` only when mixed observation causes double-invalidation bugs.

---

# General

## retain-cycle removal

**Problem** — Closures, delegates, or tasks capture owners too strongly, preventing deallocation.

**Detection Signals**
- closure capturing `self` without `[weak self]` where the closure outlives the owner
- strong `var delegate: SomeDelegate?` instead of `weak var delegate`
- `Timer` or `NotificationCenter` observer holding a strong reference to the owner

**Fix**
- Capture `[weak self]` when the closure outlives the owner.
- Use `unowned` only when the lifetime relationship is guaranteed by construction.
- Make delegates weak unless ownership is intentionally strong.

**Example**
```swift
// Before — strong capture causes retain cycle
class ViewController: UIViewController {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = {
            self.dismiss(animated: true) // strong capture
        }
    }
}

// After — weak capture breaks the cycle
class ViewController: UIViewController {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
```

**Risk Notes** — Switching to `[weak self]` means the closure body must handle `nil`. Ensure the early-return or guard pattern does not silently skip required cleanup work.

## typed errors

**Problem** — Failures are swallowed, stringly typed, or lose context, making production debugging and retry logic guesswork.

**Detection Signals**
- bare `catch {}` with no logging or rethrow
- `try?` discarding an error that carries diagnostic value
- `Error` or `NSError` passed around without domain-specific typing
- string-based error messages instead of typed enum cases

**Fix**
- Prefer domain-specific `Error` enums or well-defined error wrappers.
- Preserve the underlying error when it helps debugging or retry logic.
- Replace bare `catch {}` and casual `try?` with explicit handling.
- Keep retry and fallback behavior bounded and observable.

**Example**
```swift
// Before — bare catch swallows failure
func loadUser() async {
    do {
        let data = try await api.fetch("/user")
        user = try JSONDecoder().decode(User.self, from: data)
    } catch {}
}

// After — typed error with context
enum UserError: Error {
    case networkFailure(underlying: Error)
    case decodingFailure(underlying: Error)
}

func loadUser() async throws(UserError) {
    do {
        let data = try await api.fetch("/user")
        user = try JSONDecoder().decode(User.self, from: data)
    } catch let error as DecodingError {
        throw .decodingFailure(underlying: error)
    } catch {
        throw .networkFailure(underlying: error)
    }
}
```

**Risk Notes** — Introducing typed errors changes the function signature and forces all callers to handle the new type. Roll out incrementally, starting at the lowest layer.

## dependency injection

**Problem** — Singletons or global state make testing and evolution difficult by hiding coupling and preventing isolation.

**Detection Signals**
- `SomeService.shared` accessed directly in business logic
- `init()` creating its own dependencies internally
- test files with no way to substitute a mock or stub

**Fix**
- Inject dependencies from the composition root.
- Start concrete; extract a protocol when multiple implementations or testing pressure justify it.
- Keep module and access-control boundaries narrow.

**Example**
```swift
// Before — hidden singleton dependency
class OrderService {
    func placeOrder(_ order: Order) async throws {
        try await NetworkClient.shared.post("/orders", body: order)
        AnalyticsService.shared.track("order_placed")
    }
}

// After — injected dependencies
class OrderService {
    private let network: NetworkClient
    private let analytics: AnalyticsTracking

    init(network: NetworkClient, analytics: AnalyticsTracking) {
        self.network = network
        self.analytics = analytics
    }

    func placeOrder(_ order: Order) async throws {
        try await network.post("/orders", body: order)
        analytics.track("order_placed")
    }
}
```

**Risk Notes** — Extracting protocols too early adds indirection without proven benefit. Start by injecting concrete types; extract a protocol only when a second implementation (or test double) actually exists.

## test hardening

**Problem** — Risky behavior lacks regression coverage, leaving bugs to surface in production.

**Detection Signals**
- public type or method with no corresponding test
- test file covers only the happy path, no error or edge cases
- async code with no cancellation or concurrency test
- test depends on timing, network, or file system without isolation

**Fix**
- Add tests for the failure mode, not just the happy path.
- Add cancellation and concurrency tests for async code where feasible.
- Isolate time, randomness, storage, and network boundaries.
- Prefer small deterministic tests over broad flaky integration tests.

**Example**
```swift
// Before — happy-path only
@Test func testFetchUser() async throws {
    let user = try await service.fetchUser(id: "123")
    #expect(user.name == "Alice")
}

// After — includes error and cancellation paths
@Test func testFetchUser() async throws {
    let user = try await service.fetchUser(id: "123")
    #expect(user.name == "Alice")
}

@Test func testFetchUserNotFound() async {
    await #expect(throws: UserError.notFound) {
        try await service.fetchUser(id: "missing")
    }
}

@Test func testFetchUserCancellation() async {
    let task = Task { try await service.fetchUser(id: "123") }
    task.cancel()
    await #expect(throws: CancellationError.self) {
        try await task.value
    }
}
```

**Risk Notes** — Adding cancellation tests to code that doesn't check `Task.isCancelled` may expose missing cancellation handling. Fix the production code first, then add the test.
