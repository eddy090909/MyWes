//
//  EngagementService.swift
//  MyWes
//

import Foundation
import Supabase

struct EngagementService {
    let client: SupabaseClient

    func fetchFollowedOrganizationIDs() async throws -> Set<UUID> {
        let userID = try await authenticatedUserID()
        let rows: [OrgFollowIDRow] = try await client
            .from("org_follows")
            .select("org_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        return Set(rows.map(\.orgId))
    }

    func follow(organizationID: UUID) async throws {
        let userID = try await authenticatedUserID()
        do {
            try await client
                .from("org_follows")
                .insert(OrgFollowWrite(userId: userID, orgId: organizationID))
                .execute()
        } catch {
            if Self.isDuplicateRelationship(error) {
                return
            }
            throw error
        }
    }

    func unfollow(organizationID: UUID) async throws {
        let userID = try await authenticatedUserID()
        try await client
            .from("org_follows")
            .delete()
            .eq("user_id", value: userID)
            .eq("org_id", value: organizationID)
            .execute()
    }

    func fetchSavedEventIDs() async throws -> Set<UUID> {
        let userID = try await authenticatedUserID()
        let rows: [EventSaveIDRow] = try await client
            .from("event_saves")
            .select("event_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        return Set(rows.map(\.eventId))
    }

    func save(eventID: UUID) async throws {
        let userID = try await authenticatedUserID()
        do {
            try await client
                .from("event_saves")
                .insert(EventSaveWrite(userId: userID, eventId: eventID))
                .execute()
        } catch {
            if Self.isDuplicateRelationship(error) {
                return
            }
            throw error
        }
    }

    func unsave(eventID: UUID) async throws {
        let userID = try await authenticatedUserID()
        try await client
            .from("event_saves")
            .delete()
            .eq("user_id", value: userID)
            .eq("event_id", value: eventID)
            .execute()
    }

    private func authenticatedUserID() async throws -> UUID {
        try await client.auth.session.user.id
    }

    private static func isDuplicateRelationship(_ error: Error) -> Bool {
        if let postgrest = error as? PostgrestError, postgrest.code == "23505" {
            return true
        }
        if let http = error as? HTTPError, http.response.statusCode == 409 {
            return true
        }
        return false
    }
}

private struct OrgFollowIDRow: Decodable, Sendable {
    var orgId: UUID

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
    }
}

private struct EventSaveIDRow: Decodable, Sendable {
    var eventId: UUID

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
    }
}

private struct OrgFollowWrite: Encodable, Sendable {
    var userId: UUID
    var orgId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case orgId = "org_id"
    }
}

private struct EventSaveWrite: Encodable, Sendable {
    var userId: UUID
    var eventId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventId = "event_id"
    }
}
