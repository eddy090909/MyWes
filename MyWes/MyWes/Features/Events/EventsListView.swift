//
//  EventsListView.swift
//  MyWes
//

import SwiftUI

struct EventsListView: View {
    @Environment(AppSession.self) private var session
    @State private var selectedCategory = "All"

    private var filteredEvents: [Event] {
        if selectedCategory == "All" {
            return session.catalog.events
        }
        return session.catalog.events.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CatalogStatusView(
                    catalog: session.catalog,
                    emptyMessage: "No events posted."
                ) {
                    loadedContent
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(session.catalog.eventFilterCategories, id: \.self) { category in
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
                ForEach(filteredEvents) { event in
                    NavigationLink(value: AppRoute.event(event.id)) {
                        EventListCard(event: event)
                    }
                    .buttonStyle(.plain)
                }

                if filteredEvents.isEmpty {
                    EmptyStateText(
                        message: selectedCategory == "All"
                            ? "No events posted."
                            : "No events match this filter."
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EventsListView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
#endif
