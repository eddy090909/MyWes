//
//  SignInView.swift
//  MyWes
//

import SwiftUI

struct SignInView: View {
    @Environment(AppSession.self) private var session
    @State private var email = ""
    @FocusState private var isEmailFocused: Bool

    private var canContinue: Bool {
        AppSession.isValidWesleyanEmail(email) && !session.isSendingLink
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AppLogoMark(size: 56, cornerRadius: Theme.logoRadiusMedium)
                    .padding(.bottom, 20)

                Text("Welcome to MyWes")
                    .font(Typography.headlineLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 6)

                Text("Your Wesleyan, all in one place.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 10)

                Text("Enter your Wesleyan email to continue.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 32)

                FormField(
                    label: "Wesleyan Email",
                    placeholder: "you@wesleyan.edu",
                    text: $email,
                    submitLabel: .continue,
                    onSubmit: sendLinkIfValid,
                    focus: $isEmailFocused
                )
                .disabled(session.isSendingLink)
                .padding(.bottom, session.authError == nil ? 24 : 10)

                if let authError = session.authError {
                    Text(authError)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.cardinal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isStaticText)
                        .padding(.bottom, 14)
                }

                PrimaryButton(
                    title: "Send sign-in link",
                    isEnabled: canContinue,
                    isLoading: session.isSendingLink
                ) {
                    sendLinkIfValid()
                }

                Text("Only Wesleyan email addresses are eligible.")
                    .font(Typography.label)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 28)
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if email.isEmpty {
                email = session.pendingEmail
            }
        }
    }

    private func sendLinkIfValid() {
        guard canContinue else { return }
        Task { await session.sendSignInLink(to: email) }
    }
}

#Preview {
    SignInView()
        .environment(AppSession())
}
