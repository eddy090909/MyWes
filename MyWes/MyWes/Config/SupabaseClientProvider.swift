//
//  SupabaseClientProvider.swift
//  MyWes
//

import Foundation
import Supabase

enum SupabaseClientProvider {
    private static let lock = NSLock()
    private static var cached: SupabaseClient?

    /// Builds a client using the anon/publishable key only.
    /// Session storage uses supabase-swift's Apple-platform default (`KeychainLocalStorage`).
    /// The same instance is reused so auth and catalog share one session.
    static func makeClient() throws -> SupabaseClient {
        lock.lock()
        defer { lock.unlock() }
        if let cached {
            return cached
        }
        let url = try SupabaseConfig.url()
        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: .init(redirectToURL: AuthRedirect.callbackURL)
            )
        )
        cached = client
        return client
    }
}
