//
//  HomeView.swift
//  MyWes
//

import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session

    private var firstName: String {
        session.currentUser?.firstName ?? "Alex"
    }

    private var followedIDs: Set<UUID> {
        session.currentUser?.followedOrgIDs ?? []
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

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

            // Non-interactive chrome — Search is not wired in Milestone 1
            Text("Search")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Theme.background)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
    }

    private var upcomingEvents: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Upcoming Events", trailingLabel: "See all")
                .padding(.horizontal, Theme.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MockData.homeEvents) { event in
                        EventCard(event: event)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 6)
            }
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
        }
    }

    private var popularAskWes: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Popular on AskWes", trailingLabel: "See all")
                .padding(.horizontal, Theme.screenPadding)

            VStack(spacing: Theme.listGap) {
                ForEach(MockData.popularQuestions) { question in
                    QuestionRow(question: question)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    private var followedOrgs: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "From Organizations You Follow")
                .padding(.horizontal, Theme.screenPadding)

            let updates = MockData.updates(for: followedIDs)
            if updates.isEmpty {
                Text("Follow organizations during onboarding to see updates here.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, Theme.screenPadding)
            } else {
                VStack(spacing: Theme.listGap) {
                    ForEach(updates) { update in
                        OrgUpdateRow(update: update)
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
    }
    .environment(AppSession())
}
