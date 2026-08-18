//
//  ProfileService.swift
//  MyWes
//

import Foundation
import Supabase

struct ProfileRecord: Codable, Equatable, Sendable {
    var id: UUID
    var email: String
    var fullName: String?
    var classYear: Int?
    var interests: [String]
    var onboardingCompleted: Bool
}

struct ProfileService {
    let client: SupabaseClient

    func fetchProfile(userID: UUID) async throws -> ProfileRecord? {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .maybeSingle()
            .execute()
            .value
    }

    func completeOnboarding(
        userID: UUID,
        classYear: Int,
        interests: [String]
    ) async throws -> ProfileRecord {
        let update = ProfileOnboardingUpdate(
            classYear: classYear,
            interests: interests,
            onboardingCompleted: true
        )

        return try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userID)
            .select()
            .single()
            .execute()
            .value
    }
}

private struct ProfileOnboardingUpdate: Encodable {
    var classYear: Int
    var interests: [String]
    var onboardingCompleted: Bool
}
