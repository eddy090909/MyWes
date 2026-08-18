//
//  OrganizationsListView.swift
//  MyWes
//

import SwiftUI

struct OrganizationsListView: View {
    @Environment(AppSession.self) private var session
    @State private var selectedCategory = "All"

    private var filteredOrganizations: [Organization] {
        if selectedCategory == "All" {
            return session.catalog.organizations
        }
        return session.catalog.organizations.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if session.engagementError != nil {
                    EngagementErrorCaption()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                CatalogStatusView(
                    catalog: session.catalog,
                    emptyMessage: "No organizations yet."
                ) {
                    loadedContent
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Organizations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(session.catalog.organizationFilterCategories, id: \.self) { category in
                        FilterChip(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            LazyVStack(spacing: 10) {
                ForEach(filteredOrganizations) { organization in
                    OrganizationRow(
                        organization: organization,
                        isFollowing: session.isFollowing(organization.id)
                    ) {
                        session.toggleFollow(organization.id)
                    }
                }

                if filteredOrganizations.isEmpty {
                    EmptyStateText(
                        message: selectedCategory == "All"
                            ? "No organizations yet."
                            : "No organizations match this filter."
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NavigationStack {
        OrganizationsListView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
