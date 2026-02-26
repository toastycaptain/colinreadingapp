import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterMode = false
    @State private var consentAccepted = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Storytime")
                .font(.largeTitle.weight(.bold))

            Text(isRegisterMode ? "Create parent account" : "Parent login")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if isRegisterMode {
                Toggle(isOn: $consentAccepted) {
                    Text("I am the parent/guardian and consent to the privacy policy")
                        .font(.subheadline)
                }

                HStack(spacing: 16) {
                    Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
                    Link("Terms", destination: AppConfig.termsURL)
                }
                .font(.caption)
            }

            Button {
                Task {
                    if isRegisterMode {
                        _ = await appViewModel.register(
                            email: email,
                            password: password,
                            consentAccepted: consentAccepted,
                            policyVersion: AppConfig.privacyPolicyVersion
                        )
                    } else {
                        _ = await appViewModel.login(email: email, password: password)
                    }
                }
            } label: {
                if appViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(isRegisterMode ? "Register" : "Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitDisabled)

            Button(isRegisterMode ? "Have an account? Login" : "Need an account? Register") {
                isRegisterMode.toggle()
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(24)
    }

    private var isSubmitDisabled: Bool {
        if appViewModel.isLoading || email.isEmpty || password.isEmpty {
            return true
        }

        if isRegisterMode {
            return !consentAccepted
        }

        return false
    }
}
