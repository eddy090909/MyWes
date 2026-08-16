//
//  DiscoverView.swift
//  MyWes
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Discover")
                    .font(Typography.headlineLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                VStack(spacing: 12) {
                    NavigationLink(value: AppRoute.events) {
                        DiscoverLinkCard(
                            title: "Events",
                            subtitle: "\(MockData.events.count) upcoming across campus"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: AppRoute.organizations) {
                        DiscoverLinkCard(
                            title: "Organizations",
                            subtitle: "\(MockData.organizations.count) clubs and student groups"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.screenPadding)

                Text("Happening this week")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 10)

                VStack(spacing: Theme.listGap) {
                    ForEach(MockData.discoverWeekEvents) { event in
                        NavigationLink(value: AppRoute.event(event.id)) {
                            WeekEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
            .appDestinations()
    }
    .environment(AppSession())
}
