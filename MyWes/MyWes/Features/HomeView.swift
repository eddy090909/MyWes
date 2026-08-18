//
//  HomeView.swift
//  MyWes
//

import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session

    private var firstName: String {
        session.currentUser?.firstName ?? "Cardinal"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var savedBannerText: String {
        let count = session.savedEventCount
        let noun = count == 1 ? "event" : "events"
        return "You have \(count) saved \(noun) — tap to view"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                if session.savedEventCount > 0 {
                    NavigationLink(value: AppRoute.savedEvents) {
                        Text(savedBannerText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.cardinalPressed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Theme.savedBannerBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 14)
                    .accessibilityLabel(savedBannerText)
                }

                upcomingEvents
                    .padding(.top, 22)

                diningToday
                    .padding(.top, Theme.sectionGap)

                popularAskWes
                    .padding(.top, Theme.sectionGap)

                followedOrgs
                    .padding(.top, Theme.sectionGap)
                    .padding(.bottom, 40)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting.uppercased())
                    .font(Typography.eyebrow)
                    .tracking(0.5)
                    .foregroundStyle(Theme.ink)

                Text(firstName)
                    .font(Typography.headlineLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
            }

            Spacer()

            NavigationLink(value: AppRoute.search) {
                Text("Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Theme.background)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
    }

    private var upcomingEvents: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Upcoming Events") {
                NavigationLink(value: AppRoute.events) {
                    SeeAllLink()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.screenPadding)

            CatalogStatusView(
                catalog: session.catalog,
                emptyMessage: "No upcoming events.",
                overlayPadding: 0
            ) {
                if session.catalog.homeEvents.isEmpty {
                    EmptyStateText(message: "No upcoming events.")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(session.catalog.homeEvents) { event in
                                NavigationLink(value: AppRoute.event(event.id)) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.screenPadding)
                        .padding(.bottom, 6)
                    }
                }
            }
            .padding(
                .horizontal,
                session.catalog.status == .loaded && !session.catalog.homeEvents.isEmpty
                    ? 0
                    : Theme.screenPadding
            )
        }
    }

    private var diningToday: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Dining Today")
                .padding(.horizontal, Theme.screenPadding)

            HStack(spacing: 10) {
                ForEach(MockData.homeDining) { location in
                    DiningStatusCard(location: location)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .accessibilityElement(children: .contain)
        }
    }

    private var popularAskWes: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Popular on AskWes")
                .padding(.horizontal, Theme.screenPadding)

            VStack(spacing: Theme.listGap) {
                ForEach(MockData.popularQuestions) { question in
                    QuestionRow(question: question)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    @ViewBuilder
    private var followedOrgs: some View {
        switch session.catalog.status {
        case .loaded, .empty:
            followedOrgsContent
        case .idle, .loading, .failed:
            EmptyView()
        }
    }

    private var followedOrgsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "From Organizations You Follow")
                .padding(.horizontal, Theme.screenPadding)

            let updates = MockData.updates(
                for: session.followedOrgIDs,
                organizations: session.catalog.organizations
            )
            if updates.isEmpty {
                Text("Follow organizations to see updates here.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, Theme.screenPadding)
            } else {
                VStack(spacing: Theme.listGap) {
                    ForEach(updates) { update in
                        NavigationLink(value: AppRoute.organization(update.orgID)) {
                            OrgUpdateRow(update: update)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
