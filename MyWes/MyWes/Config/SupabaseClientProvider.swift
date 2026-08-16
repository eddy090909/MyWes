//
//  SupabaseClientProvider.swift
//  MyWes
//

import Foundation
import Supabase

enum SupabaseClientProvider {
    /// Builds a client using the anon/publishable key only.
    /// Session storage uses supabase-swift's Apple-platform default (`KeychainLocalStorage`).
    static func makeClient() throws -> SupabaseClient {
        let url = try SupabaseConfig.url()
        return SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }
}
