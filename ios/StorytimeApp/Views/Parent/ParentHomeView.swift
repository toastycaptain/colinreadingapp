import SwiftUI

struct ParentHomeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        List {
            Section("Active Child") {
                if let child = appViewModel.activeChild {
                    Text(child.name)
                        .font(.headline)
                } else {
                    Text("No active child selected")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Actions") {
                NavigationLink("Search Catalog") {
                    ParentCatalogSearchView()
                }

                NavigationLink("Manage Child Library") {
                    ParentLibraryManagementView()
                }

                NavigationLink("Manage Children") {
                    ParentChildrenManagementView()
                }
            }

            Section {
                Button("Back to Child Mode") {
                    appViewModel.exitParentMode()
                }

                Button("Logout", role: .destructive) {
                    appViewModel.logout()
                }
            }
        }
        .navigationTitle("Parent Mode")
        .task {
            await appViewModel.refreshLibrary()
        }
    }
}
