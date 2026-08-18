//
//  DiscoverView.swift
//  MyWes
//

import SwiftUI

struct DiscoverView: View {
    @Environment(AppSession.self) private var session

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

                CatalogStatusView(
                    catalog: session.catalog,
                    emptyMessage: "No campus events or organizations yet.",
                    overlayPadding: Theme.screenPadding
                ) {
                    loadedContent
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 12) {
                NavigationLink(value: AppRoute.events) {
                    DiscoverLinkCard(
                        title: "Events",
                        subtitle: "\(session.catalog.upcomingEvents.count) upcoming across campus"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: AppRoute.organizations) {
                    DiscoverLinkCard(
                        title: "Organizations",
                        subtitle: "\(session.catalog.organizations.count) clubs and student groups"
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
                if session.catalog.discoverWeekEvents.isEmpty {
                    EmptyStateText(message: "Nothing happening this week.")
                } else {
                    ForEach(session.catalog.discoverWeekEvents) { event in
                        NavigationLink(value: AppRoute.event(event.id)) {
                            WeekEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
