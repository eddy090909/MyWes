//
//  EventService.swift
//  MyWes
//

import Foundation
import Supabase

struct EventService {
    let client: SupabaseClient

    func fetchEvents() async throws -> [Event] {
        let rows: [EventRecord] = try await client
            .from("events")
            // "*" (not a column list) so this works before and after the
            // campus calendar migration adds is_all_day/source_url.
            .select()
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
                endAt: row.endAt,
                isAllDay: row.isAllDay,
                sourceURL: row.sourceUrl.flatMap(URL.init(string:)).flatMap {
                    $0.scheme == "https" && $0.host == "events.wesleyan.edu" ? $0 : nil
                }
            )
        }
    }
}
