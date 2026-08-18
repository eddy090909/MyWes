//
//  AuthService.swift
//  MyWes
//

import Foundation
import Auth
import Supabase

struct AuthService {
    let client: SupabaseClient

    func sendMagicLink(to email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: AuthRedirect.callbackURL,
            shouldCreateUser: true
        )
    }

    func sessionUserID(from url: URL) async throws -> UUID {
        try await client.auth.session(from: url).user.id
    }

    func validUserID() async throws -> UUID? {
        try await validSession()?.user.id
    }

    func validSession() async throws -> Session? {
        do {
            return try await client.auth.session
        } catch AuthError.sessionMissing {
            return nil
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
    }
}

enum AuthUserFacingError {
    static func message(for error: Error) -> String {
        if let configError = error as? SupabaseConfigError {
            return configError.localizedDescription
        }

        if let authError = error as? AuthError {
            switch authError {
            case .api(let message, _, _, let response):
                if response.statusCode == 403 || response.statusCode == 400 {
                    return message.isEmpty
                        ? "MyWes is only available to Wesleyan University email addresses."
                        : message
                }
                if response.statusCode == 429 {
                    return "Please wait a moment before requesting another sign-in link."
                }
                return message.isEmpty ? "Could not send a sign-in link. Please try again." : message
            case .sessionMissing:
                return "Your session expired. Please sign in again."
            case .pkceGrantCodeExchange:
                return "That sign-in link is invalid or expired. Request a new one."
            case .implicitGrantRedirect:
                return "That sign-in link could not be opened. Request a new one."
            default:
                return authError.errorDescription ?? "Could not complete sign-in. Please try again."
            }
        }

        return "Something went wrong. Please try again."
    }
}
