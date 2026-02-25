import SwiftUI

struct ParentChildrenManagementView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var newChildName = ""

    var body: some View {
        VStack(spacing: 10) {
            List(appViewModel.children, id: \.id) { child in
                HStack {
                    Text(child.name)
                    Spacer()
                    if appViewModel.activeChild?.id == child.id {
                        Text("Active")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Button("Select") {
                            Task { await appViewModel.selectChild(child) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .listStyle(.plain)

            HStack {
                TextField("New child name", text: $newChildName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    Task {
                        await appViewModel.createChild(name: newChildName)
                        newChildName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newChildName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Children")
    }
}
