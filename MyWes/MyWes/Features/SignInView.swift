//
//  SignInView.swift
//  MyWes
//

import SwiftUI

struct SignInView: View {
    @Environment(AppSession.self) private var session

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

                Text("Sign in with your Wesleyan Google account to continue.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 32)

                PrimaryButton(
                    title: "Continue with Google",
                    isEnabled: !session.isSigningIn,
                    isLoading: session.isSigningIn
                ) {
                    Task { await session.signInWithGoogle() }
                }

                Text("Use your @wesleyan.edu Google account.")
                    .font(Typography.label)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                if let authError = session.authError, !authError.isEmpty {
                    Text(authError)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.cardinal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isStaticText)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    Button {
                        Task { await session.tryAnotherGoogleAccount() }
                    } label: {
                        Text("Try another Google account")
                            .font(Typography.label)
                            .foregroundStyle(Theme.cardinal)
                    }
                    .buttonStyle(.plain)
                    .disabled(session.isSigningIn)
                    .frame(maxWidth: .infinity)
                    .accessibilityHint("Signs in with a different Google account")
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    SignInView()
        .environment(AppSession())
}
