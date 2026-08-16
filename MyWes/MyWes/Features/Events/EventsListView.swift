//
//  EventsListView.swift
//  MyWes
//

import SwiftUI

struct EventsListView: View {
    @State private var selectedCategory = "All"

    private var filteredEvents: [Event] {
        if selectedCategory == "All" {
            return MockData.events
        }
        return MockData.events.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MockData.eventCategories, id: \.self) { category in
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
                        EmptyStateText(message: "No events match this filter.")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        EventsListView()
            .appDestinations()
    }
    .environment(AppSession())
}
