//
//  AppSession.swift
//  MyWes
//

import Foundation
import Observation
import SwiftUI

enum AppPhase: Equatable {
    case splash
    case signIn
    case verify
    case onboarding
    case main
}

@Observable
final class AppSession {
    var phase: AppPhase
    var currentUser: AppUser?
    var pendingEmail: String = ""

    // Onboarding draft
    var onboardStep: Int = 0
    var selectedYear: String?
    var selectedInterests: Set<String> = []
    var followedOrgIDs: Set<UUID> = []
    var savedEventIDs: Set<UUID> = []

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        if completed {
            let user = MockData.defaultUser()
            phase = .main
            currentUser = user
            followedOrgIDs = user.followedOrgIDs
            savedEventIDs = []
        } else {
            phase = .splash
            currentUser = nil
        }
    }

    private static let onboardingKey = "hasCompletedOnboarding"
    /// Milestone 1 mock OTP. Production will replace this with Supabase email OTP.
    static let mockVerificationCode = "123456"
    private static let mockFirstName = "Alex"
    private static let wesleyanEmailPattern = /^[a-z0-9._%+\-]+@wesleyan\.edu$/

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.onboardingKey) }
    }

    var savedEventCount: Int {
        savedEventIDs.count
    }

    static func isValidWesleyanEmail(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return false }
        return trimmed.wholeMatch(of: wesleyanEmailPattern) != nil
    }

    func continueFromSplash() {
        phase = .signIn
    }

    func submitWesleyanEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidWesleyanEmail(trimmed) else { return false }
        pendingEmail = trimmed
        phase = .verify
        return true
    }

    func returnToEmailEntry() {
        phase = .signIn
    }

    func verifyCode(_ code: String) -> Bool {
        let digits = String(code.filter(\.isNumber).prefix(6))
        guard digits.count == 6 else { return false }
        guard digits == Self.mockVerificationCode else { return false }
        guard !pendingEmail.isEmpty else { return false }

        currentUser = AppUser(
            id: UUID(),
            email: pendingEmail,
            firstName: Self.mockFirstName,
            classYear: nil,
            interests: [],
            followedOrgIDs: []
        )
        onboardStep = 0
        selectedYear = nil
        selectedInterests = []
        followedOrgIDs = []
        savedEventIDs = []
        phase = .onboarding
        return true
    }

    func toggleInterest(_ name: String) {
        if selectedInterests.contains(name) {
            selectedInterests.remove(name)
        } else {
            selectedInterests.insert(name)
        }
    }

    func isFollowing(_ orgID: UUID) -> Bool {
        followedOrgIDs.contains(orgID)
    }

    func toggleFollow(_ orgID: UUID) {
        if followedOrgIDs.contains(orgID) {
            followedOrgIDs.remove(orgID)
        } else {
            followedOrgIDs.insert(orgID)
        }
        if var user = currentUser {
            user.followedOrgIDs = followedOrgIDs
            currentUser = user
        }
    }

    func isSaved(_ eventID: UUID) -> Bool {
        savedEventIDs.contains(eventID)
    }

    func toggleSaveEvent(_ eventID: UUID) {
        if savedEventIDs.contains(eventID) {
            savedEventIDs.remove(eventID)
        } else {
            savedEventIDs.insert(eventID)
        }
    }

    func onboardBack() {
        if onboardStep > 0 {
            onboardStep -= 1
        }
    }

    func onboardContinue() {
        if onboardStep < 2 {
            onboardStep += 1
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        guard var user = currentUser else { return }
        user.classYear = selectedYear
        user.interests = Array(selectedInterests).sorted()
        user.followedOrgIDs = followedOrgIDs
        currentUser = user
        hasCompletedOnboarding = true
        phase = .main
    }
}
