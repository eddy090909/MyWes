//
//  OrganizationService.swift
//  MyWes
//

import Foundation
import Supabase

struct OrganizationRecord: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var category: String
    var description: String
    var memberCount: Int
    var contactEmail: String?
    var instagramHandle: String?
}

struct OrganizationService {
    let client: SupabaseClient

    func fetchOrganizations() async throws -> [Organization] {
        let rows: [OrganizationRecord] = try await client
            .from("organizations")
            .select("id,name,category,description,member_count,contact_email,instagram_handle")
            .order("id")
            .execute()
            .value

        return rows.map { row in
            Organization(
                id: row.id,
                name: row.name,
                category: row.category,
                memberCount: row.memberCount,
                description: row.description,
                contactEmail: row.contactEmail,
                instagramHandle: row.instagramHandle
            )
        }
    }
}
