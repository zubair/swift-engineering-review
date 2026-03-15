// Test fixture: Shared mutable state without actor isolation
// Expected findings: actor isolation (blocker), task lifetime (major)

import Foundation

class ImageCache: @unchecked Sendable {
    private var store: [String: Data] = [:]
    private let queue = DispatchQueue(label: "cache")

    func set(_ key: String, _ value: Data) {
        queue.sync { store[key] = value }
    }

    func get(_ key: String) -> Data? {
        queue.sync { store[key] }
    }
}

class ImageLoader {
    let cache = ImageCache()

    func loadImages(_ urls: [URL]) {
        for url in urls {
            Task {
                let (data, _) = try await URLSession.shared.data(from: url)
                cache.set(url.absoluteString, data)
            }
        }
    }

    func prefetch(_ url: URL) {
        Task.detached {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.cache.set(url.absoluteString, data)
        }
    }
}
