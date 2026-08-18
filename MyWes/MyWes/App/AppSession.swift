//
//  AppSession.swift
//  MyWes
//

import Auth
import Foundation
import Observation
import SwiftUI

enum AppPhase: Equatable {
    case restoring
    case splash
    case signIn
    case onboarding
    case main
    case provisioningFailure
}

@Observable
final class AppSession {
    var phase: AppPhase = .restoring
    var currentUser: AppUser?
    var pendingEmail: String = ""
    var authError: String?

    var onboardStep: Int = 0
    var selectedYear: String?
    var selectedInterests: Set<String> = []
    var followedOrgIDs: Set<UUID> = []
    var savedEventIDs: Set<UUID> = []
    var engagementError: String?

    var isSigningIn = false
    var isHandlingCallback = false
    var isCompletingOnboarding = false

    let catalog: CampusCatalog

    private let authService: AuthService?
    private let profileService: ProfileService?
    private let engagementService: EngagementService?
    private var isPreviewMode = false
    private var authGeneration = 0
    private var didStart = false

    private static let wesleyanEmailPattern = /^[a-z0-9._%+\-]+@wesleyan\.edu$/
    private static let engagementLoadFailedMessage = "Couldn't load your follows and saved events. Try again."

    init() {
        if let client = try? SupabaseClientProvider.makeClient() {
            authService = AuthService(client: client)
            profileService = ProfileService(client: client)
            engagementService = EngagementService(client: client)
            catalog = CampusCatalog(client: client)
        } else {
            authService = nil
            profileService = nil
            engagementService = nil
            catalog = CampusCatalog(client: nil)
        }
    }

    var savedEventCount: Int {
        savedEventIDs.count
    }

    static func isValidWesleyanEmail(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return false }
        return trimmed.wholeMatch(of: wesleyanEmailPattern) != nil
    }

    func start() async {
        guard !didStart else { return }
        didStart = true
        await restoreSession()
    }

    func continueFromSplash() {
        authError = nil
        phase = .signIn
    }

    func signInWithGoogle() async {
        guard !isSigningIn else { return }
        guard let authService else {
            authError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }

        authGeneration += 1
        let generation = authGeneration
        isSigningIn = true
        isHandlingCallback = true
        authError = nil
        engagementError = nil
        defer { isSigningIn = false }

        do {
            let session = try await authService.signInWithGoogle()
            guard generation == authGeneration else { return }
            try await completeAuthenticatedSession(session, generation: generation)
        } catch {
            guard generation == authGeneration else { return }
            await authService.signOut()
            signedOut(to: .signIn)
            authError = AuthUserFacingError.isCancellation(error)
                ? nil
                : AuthUserFacingError.message(for: error)
        }
    }

    func tryAnotherGoogleAccount() async {
        await signInWithGoogle()
    }

    func handleAuthURL(_ url: URL) async {
        guard AuthRedirect.isCallback(url) else { return }
        guard !isSigningIn, !isHandlingCallback else { return }
        guard let authService else {
            signedOut(to: .signIn)
            authError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }

        authGeneration += 1
        let generation = authGeneration
        isHandlingCallback = true
        authError = nil
        engagementError = nil

        do {
            let session = try await authService.session(from: url)
            guard generation == authGeneration else { return }
            try await completeAuthenticatedSession(session, generation: generation)
        } catch {
            guard generation == authGeneration else { return }
            await authService.signOut()
            signedOut(to: .signIn)
            authError = AuthUserFacingError.isCancellation(error)
                ? nil
                : AuthUserFacingError.message(for: error)
        }
    }

    func retryProfileLoad() async {
        authError = nil
        engagementError = nil
        guard let authService else {
            signedOut(to: .signIn)
            authError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }

        authGeneration += 1
        let generation = authGeneration
        phase = .restoring

        do {
            guard let session = try await authService.validSession() else {
                signedOut(to: .splash)
                return
            }
            try await completeAuthenticatedSession(session, generation: generation)
        } catch {
            guard generation == authGeneration else { return }
            signedOut(to: .signIn)
            authError = AuthUserFacingError.message(for: error)
        }
    }

    func signOutFromFailure() async {
        await authService?.signOut()
        signedOut(to: .signIn)
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
        let shouldFollow = !followedOrgIDs.contains(orgID)
        applyFollow(orgID, isFollowing: shouldFollow)

        guard !isPreviewMode else { return }

        Task { await persistFollow(orgID, shouldFollow: shouldFollow) }
    }

    func isSaved(_ eventID: UUID) -> Bool {
        savedEventIDs.contains(eventID)
    }

    func toggleSaveEvent(_ eventID: UUID) {
        let shouldSave = !savedEventIDs.contains(eventID)
        applySave(eventID, isSaved: shouldSave)

        guard !isPreviewMode else { return }

        Task { await persistSave(eventID, shouldSave: shouldSave) }
    }

    func retryEngagementLoad() async {
        engagementError = nil
        guard currentUser != nil else {
            await retryProfileLoad()
            return
        }

        let generation = authGeneration
        do {
            try await loadEngagement()
            guard generation == authGeneration else { return }
            phase = currentUser?.onboardingCompleted == true ? .main : .onboarding
            Task { await catalog.refreshIfNeeded() }
        } catch {
            guard generation == authGeneration else { return }
            engagementError = Self.engagementLoadFailedMessage
        }
    }

    func onboardBack() {
        authError = nil
        if onboardStep > 0 {
            onboardStep -= 1
        }
    }

    func onboardContinue() {
        authError = nil
        if onboardStep < 2 {
            onboardStep += 1
        } else {
            Task { await completeOnboarding() }
        }
    }

    private func restoreSession() async {
        guard let authService else {
            phase = .splash
            return
        }

        let generation = authGeneration
        phase = .restoring
        authError = nil
        engagementError = nil

        do {
            guard let session = try await authService.validSession() else {
                guard generation == authGeneration else { return }
                phase = .splash
                return
            }
            try await completeAuthenticatedSession(session, generation: generation)
        } catch {
            guard generation == authGeneration else { return }
            await authService.signOut()
            signedOut(to: .splash)
            authError = AuthUserFacingError.message(for: error)
        }
    }

    private func completeAuthenticatedSession(_ session: Session, generation: Int) async throws {
        guard let email = session.user.email, Self.isValidWesleyanEmail(email) else {
            await authService?.signOut()
            signedOut(to: .signIn)
            authError = AuthUserFacingError.wesleyanOnlyMessage
            return
        }

        phase = .restoring
        try await loadProfileAndRoute(userID: session.user.id, generation: generation)
    }

    private func loadProfileAndRoute(userID: UUID, generation: Int) async throws {
        guard let profileService else {
            throw SupabaseConfigError.missingConfiguration
        }

        guard let profile = try await profileService.fetchProfile(userID: userID) else {
            guard generation == authGeneration else { return }
            currentUser = nil
            isHandlingCallback = false
            phase = .provisioningFailure
            authError = "Your account was created, but your profile could not be loaded. This is a backend provisioning problem, not something the app can invent."
            return
        }

        guard generation == authGeneration else { return }

        apply(profile: profile)
        isHandlingCallback = false
        Task { await catalog.refreshIfNeeded() }

        do {
            try await loadEngagement()
        } catch {
            guard generation == authGeneration else { return }
            engagementError = Self.engagementLoadFailedMessage
            return
        }

        guard generation == authGeneration else { return }
        phase = profile.onboardingCompleted ? .main : .onboarding
    }

    private func apply(profile: ProfileRecord) {
        let user = AppUser.fromProfile(profile, followedOrgIDs: followedOrgIDs)
        currentUser = user
        pendingEmail = profile.email
        selectedYear = user.classYear
        selectedInterests = Set(profile.interests)
        onboardStep = 0
    }

    private func completeOnboarding() async {
        guard let profileService else {
            authError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }
        guard let user = currentUser else { return }
        guard let yearText = selectedYear, let classYear = Int(yearText) else {
            authError = "Choose a class year to continue."
            return
        }

        isCompletingOnboarding = true
        authError = nil
        defer { isCompletingOnboarding = false }

        do {
            let profile = try await profileService.completeOnboarding(
                userID: user.id,
                classYear: classYear,
                interests: Array(selectedInterests).sorted()
            )
            apply(profile: profile)
            if var updated = currentUser {
                updated.followedOrgIDs = followedOrgIDs
                currentUser = updated
            }
            phase = .main
            await catalog.refreshIfNeeded()
        } catch {
            authError = AuthUserFacingError.message(for: error)
        }
    }

    private func signedOut(to newPhase: AppPhase) {
        authGeneration += 1
        catalog.reset()
        currentUser = nil
        pendingEmail = ""
        isHandlingCallback = false
        isSigningIn = false
        isCompletingOnboarding = false
        onboardStep = 0
        selectedYear = nil
        selectedInterests = []
        followedOrgIDs = []
        savedEventIDs = []
        engagementError = nil
        phase = newPhase
    }

    private func loadEngagement() async throws {
        guard !isPreviewMode else { return }
        guard let engagementService else {
            throw SupabaseConfigError.missingConfiguration
        }

        async let follows = engagementService.fetchFollowedOrganizationIDs()
        async let saves = engagementService.fetchSavedEventIDs()
        let (followed, saved) = try await (follows, saves)
        followedOrgIDs = followed
        savedEventIDs = saved
        syncFollowedIDsToCurrentUser()
        engagementError = nil
    }

    private func persistFollow(_ orgID: UUID, shouldFollow: Bool) async {
        let generation = authGeneration
        guard let engagementService else {
            guard generation == authGeneration else { return }
            applyFollow(orgID, isFollowing: !shouldFollow)
            engagementError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }

        do {
            if shouldFollow {
                try await engagementService.follow(organizationID: orgID)
            } else {
                try await engagementService.unfollow(organizationID: orgID)
            }
            guard generation == authGeneration else { return }
            engagementError = nil
        } catch {
            guard generation == authGeneration else { return }
            applyFollow(orgID, isFollowing: !shouldFollow)
            engagementError = shouldFollow
                ? "Couldn't follow organization. Try again."
                : "Couldn't unfollow organization. Try again."
        }
    }

    private func persistSave(_ eventID: UUID, shouldSave: Bool) async {
        let generation = authGeneration
        guard let engagementService else {
            guard generation == authGeneration else { return }
            applySave(eventID, isSaved: !shouldSave)
            engagementError = SupabaseConfigError.missingConfiguration.localizedDescription
            return
        }

        do {
            if shouldSave {
                try await engagementService.save(eventID: eventID)
            } else {
                try await engagementService.unsave(eventID: eventID)
            }
            guard generation == authGeneration else { return }
            engagementError = nil
        } catch {
            guard generation == authGeneration else { return }
            applySave(eventID, isSaved: !shouldSave)
            engagementError = shouldSave
                ? "Couldn't save. Try again."
                : "Couldn't unsave. Try again."
        }
    }

    private func applyFollow(_ orgID: UUID, isFollowing: Bool) {
        if isFollowing {
            followedOrgIDs.insert(orgID)
        } else {
            followedOrgIDs.remove(orgID)
        }
        syncFollowedIDsToCurrentUser()
    }

    private func applySave(_ eventID: UUID, isSaved: Bool) {
        if isSaved {
            savedEventIDs.insert(eventID)
        } else {
            savedEventIDs.remove(eventID)
        }
    }

    private func syncFollowedIDsToCurrentUser() {
        if var user = currentUser {
            user.followedOrgIDs = followedOrgIDs
            currentUser = user
        }
    }
}

#if DEBUG
extension AppSession {
    static func preview() -> AppSession {
        let session = AppSession()
        session.isPreviewMode = true
        session.catalog.usePreviewData(
            organizations: MockData.organizations,
            events: MockData.events
        )
        let user = MockData.defaultUser()
        session.currentUser = user
        session.followedOrgIDs = user.followedOrgIDs
        session.savedEventIDs = [MockData.IDs.evt1]
        return session
    }
}
#endif
