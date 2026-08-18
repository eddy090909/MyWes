//
//  CheckEmailView.swift
//  MyWes
//

import SwiftUI

struct CheckEmailView: View {
    @Environment(AppSession.self) private var session

    private var resendTitle: String {
        if session.resendCooldownRemaining > 0 {
            return "Resend link in \(session.resendCooldownRemaining)s"
        }
        return "Resend link"
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

                Text("We sent a secure sign-in link to:")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 6)

                Text(session.pendingEmail)
                    .font(Typography.bodyEmphasized)
                    .foregroundStyle(Theme.ink)
                    .textSelection(.enabled)
                    .padding(.bottom, 16)

                Text("Open the email and tap the link to continue.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, session.authError == nil ? 32 : 12)

                if session.isHandlingCallback {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Signing you in…")
                            .font(Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24)
                }

                if let authError = session.authError {
                    Text(authError)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.cardinal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isStaticText)
                        .padding(.bottom, 20)
                }

                Button {
                    Task { await session.resendSignInLink() }
                } label: {
                    Text(resendTitle)
                        .font(Typography.label)
                        .foregroundStyle(session.canResendLink ? Theme.cardinal : Theme.secondaryText)
                }
                .buttonStyle(.plain)
                .disabled(!session.canResendLink)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Sends another sign-in link to your email")
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    let session = AppSession()
    session.pendingEmail = "alex@wesleyan.edu"
    session.phase = .checkEmail
    return CheckEmailView()
        .environment(session)
}
