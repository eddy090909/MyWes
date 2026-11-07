import Foundation

@main struct AuthFailureTests {
    static func main() {
        let verifier = AuthFailureMessage.api(message: "invalid request: both auth code and code verifier should be non-empty", statusCode: 400)
        assert(verifier.contains("secure login attempt"))
        assert(!verifier.contains("only available to Wesleyan"))
        for status in [400, 403] {
            let message = AuthFailureMessage.api(message: "unrelated request error", statusCode: status)
            assert(!message.contains("only available to Wesleyan"))
            assert(message.contains("HTTP \(status)"))
        }
        let domain = AuthFailureMessage.api(message: "MyWes is only available to Wesleyan University email addresses.", statusCode: 403)
        assert(domain.contains("@wesleyan.edu"))
        assert(AuthFailureMessage.api(message: "Provider is not enabled", statusCode: 400).contains("isn't enabled"))
        assert(AuthFailureMessage.api(message: "rate limited", statusCode: 429).contains("Too many"))
        assert(AuthSetupError.secureStorageUnavailable.localizedDescription.contains("secure login storage"))
        print("Auth failure checks passed: missing verifier, unrelated 400/403, domain gate, disabled provider, rate limiting, Keychain failure.")
    }
}
