import SwiftUI

@main
struct StorytimeApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .task {
                    await appViewModel.bootstrap()
                }
        }
    }
}
