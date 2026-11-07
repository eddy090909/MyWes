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
            case .restoring:
                RestoringSessionView()
            case .splash:
                SplashView()
            case .signIn:
                SignInView()
            case .onboarding:
                OnboardingView()
            case .main:
                MainTabView()
            case .provisioningFailure:
                ProvisioningFailureView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.phase)
        .task {
            await session.start()
        }
        .onOpenURL { url in
            Task { await session.handleAuthURL(url) }
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environment(AppSession())
}
#endif
