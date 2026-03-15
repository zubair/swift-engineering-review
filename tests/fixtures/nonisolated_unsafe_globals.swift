// Test fixture: nonisolated(unsafe) usage — mix of safe and unsafe patterns
// Expected findings: nonisolated(unsafe) (major for mutable var), actor isolation (minor)

import Foundation
import os

// Safe: immutable, thread-safe logger — but missing safety comment
nonisolated(unsafe) let logger = Logger(subsystem: "com.app", category: "main")

// Unsafe: mutable global state with no synchronization
nonisolated(unsafe) var featureFlags: [String: Bool] = [:]

// Unsafe: mutable static var
class AppConfig {
    nonisolated(unsafe) static var apiBaseURL: String = "https://api.example.com"
}

func updateFlags() async {
    // Race: multiple tasks writing to unprotected global
    await withTaskGroup(of: Void.self) { group in
        group.addTask {
            featureFlags["darkMode"] = true
        }
        group.addTask {
            featureFlags["newUI"] = true
        }
    }
}

func configureAPI(environment: String) {
    // Race: can be called from any isolation domain
    if environment == "staging" {
        AppConfig.apiBaseURL = "https://staging.example.com"
    }
}
