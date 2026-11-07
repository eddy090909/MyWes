//
//  RestoringSessionView.swift
//  MyWes
//

import SwiftUI

struct RestoringSessionView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            Theme.splashDark
                .ignoresSafeArea()

            VStack(spacing: 18) {
                AppLogoMark(size: 76, cornerRadius: Theme.logoRadiusLarge)

                Text("MyWes")
                    .font(Typography.displayLarge)
                    .tracking(-0.4)
                    .foregroundStyle(.white)

                if let error = session.engagementError {
                    Text(error)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.splashTagline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)

                    Button("Retry") {
                        Task { await session.retryEngagementLoad() }
                    }
                    .font(Typography.label)
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                    .accessibilityLabel("Retry")
                } else {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 12)
                        .accessibilityLabel("Restoring your session")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    RestoringSessionView()
        .environment(AppSession.preview())
}
#endif
