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

                if session.engagementError != nil {
                    EngagementErrorCaption()
                        .padding(.horizontal, Theme.screenPadding)
                        .padding(.top, 14)
                }

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
        .task { await session.community.refresh() }
        .refreshable {
            await session.catalog.refresh()
            await session.community.refresh()
        }
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
            SectionHeader(title: "Dining Today") {
                NavigationLink(value: AppRoute.dining) { SeeAllLink() }
            }
            if let error = session.community.diningError {
                CampusRetry(message: error) { await session.community.refresh() }
            } else if session.community.dining.isEmpty {
                Text(session.community.isLoading ? "Loading dining hours…" : "No dining schedules published yet.")
                    .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
            }
            TimelineView(.periodic(from: .now, by: 60)) { context in
                ForEach(session.community.dining.prefix(2)) { venue in
                    DiningVenueCard(venue: venue, date: context.date)
                }
            }
        }.padding(.horizontal, Theme.screenPadding)
    }

    private var popularAskWes: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Latest on AskWes") {
                NavigationLink(value: AppRoute.askWes) { SeeAllLink() }
            }
            if let error = session.community.questionError {
                CampusRetry(message: error) { await session.community.refresh() }
            } else if session.community.questions.isEmpty {
                Text(session.community.isLoading ? "Loading questions…" : "No questions yet. Ask your campus a question.")
                    .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
            }
            ForEach(session.community.questions.prefix(3)) { question in
                NavigationLink(value: AppRoute.question(question.id)) { CampusQuestionRow(question: question) }
                    .buttonStyle(.plain)
            }
        }.padding(.horizontal, Theme.screenPadding)
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
            SectionHeader(title: "Events from Organizations You Follow")
                .padding(.horizontal, Theme.screenPadding)

            let updates = session.catalog.upcomingEvents.filter { session.followedOrgIDs.contains($0.orgID) }
            if updates.isEmpty {
                Text("No upcoming events from followed organizations.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, Theme.screenPadding)
            } else {
                VStack(spacing: Theme.listGap) {
                    ForEach(updates) { event in
                        NavigationLink(value: AppRoute.event(event.id)) {
                            SearchResultRow(title: event.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
#endif
