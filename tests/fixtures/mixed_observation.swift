// Test fixture: Mixed ObservableObject + @Observable causing double-invalidation
// Expected findings: observable migration (major), state ownership (minor)

import SwiftUI

// Old pattern — still using ObservableObject
class UserSettings: ObservableObject {
    @Published var theme: String = "light"
    @Published var fontSize: Int = 14
}

// New pattern — already migrated
@Observable class AppState {
    var currentUser: String = ""
    var isLoggedIn: Bool = false
}

struct RootView: View {
    @State private var appState = AppState()
    @StateObject private var settings = UserSettings() // mixed observation

    var body: some View {
        VStack {
            Text("User: \(appState.currentUser)")
            SettingsView(settings: settings)
        }
        .environment(appState)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: UserSettings

    var body: some View {
        VStack {
            Text("Theme: \(settings.theme)")
            Text("Font size: \(settings.fontSize)")
            // Both observation systems fire when settings change,
            // causing redundant view invalidation up the hierarchy
        }
    }
}
