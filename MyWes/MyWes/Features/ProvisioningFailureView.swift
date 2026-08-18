//
//  ProvisioningFailureView.swift
//  MyWes
//

import SwiftUI

struct ProvisioningFailureView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AppLogoMark(size: 56, cornerRadius: Theme.logoRadiusMedium)
                .padding(.bottom, 20)

            Text("Profile unavailable")
                .font(Typography.headlineLarge)
                .tracking(-0.4)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)

            Text(session.authError ?? "Your account exists, but your MyWes profile could not be loaded.")
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .padding(.bottom, 28)

            PrimaryButton(title: "Try again") {
                Task { await session.retryProfileLoad() }
            }

            Button {
                Task { await session.signOutFromFailure() }
            } label: {
                Text("Use a different email")
                    .font(Typography.label)
                    .foregroundStyle(Theme.cardinal)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 80)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    ProvisioningFailureView()
        .environment(AppSession())
}
