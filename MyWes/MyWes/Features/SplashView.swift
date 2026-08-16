//
//  SplashView.swift
//  MyWes
//

import SwiftUI

struct SplashView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            Theme.splashDark
                .ignoresSafeArea()

            VStack(spacing: 14) {
                AppLogoMark(size: 76, cornerRadius: Theme.logoRadiusLarge)

                Text("MyWes")
                    .font(Typography.displayLarge)
                    .tracking(-0.4)
                    .foregroundStyle(.white)

                Text("Your Wesleyan, all in one place.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.splashTagline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                Text("Tap to continue")
                    .font(Typography.label)
                    .foregroundStyle(Theme.splashMuted)
                    .padding(.top, 36)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            session.continueFromSplash()
        }
    }
}

#Preview {
    SplashView()
        .environment(AppSession())
}
