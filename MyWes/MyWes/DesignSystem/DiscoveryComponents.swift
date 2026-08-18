//
//  DiscoveryComponents.swift
//  MyWes
//

import SwiftUI

struct FilterChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(isSelected ? Theme.cardinal : Theme.background)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct DiscoverLinkCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.discoverCardMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.splashDark)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct WeekEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(event.monthLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(event.dayNumber)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("\(event.time) · \(event.location)")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .cardChrome()
    }
}

struct EventListCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            eventPlaceholderColor(for: event.category)
                .frame(height: 64)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("\(event.dateLabel) · \(event.time) · \(event.location)")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .cardChrome()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct OrganizationRow: View {
    let organization: Organization
    var isFollowing: Bool
    let onToggleFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: AppRoute.organization(organization.id)) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(organizationPlaceholderColor(for: organization.category).opacity(0.25))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(organization.name.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.ink)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(organization.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        Text("\(organization.category) · \(organization.memberCount) members")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            FollowButton(isFollowing: isFollowing, action: onToggleFollow)
        }
        .padding(12)
        .cardChrome()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SearchResultRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .accessibilityAddTraits(.isButton)
    }
}

struct EmptyStateText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Typography.bodySmall)
            .foregroundStyle(Theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

struct CatalogStatusView<Content: View>: View {
    let catalog: CampusCatalog
    var emptyMessage: String? = nil
    var overlayPadding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        switch catalog.status {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, overlayPadding)
        case .empty:
            Group {
                if let emptyMessage {
                    EmptyStateText(message: emptyMessage)
                } else {
                    content()
                }
            }
            .padding(.horizontal, emptyMessage == nil ? 0 : overlayPadding)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondaryText)
                Button("Retry") {
                    Task { await catalog.refresh() }
                }
                .font(Typography.label)
                .foregroundStyle(Theme.cardinal)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.horizontal, overlayPadding)
        case .loaded:
            content()
        }
    }
}

struct CatalogItemStatusView: View {
    let catalog: CampusCatalog
    let title: String
    let systemImage: String

    var body: some View {
        switch catalog.status {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondaryText)
                Button("Retry") {
                    Task { await catalog.refresh() }
                }
                .font(Typography.label)
                .foregroundStyle(Theme.cardinal)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(20)
        case .empty, .loaded:
            ContentUnavailableView(title, systemImage: systemImage)
        }
    }
}

struct SeeAllLink: View {
    var body: some View {
        Text("See all")
            .font(Typography.label)
            .foregroundStyle(Theme.cardinal)
    }
}
