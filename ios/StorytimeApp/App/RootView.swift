import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            Group {
                if appViewModel.jwt == nil {
                    ChildLibraryView()
                } else if appViewModel.activeChild == nil {
                    ChildSelectionView()
                } else {
                    switch appViewModel.mode {
                    case .child:
                        ChildLibraryView()
                    case .parent:
                        ParentHomeView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $appViewModel.showParentGate) {
            ParentGateView()
                .environmentObject(appViewModel)
        }
        .overlay(alignment: .top) {
            if let error = appViewModel.errorMessage {
                ErrorBannerView(message: error)
                    .padding(.top, 8)
            }
        }
    }
}
