//
//  DiningMenuService.swift
//  MyWes
//
//  Fetches Bon Appétit cafe pages and caches parsed menus per cafe and day.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor DiningMenuService {
    static let shared = DiningMenuService()

    private struct Entry {
        var fetchedAt: Date
        var meals: [DiningMeal]
    }

    private var entries: [String: Entry] = [:]
    private var inFlight: [String: Task<[DiningMeal], Error>] = [:]
    private let freshness: TimeInterval = 30 * 60

    func meals(slug: String, dateKey: String, forceRefresh: Bool = false) async throws -> [DiningMeal] {
        let key = "\(slug)/\(dateKey)"
        if !forceRefresh, let entry = entries[key], Date().timeIntervalSince(entry.fetchedAt) < freshness {
            return entry.meals
        }
        if let task = inFlight[key] { return try await task.value }
        let task = Task.detached(priority: .userInitiated) {
            try await Self.fetch(slug: slug, dateKey: dateKey)
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let meals = try await task.value
        entries[key] = Entry(fetchedAt: Date(), meals: meals)
        return meals
    }

    private var specialsData: (fetchedAt: Date, data: Data)?
    private var specialsTask: Task<Data, Error>?

    /// Recent specials posts for WesWings or Red & Black Café. Both come from
    /// one weswings.com request, cached for 30 minutes.
    func specials(_ source: WesWingsSpecials.Source, forceRefresh: Bool = false) async throws -> [DiningSpecialPost] {
        let data: Data
        if !forceRefresh, let cached = specialsData, Date().timeIntervalSince(cached.fetchedAt) < freshness {
            data = cached.data
        } else if let task = specialsTask {
            data = try await task.value
        } else {
            let task = Task.detached(priority: .userInitiated) { try await Self.fetchSpecials() }
            specialsTask = task
            defer { specialsTask = nil }
            data = try await task.value
            specialsData = (Date(), data)
        }
        return try WesWingsSpecials.parse(data, source: source)
    }

    @concurrent
    private nonisolated static func fetchSpecials() async throws -> Data {
        var request = URLRequest(url: WesWingsSpecials.postsURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    @concurrent
    private nonisolated static func fetch(slug: String, dateKey: String) async throws -> [DiningMeal] {
        guard let url = BonAppetitMenu.url(slug: slug, dateKey: dateKey) else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try BonAppetitMenu.parse(html: String(decoding: data, as: UTF8.self))
    }
}
