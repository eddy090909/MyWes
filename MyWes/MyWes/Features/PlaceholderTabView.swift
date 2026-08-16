//
//  PlaceholderTabView.swift
//  MyWes
//

import SwiftUI

struct PlaceholderTabView: View {
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.ink)

            Text("Coming soon")
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderTabView(title: "Discover")
    }
}
