//
//  RootView.swift
//  MyWes
//

import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .splash:
                SplashView()
            case .signIn:
                SignInView()
            case .verify:
                VerificationView()
            case .onboarding:
                OnboardingView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.phase)
    }
}

#Preview {
    RootView()
        .environment(AppSession())
}
