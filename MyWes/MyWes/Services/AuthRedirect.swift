//
//  AuthRedirect.swift
//  MyWes
//

import Foundation

enum AuthRedirect {
    static let callbackURL = URL(string: "mywes://auth-callback")!

    static func isCallback(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "mywes" && url.host?.lowercased() == "auth-callback"
    }
}
