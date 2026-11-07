//
//  SupabaseConfig.swift
//  MyWes
//

import Foundation

enum SupabaseConfigError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case serviceRoleKeyNotAllowed

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase is not configured. Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and add the project URL and anon key."
        case .invalidURL:
            return "SUPABASE_URL is not a valid URL."
        case .serviceRoleKeyNotAllowed:
            return "The service-role key must never be used in the iOS app. Use the anon/publishable key."
        }
    }
}

enum SupabaseConfig {
    static var urlString: String {
        string(forInfoKey: "SUPABASE_URL")
    }

    static var anonKey: String {
        string(forInfoKey: "SUPABASE_ANON_KEY")
    }

    /// True only when Secrets.xcconfig (or equivalent build settings) supplied real project values.
    static var isConfigured: Bool {
        guard !urlString.isEmpty, !anonKey.isEmpty else { return false }
        if urlString.contains("YOUR_PROJECT_REF") { return false }
        if anonKey.hasPrefix("YOUR_") { return false }
        return URL(string: urlString) != nil
    }

    static func url() throws -> URL {
        try validate()
        guard let url = URL(string: urlString), url.scheme == "https",
              url.host != nil, url.user == nil, url.password == nil else {
            throw SupabaseConfigError.invalidURL
        }
        return url
    }

    static func validate() throws {
        guard isConfigured else {
            throw SupabaseConfigError.missingConfiguration
        }
        if looksLikeServiceRoleKey(anonKey) {
            throw SupabaseConfigError.serviceRoleKeyNotAllowed
        }
    }

    private static func string(forInfoKey key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Best-effort guard against pasting the dashboard service_role JWT into the client.
    private static func looksLikeServiceRoleKey(_ key: String) -> Bool {
        if key.hasPrefix("sb_secret_") { return true }
        let segments = key.split(separator: ".")
        guard segments.count >= 2 else { return false }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = payload.count % 4
        if remainder > 0 {
            payload.append(String(repeating: "=", count: 4 - remainder))
        }

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let role = json["role"] as? String
        else {
            return false
        }

        return role == "service_role"
    }
}
