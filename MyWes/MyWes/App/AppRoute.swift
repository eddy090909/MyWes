//
//  AppRoute.swift
//  MyWes
//

import SwiftUI

enum AppRoute: Hashable {
    case question(UUID)
    case dining
    case diningMenu(UUID)
    case askWes
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
            case .question(let id):
                QuestionDetailView(questionID: id)
            case .dining:
                DiningView()
            case .diningMenu(let id):
                DiningMenuView(venueID: id)
            case .askWes:
                AskWesView()
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
