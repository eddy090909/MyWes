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
            return MockData.organizations
        }
        return MockData.organizations.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MockData.organizationCategories, id: \.self) { category in
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
                        EmptyStateText(message: "No organizations match this filter.")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Organizations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        OrganizationsListView()
            .appDestinations()
    }
    .environment(AppSession())
}
