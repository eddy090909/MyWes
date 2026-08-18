//
//  SavedEventsView.swift
//  MyWes
//

import SwiftUI

struct SavedEventsView: View {
    @Environment(AppSession.self) private var session

    private var savedEvents: [Event] {
        session.catalog.savedEvents(ids: session.savedEventIDs)
    }

    var body: some View {
        ScrollView {
            CatalogStatusView(catalog: session.catalog, overlayPadding: 0) {
                LazyVStack(spacing: 10) {
                    ForEach(savedEvents) { event in
                        NavigationLink(value: AppRoute.event(event.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.system(size: 14, weight: .bold))
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

                    if savedEvents.isEmpty {
                        EmptyStateText(message: "No saved events yet.")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SavedEventsView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
