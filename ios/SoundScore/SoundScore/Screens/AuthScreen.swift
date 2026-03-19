import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email = "dev@soundscore.test"
    @State private var password = "devpass1234"
    @State private var handle = "madhav"
    @State private var isSignup = true
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(ThemeManager.shared.primary)
                    Text("SoundScore")
                        .font(SSTypography.headlineMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                    Text("Your taste, your journal.")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.textSecondary)
                }

                GlassCard(
                    cornerRadius: 24,
                    borderColor: SSColors.glassBorder,
                    frosted: true
                ) {
                    VStack(spacing: 16) {
                        if isSignup {
                            AuthField(
                                icon: "at",
                                placeholder: "Handle",
                                text: $handle
                            )
                        }

                        AuthField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        AuthField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(SSTypography.bodySmall)
                                .foregroundColor(SSColors.accentCoral)
                                .multilineTextAlignment(.center)
                        }

                        SSButton(
                            text: isLoading
                                ? "..."
                                : (isSignup ? "Create Account" : "Log In")
                        ) {
                            submit()
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.6 : 1)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignup.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            Text(
                                isSignup
                                    ? "Already have an account? Log in"
                                    : "Don't have an account? Sign up"
                            )
                            .font(SSTypography.bodySmall)
                            .foregroundColor(ThemeManager.shared.primary)
                        }
                    }
                }
                .padding(.horizontal, 4)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private func submit() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        if isSignup, handle.isEmpty {
            errorMessage = "Handle is required for signup."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignup {
                    do {
                        try await authManager.signup(
                            email: email, password: password, handle: handle
                        )
                    } catch ApiError.serverError(let code, _) where code == 409 {
                        // Account already exists — fall back to login
                        try await authManager.login(
                            email: email, password: password
                        )
                    }
                } else {
                    try await authManager.login(
                        email: email, password: password
                    )
                }
                await MainActor.run { isLoading = false }
                Task { await SoundScoreRepository.shared.refresh() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Auth Field Component

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(SSColors.textTertiary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(SSColors.chromeLight)
                    .font(SSTypography.bodyMedium)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(SSColors.chromeLight)
                    .font(SSTypography.bodyMedium)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SSColors.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SSColors.glassBorder, lineWidth: 0.5)
        )
    }
}
