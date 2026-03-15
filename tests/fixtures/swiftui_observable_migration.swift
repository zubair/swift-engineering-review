// Test fixture: SwiftUI view using legacy ObservableObject pattern
// Expected findings: observable migration (nit), task lifetime (major)

import SwiftUI

class ProfileModel: ObservableObject {
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        // simulate network
        try? await Task.sleep(for: .seconds(1))
        name = "Alice"
        bio = "Swift developer"
        isLoading = false
    }
}

struct ProfileView: View {
    @StateObject private var model = ProfileModel()

    var body: some View {
        VStack {
            if model.isLoading {
                ProgressView()
            } else {
                Text(model.name)
                Text(model.bio)
            }
        }
        .onAppear {
            Task {
                await model.load()
            }
        }
    }
}
