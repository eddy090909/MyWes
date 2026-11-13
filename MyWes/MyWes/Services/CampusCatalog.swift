//
//  CampusCatalog.swift
//  MyWes
//

import Foundation
import Observation
import Supabase

@Observable
final class CampusCatalog {
    enum Status: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var organizations: [Organization] = []
    private(set) var events: [Event] = []

    private let organizationService: OrganizationService?
    private let eventService: EventService?
    private var loadTask: Task<Void, Never>?

    init(client: SupabaseClient?) {
        if let client {
            organizationService = OrganizationService(client: client)
            eventService = EventService(client: client)
        } else {
            organizationService = nil
            eventService = nil
        }
    }

    var upcomingEvents: [Event] {
        let start = CampusTime.startOfToday()
        return events
            .filter { $0.startAt >= start }
            .sorted { $0.startAt < $1.startAt }
    }

    var homeEvents: [Event] {
        Array(upcomingEvents.prefix(4))
    }

    var discoverWeekEvents: [Event] {
        events
            .filter { CampusTime.isInCurrentWeek($0.startAt) }
            .sorted { $0.startAt < $1.startAt }
    }

    var eventFilterCategories: [String] {
        filterCategories(
            preferred: ["All", "Social", "Academic", "Arts", "Athletics", "Dining", "Community"],
            values: events.map(\.category)
        )
    }

    var organizationFilterCategories: [String] {
        filterCategories(
            preferred: ["All", "Governance", "Media", "Academic", "Arts", "Athletics", "Community", "Social", "Campus Services"],
            values: organizations.map(\.category)
        )
    }

    var onboardingOrganizations: [Organization] {
        Array(organizations.sorted { $0.id < $1.id }.prefix(4))
    }

    func organization(id: UUID) -> Organization? {
        organizations.first { $0.id == id }
    }

    func event(id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    func events(hostedBy orgID: UUID) -> [Event] {
        upcomingEvents.filter { $0.orgID == orgID }
    }

    func savedEvents(ids: Set<UUID>) -> [Event] {
        events.filter { ids.contains($0.id) }
    }

    func search(query: String) -> (events: [Event], organizations: [Organization]) {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return ([], []) }

        let matchedEvents = events.filter {
            $0.title.lowercased().contains(needle) || $0.category.lowercased().contains(needle)
        }
        let matchedOrgs = organizations.filter {
            $0.name.lowercased().contains(needle) || $0.category.lowercased().contains(needle)
        }
        return (matchedEvents, matchedOrgs)
    }

    func refreshIfNeeded() async {
        switch status {
        case .loaded, .empty, .loading:
            return
        case .idle, .failed:
            await refresh()
        }
    }

    func refresh() async {
        loadTask?.cancel()
        let task = Task { await performRefresh() }
        loadTask = task
        await task.value
    }

    func reset() {
        loadTask?.cancel()
        loadTask = nil
        organizations = []
        events = []
        status = .idle
    }

    func usePreviewData(organizations: [Organization], events: [Event]) {
        self.organizations = organizations
        self.events = events
        status = organizations.isEmpty && events.isEmpty ? .empty : .loaded
    }

    private func performRefresh() async {
        guard let organizationService, let eventService else {
            status = .failed(SupabaseConfigError.missingConfiguration.localizedDescription)
            return
        }

        status = .loading
        do {
            async let fetchedOrgs = organizationService.fetchOrganizations()
            async let fetchedEvents = eventService.fetchEvents()
            let (orgs, evts) = try await (fetchedOrgs, fetchedEvents)
            guard !Task.isCancelled else { return }
            organizations = orgs
            events = evts
            status = orgs.isEmpty && evts.isEmpty ? .empty : .loaded
        } catch {
            guard !Task.isCancelled else { return }
            organizations = []
            events = []
            status = .failed(AuthUserFacingError.message(for: error))
        }
    }

    private func filterCategories(preferred: [String], values: [String]) -> [String] {
        let present = Set(values)
        var result = preferred.filter { $0 == "All" || present.contains($0) }
        let extras = present.subtracting(preferred).sorted()
        result.append(contentsOf: extras)
        return result
    }
}
