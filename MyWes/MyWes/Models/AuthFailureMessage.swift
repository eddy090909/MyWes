import Foundation

nonisolated enum AuthSetupError: LocalizedError {
    case secureStorageUnavailable

    var errorDescription: String? {
        "MyWes couldn't access secure login storage. Run a signed build from Xcode and try again."
    }
}

nonisolated enum AuthFailureMessage {
    static func api(message: String, statusCode: Int) -> String {
        let lower = message.lowercased()
        if lower.contains("code verifier") || lower.contains("code_verifier")
            || lower.contains("flow state") || lower.contains("flow_state") {
            return "The secure login attempt expired or couldn't be restored. Start Google sign-in again. If this repeats, run a signed build from Xcode."
        }
        // A status code alone cannot establish that a student's email is wrong.
        if lower.contains("only available to wesleyan")
            || lower.contains("wesleyan university email address is required") {
            return "MyWes is only available to Wesleyan accounts. Sign in with your @wesleyan.edu Google account."
        }
        if statusCode == 429 { return "Too many sign-in attempts. Wait a moment and try again." }
        if lower.contains("provider is not enabled") || lower.contains("unsupported provider") {
            return "Google sign-in isn't enabled for this MyWes backend. Contact the app owner."
        }
        return "Google sign-in couldn't finish (HTTP \(statusCode)). Please start a new sign-in attempt."
    }
}
