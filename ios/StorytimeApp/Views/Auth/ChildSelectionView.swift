import SwiftUI

struct ChildSelectionView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var newChildName = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Child")
                .font(.title2.weight(.bold))

            if appViewModel.children.isEmpty {
                Text("No child profiles yet. Create one below.")
                    .foregroundStyle(.secondary)
            } else {
                List(appViewModel.children, id: \.id) { child in
                    Button {
                        Task { await appViewModel.selectChild(child) }
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(Text(String(child.name.prefix(1))).font(.headline))
                            Text(child.name)
                                .font(.body.weight(.medium))
                        }
                    }
                }
                .listStyle(.plain)
            }

            VStack(spacing: 8) {
                TextField("New child name", text: $newChildName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Create Child") {
                    Task {
                        await appViewModel.createChild(name: newChildName)
                        newChildName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newChildName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)

            Button("Logout") {
                appViewModel.logout()
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
        .padding(.top)
    }
}
