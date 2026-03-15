// Test fixture: Retain cycles via strong delegate and closure capture
// Expected findings: retain-cycle removal (major), typed errors (minor)

import Foundation

protocol DataManagerDelegate {
    func didFinishLoading(_ data: [String])
    func didFail(_ error: Error)
}

class DataManager {
    var delegate: DataManagerDelegate? // strong reference — should be weak
    private var items: [String] = []

    func fetchItems() {
        URLSession.shared.dataTask(with: URL(string: "https://api.example.com/items")!) { data, _, error in
            if let data = data {
                let items = try? JSONDecoder().decode([String].self, from: data)
                self.items = items ?? []
                self.delegate?.didFinishLoading(self.items)
            } else {
                // bare catch equivalent — error swallowed when nil
            }
        }.resume()
    }
}

class ViewController: NSObject, DataManagerDelegate {
    let manager = DataManager()

    func setup() {
        manager.delegate = self

        manager.fetchItems()

        // Strong closure capture
        let completion: () -> Void = {
            print("Done: \(self.description)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: completion)
    }

    func didFinishLoading(_ data: [String]) {
        print("Loaded \(data.count) items")
    }

    func didFail(_ error: Error) {
        print("Failed")
    }
}
