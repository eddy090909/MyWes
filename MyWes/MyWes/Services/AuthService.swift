//
//  AuthService.swift
//  MyWes
//

import AuthenticationServices
import Foundation
import Auth
import Supabase

struct AuthService {
    let client: SupabaseClient

    func signInWithGoogle() async throws -> Session {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: AuthRedirect.callbackURL
        ) { session in
            session.prefersEphemeralWebBrowserSession = true
        }
    }

    func session(from url: URL) async throws -> Session {
        try await client.auth.session(from: url)
    }

    func sessionUserID(from url: URL) async throws -> UUID {
        try await session(from: url).user.id
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

    func signOutChecked() async throws {
        try await client.auth.signOut(scope: .local)
    }

    func signOut() async {
        try? await client.auth.signOut(scope: .local)
    }
}

enum AuthUserFacingError {
    static let wesleyanOnlyMessage =
        "MyWes is only available to Wesleyan accounts. Sign in with your @wesleyan.edu Google account."

    static func isCancellation(_ error: Error) -> Bool {
        if let asError = error as? ASWebAuthenticationSessionError {
            return asError.code == .canceledLogin
        }
        let nsError = error as NSError
        return nsError.domain == ASWebAuthenticationSessionError.errorDomain
            && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
    }

    static func message(for error: Error) -> String {
        if isCancellation(error) {
            return ""
        }

        if let configError = error as? SupabaseConfigError {
            return configError.localizedDescription
        }

        if let authError = error as? AuthError {
            switch authError {
            case .api(let message, _, _, let response):
                if looksLikeWorkspacePolicy(message) {
                    return message
                }
                if response.statusCode == 403 || response.statusCode == 400 {
                    return wesleyanOnlyMessage
                }
                return message.isEmpty
                    ? "Could not complete Google sign-in. Please try again."
                    : message
            case .sessionMissing:
                return "Your session expired. Please sign in again."
            case .pkceGrantCodeExchange(let message, let oauthError, let code):
                if let exact = workspacePolicyMessage(message, oauthError, code) {
                    return exact
                }
                return "Google sign-in didn't complete. Please try again."
            case .implicitGrantRedirect(let message):
                if looksLikeWorkspacePolicy(message) {
                    return message
                }
                return "Google sign-in didn't complete. Please try again."
            default:
                let description = authError.errorDescription ?? ""
                if looksLikeWorkspacePolicy(description) {
                    return description
                }
                return description.isEmpty
                    ? "Could not complete Google sign-in. Please try again."
                    : description
            }
        }

        let localized = error.localizedDescription
        if looksLikeWorkspacePolicy(localized) {
            return localized
        }
        return "Something went wrong. Please try again."
    }

    private static func workspacePolicyMessage(_ parts: String?...) -> String? {
        let nonempty = parts.compactMap { part -> String? in
            guard let part, !part.isEmpty else { return nil }
            return part
        }
        let combined = nonempty.joined(separator: " ")
        guard looksLikeWorkspacePolicy(combined) else { return nil }
        return combined
    }

    private static func looksLikeWorkspacePolicy(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("app blocked")
            || lower.contains("administrator approval")
            || lower.contains("access_denied")
            || lower.contains("access denied")
            || lower.contains("org_internal")
            || (lower.contains("403") && lower.contains("org"))
    }
}
