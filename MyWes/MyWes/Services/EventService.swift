//
//  EventService.swift
//  MyWes
//

import Foundation
import Supabase

struct EventRecord: Codable, Equatable, Sendable {
    var id: UUID
    var orgId: UUID
    var title: String
    var category: String
    var description: String
    var location: String
    var startAt: Date
    var endAt: Date?
}

struct EventService {
    let client: SupabaseClient

    func fetchEvents() async throws -> [Event] {
        let rows: [EventRecord] = try await client
            .from("events")
            .select("id,org_id,title,category,description,location,start_at,end_at")
            .order("start_at")
            .execute()
            .value

        return rows.map { row in
            Event(
                id: row.id,
                title: row.title,
                category: row.category,
                location: row.location,
                orgID: row.orgId,
                description: row.description,
                startAt: row.startAt,
                endAt: row.endAt
            )
        }
    }
}
