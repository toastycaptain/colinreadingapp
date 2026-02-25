import SwiftUI

struct ParentGateView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage: String?

    private var isSetupMode: Bool {
        !appViewModel.hasParentPIN()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(isSetupMode ? "Create Parent PIN" : "Enter Parent PIN")
                    .font(.title3.weight(.bold))

                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if isSetupMode {
                    SecureField("Confirm PIN", text: $confirmPin)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button(isSetupMode ? "Save PIN" : "Unlock Parent Mode") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pin.count < 4 || (isSetupMode && confirmPin.count < 4))

                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        appViewModel.showParentGate = false
                        dismiss()
                    }
                }
            }
        }
    }

    private func submit() {
        let normalizedPIN = pin.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedPIN.count >= 4 else {
            errorMessage = "PIN must be at least 4 digits."
            return
        }

        if isSetupMode {
            guard normalizedPIN == confirmPin.trimmingCharacters(in: .whitespacesAndNewlines) else {
                errorMessage = "PIN entries do not match."
                return
            }
            appViewModel.setParentPIN(normalizedPIN)
            dismiss()
            return
        }

        let success = appViewModel.verifyParentPIN(normalizedPIN)
        if success {
            dismiss()
        } else {
            errorMessage = "Incorrect PIN."
        }
    }
}
