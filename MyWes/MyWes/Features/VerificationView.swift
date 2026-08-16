//
//  VerificationView.swift
//  MyWes
//

import SwiftUI

struct VerificationView: View {
    @Environment(AppSession.self) private var session
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var didResend = false
    @State private var canResend = true
    @FocusState private var isCodeFocused: Bool

    private var canVerify: Bool {
        code.count == 6
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: session.returnToEmailEntry) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Change email")
                            .font(Typography.bodyEmphasized)
                    }
                    .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change email")
                .padding(.bottom, 28)

                Text("Check your email")
                    .font(Typography.headlineLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 6)

                Text("We sent a 6-digit verification code to:")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 6)

                Text(session.pendingEmail)
                    .font(Typography.bodyEmphasized)
                    .foregroundStyle(Theme.ink)
                    .textSelection(.enabled)
                    .padding(.bottom, 32)

                FormField(
                    label: "Verification Code",
                    placeholder: "000000",
                    text: $code,
                    keyboardType: .numberPad,
                    textContentType: .oneTimeCode,
                    usesMonospacedDigits: true,
                    focus: $isCodeFocused
                )
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                    if digits != newValue {
                        code = digits
                    }
                    if errorMessage != nil {
                        errorMessage = nil
                    }
                }
                .padding(.bottom, errorMessage == nil ? 24 : 10)

                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.cardinal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isStaticText)
                        .padding(.bottom, 14)
                }

                PrimaryButton(title: "Verify", isEnabled: canVerify) {
                    attemptVerify()
                }

                Button {
                    resendCode()
                } label: {
                    Text("Resend code")
                        .font(Typography.label)
                        .foregroundStyle(canResend ? Theme.cardinal : Theme.secondaryText)
                }
                .buttonStyle(.plain)
                .disabled(!canResend)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .accessibilityHint("Sends another 6-digit verification code")

                if didResend {
                    Text("Code resent.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            isCodeFocused = true
        }
    }

    private func attemptVerify() {
        guard canVerify else { return }
        if session.verifyCode(code) {
            errorMessage = nil
        } else {
            errorMessage = "Incorrect code. Try again."
        }
    }

    private func resendCode() {
        guard canResend else { return }
        canResend = false
        didResend = true
        errorMessage = nil
        Task {
            try? await Task.sleep(for: .seconds(2))
            canResend = true
        }
    }
}

#Preview {
    let session = AppSession()
    session.pendingEmail = "alex@wesleyan.edu"
    return VerificationView()
        .environment(session)
}
