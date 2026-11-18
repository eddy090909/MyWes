import SwiftUI

struct CampusRetry: View {
    let message: String
    let retry: () async -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text(message).foregroundStyle(Theme.secondaryText)
            Button("Retry") { Task { await retry() } }
        }
        .frame(maxWidth: .infinity).padding()
    }
}

struct ProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var name = ""
    @State private var year = ""
    @State private var interests = ""
    @State private var status: String?
    @State private var signingOut = false
    var body: some View {
        Form {
            Section("Wesleyan account") {
                Text(session.currentUser?.email ?? "")
                TextField("Full name", text: $name).textContentType(.name)
                TextField("Class year", text: $year).keyboardType(.numberPad)
                TextField("Interests, separated by commas", text: $interests, axis: .vertical)
            }
            Section {
                Button(session.isSavingProfile ? "Saving…" : "Save profile") {
                    Task {
                        status = nil
                        do {
                            try await session.saveProfile(name: name, year: year, interests: interests)
                            status = "Profile saved."
                        } catch { status = (error as? ProfileEditError)?.localizedDescription ?? "Couldn't save your profile. Please retry." }
                    }
                }.disabled(session.isSavingProfile || signingOut)
                if let status { Text(status).font(Typography.bodySmall) }
            }
            Section("Your campus") {
                NavigationLink("Saved events", value: AppRoute.savedEvents)
                ForEach(session.catalog.organizations.filter { session.isFollowing($0.id) }) { org in
                    NavigationLink(org.name, value: AppRoute.organization(org.id))
                }
                if session.followedOrgIDs.isEmpty { Text("No followed organizations yet.") }
            }
            Section {
                Button(signingOut ? "Signing out…" : "Sign out", role: .destructive) {
                    signingOut = true
                    Task { await session.signOut(); signingOut = false }
                }.disabled(signingOut || session.isSavingProfile)
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            name = session.profileName
            year = session.currentUser?.classYear ?? ""
            interests = session.currentUser?.interests.joined(separator: ", ") ?? ""
        }
    }
}
