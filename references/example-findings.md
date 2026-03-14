# Example Review Findings

These examples demonstrate the expected output format for review findings.

---

### [critical] Data race on shared mutable dictionary

**File:** `Services/CacheManager.swift:47`
**Issue:** `cache` is a `var [String: Data]` dictionary accessed from multiple
`Task {}` blocks without synchronization. This causes undefined behavior under
Swift 6 strict concurrency.
**Fix:** Convert `CacheManager` to an `actor`, or protect `cache` with a `Mutex`.

```swift
// Before
class CacheManager {
    var cache: [String: Data] = [:]

    func store(_ data: Data, for key: String) {
        cache[key] = data  // data race
    }
}

// After
actor CacheManager {
    private var cache: [String: Data] = [:]

    func store(_ data: Data, for key: String) {
        cache[key] = data  // actor-isolated, safe
    }
}
```

---

### [major] Retain cycle in closure capture

**File:** `ViewModels/ProfileViewModel.swift:82`
**Issue:** `self` is captured strongly in an escaping closure passed to
`NetworkClient.fetch`. If the network request outlives the view model,
this creates a retain cycle.
**Fix:** Capture `[weak self]` and guard.

```swift
// Before
networkClient.fetch(endpoint) { result in
    self.handleResult(result)
}

// After
networkClient.fetch(endpoint) { [weak self] result in
    guard let self else { return }
    self.handleResult(result)
}
```

---

### [major] Force-unwrap in production code path

**File:** `Utilities/DateParser.swift:23`
**Issue:** `DateFormatter().date(from: input)!` will crash if the input
string does not match the expected format. User input is not validated
before reaching this point.
**Fix:** Use optional binding and throw a descriptive error.

```swift
// Before
let date = formatter.date(from: input)!

// After
guard let date = formatter.date(from: input) else {
    throw DateParsingError.invalidFormat(input)
}
```

---

### [minor] Over-broad MainActor annotation

**File:** `Services/AnalyticsService.swift:1`
**Issue:** The entire `AnalyticsService` class is annotated `@MainActor`,
but it only performs network calls and data formatting — no UI work.
This forces all callers onto the main actor unnecessarily.
**Fix:** Remove `@MainActor` from the class. If specific methods need
main-actor isolation, annotate those individually.

---

### [minor] Bare catch block swallows error

**File:** `Networking/APIClient.swift:95`
**Issue:** `catch {}` silently discards the error. Callers have no way to
know the request failed, and debugging production issues becomes difficult.
**Fix:** At minimum, log the error. Prefer rethrowing or returning a
`Result.failure`.

```swift
// Before
do {
    let data = try await session.data(for: request)
} catch {}

// After
do {
    let data = try await session.data(for: request)
} catch {
    Logger.network.error("Request failed: \(error)")
    throw error
}
```

---

### [nit] Import order

**File:** `Views/SettingsView.swift:1`
**Issue:** `import SwiftUI` appears after `import MyAppKit`. System
frameworks should be imported first.
**Fix:** Sort imports with system frameworks first, then project modules.

```swift
// Before
import MyAppKit
import SwiftUI

// After
import SwiftUI

import MyAppKit
```
