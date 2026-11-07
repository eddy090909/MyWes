//
//  ProfileService.swift
//  MyWes
//

import Foundation
import Supabase

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

    func updateProfile(userID: UUID, name: String, year: Int, interests: [String]) async throws -> ProfileRecord {
        try await client.from("profiles")
            .update(ProfileEdit(fullName: name, classYear: year, interests: interests))
            .eq("id", value: userID).select().single().execute().value
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

nonisolated enum ProfileEditError: LocalizedError {
    case invalidInput
    var errorDescription: String? {
        "Use a name of up to 100 characters, a year from 2020–2040, and up to 20 interests of 60 characters each."
    }
}
