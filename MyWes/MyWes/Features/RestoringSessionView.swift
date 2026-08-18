//
//  RestoringSessionView.swift
//  MyWes
//

import SwiftUI

struct RestoringSessionView: View {
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

                ProgressView()
                    .tint(.white)
                    .padding(.top, 12)
                    .accessibilityLabel("Restoring your session")
            }
        }
    }
}

#Preview {
    RestoringSessionView()
}
