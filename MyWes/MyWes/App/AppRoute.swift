//
//  AppRoute.swift
//  MyWes
//

import SwiftUI

enum AppRoute: Hashable {
    case search
    case events
    case event(UUID)
    case organizations
    case organization(UUID)
    case savedEvents
}

extension View {
    func appDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .search:
                SearchView()
            case .events:
                EventsListView()
            case .event(let id):
                EventDetailView(eventID: id)
            case .organizations:
                OrganizationsListView()
            case .organization(let id):
                OrganizationDetailView(orgID: id)
            case .savedEvents:
                SavedEventsView()
            }
        }
    }
}
