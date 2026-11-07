//
//  OrganizationDetailView.swift
//  MyWes
//

import SwiftUI

struct OrganizationDetailView: View {
    let orgID: UUID
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private var organization: Organization? {
        session.catalog.organization(id: orgID)
    }

    private var upcomingEvents: [Event] {
        session.catalog.events(hostedBy: orgID)
    }

    private var isFollowing: Bool {
        session.isFollowing(orgID)
    }

    var body: some View {
        Group {
            if let organization {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(organization)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(organization.name)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(Theme.ink)
                                .padding(.bottom, 4)

                            Text("\(organization.category) · \(organization.memberCount) members")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.secondaryText)
                                .padding(.bottom, 16)

                            FollowButton(
                                isFollowing: isFollowing,
                                isWide: true
                            ) {
                                session.toggleFollow(orgID)
                            }
                            .padding(.bottom, session.engagementError == nil ? 18 : 10)

                            if session.engagementError != nil {
                                EngagementErrorCaption()
                                    .padding(.bottom, 18)
                            }

                            Text(organization.description)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink.opacity(0.85))
                                .lineSpacing(4)
                                .padding(.bottom, 18)

                            Text("Upcoming Events")
                                .font(Typography.sectionTitle)
                                .foregroundStyle(Theme.ink)
                                .padding(.bottom, 10)

                            if upcomingEvents.isEmpty {
                                Text("No upcoming events posted.")
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.secondaryText)
                                    .padding(.bottom, 16)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(upcomingEvents) { event in
                                        NavigationLink(value: AppRoute.event(event.id)) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(event.title)
                                                    .font(.system(size: 13.5, weight: .bold))
                                                    .foregroundStyle(Theme.ink)
                                                Text("\(event.dateLabel) · \(event.location)")
                                                    .font(Typography.caption)
                                                    .foregroundStyle(Theme.secondaryText)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .cardChrome()
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.bottom, 16)
                            }

                            contactLine(organization)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                .background(Theme.background.ignoresSafeArea())
            } else {
                CatalogItemStatusView(
                    catalog: session.catalog,
                    title: "Organization unavailable",
                    systemImage: "person.3"
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func header(_ organization: Organization) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                organizationPlaceholderColor(for: organization.category)
                    .frame(height: 120)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.85))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .padding(.top, 16)
                .padding(.leading, 16)
            }

            Circle()
                .fill(organizationPlaceholderColor(for: organization.category).opacity(0.25))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String(organization.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.ink)
                )
                .overlay(
                    Circle().stroke(Theme.background, lineWidth: 4)
                )
                .padding(.leading, 20)
                .offset(y: -32)
                .padding(.bottom, -20)
        }
    }

    @ViewBuilder
    private func contactLine(_ organization: Organization) -> some View {
        let email = organization.contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let handle = organization.instagramHandle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasEmail = !(email?.isEmpty ?? true)
        let hasHandle = !(handle?.isEmpty ?? true)

        if hasEmail || hasHandle {
            HStack(spacing: 6) {
                if let email, hasEmail, let mailURL = URL(string: "mailto:\(email)") {
                    Link(destination: mailURL) {
                        Label(email, systemImage: "envelope")
                    }
                }

                if hasEmail && hasHandle {
                    Text("·")
                        .foregroundStyle(Theme.secondaryText)
                }

                if let handle, hasHandle {
                    let trimmed = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
                    if let instagramURL = URL(string: "https://instagram.com/\(trimmed)") {
                        Link(destination: instagramURL) {
                            Text("@\(trimmed)")
                        }
                    } else {
                        Text("@\(trimmed)")
                    }
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(Theme.secondaryText)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        OrganizationDetailView(orgID: MockData.IDs.org1)
            .appDestinations()
    }
    .environment(AppSession.preview())
}
#endif
