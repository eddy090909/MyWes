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

struct CampusQuestionRow: View {
    let question: CampusQuestion
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.title).font(.headline).foregroundStyle(Theme.ink)
            Text(question.topic).font(Typography.caption).foregroundStyle(Theme.cardinal)
            Text(question.body).font(Typography.bodySmall).foregroundStyle(Theme.secondaryText).lineLimit(2)
            Text(question.createdAt, style: .date).font(Typography.caption).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
        .contentShape(Rectangle())
    }
}

struct AskWesView: View {
    @Environment(AppSession.self) private var session
    @State private var composing = false
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.listGap) {
                if let error = session.community.questionError {
                    CampusRetry(message: error) { await session.community.refresh() }
                }
                if session.community.isLoading { ProgressView() }
                if session.community.questions.isEmpty && !session.community.isLoading && session.community.questionError == nil {
                    Text("No questions yet. Start a conversation with your campus.")
                        .foregroundStyle(Theme.secondaryText).padding()
                }
                ForEach(session.community.questions) { question in
                    NavigationLink(value: AppRoute.question(question.id)) {
                        CampusQuestionRow(question: question)
                    }.buttonStyle(.plain)
                }
                if session.community.questions.count == 100 {
                    NavigationLink("Search older questions", value: AppRoute.search)
                }
            }.padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("AskWes")
        .toolbar { Button("Ask a question", systemImage: "square.and.pencil") { composing = true } }
        .sheet(isPresented: $composing) { QuestionComposer() }
        .task { await session.community.refresh() }
        .refreshable { await session.community.refresh() }
    }
}

struct QuestionComposer: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var topic = "Campus life"
    @State private var posting = false
    @State private var error: String?
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedBody: String { bodyText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool { (5...180).contains(trimmedTitle.count) && (1...5000).contains(trimmedBody.count) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Title (5–180 characters)", text: $title)
                    Picker("Topic", selection: $topic) {
                        ForEach(["Campus life", "Academics", "Dining", "Housing", "Events"], id: \.self) { Text($0) }
                    }
                    TextField("Details", text: $bodyText, axis: .vertical).lineLimit(5...12)
                }
                Text("Visible to signed-in Wesleyan students. Your email is never displayed.")
                    .font(Typography.caption)
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Ask a question")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(posting) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(posting ? "Posting…" : "Post") {
                        Task {
                            posting = true
                            error = nil
                            defer { posting = false }
                            do {
                                _ = try await session.community.postQuestion(title: trimmedTitle, body: trimmedBody, topic: topic)
                                dismiss()
                            } catch { self.error = "Couldn't post. Your draft is preserved; please retry." }
                        }
                    }.disabled(!valid || posting)
                }
            }
            .interactiveDismissDisabled(posting)
        }.tint(Theme.cardinal)
    }
}

struct QuestionDetailView: View {
    let questionID: UUID
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var question: CampusQuestion?
    @State private var answers: [CampusAnswer] = []
    @State private var reply = ""
    @State private var error: String?
    @State private var loading = true
    @State private var busy = false
    @State private var deletingQuestion = false
    @State private var deletingAnswer: UUID?
    @State private var showingAnswerDeletion = false

    var body: some View {
        ScrollView {
            detailContent
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("AskWes").navigationBarTitleDisplayMode(.inline)
        .task { await load() }.refreshable { await load() }
        .confirmationDialog("Delete this question and its answers?", isPresented: $deletingQuestion, titleVisibility: .visible) {
            Button("Delete question", role: .destructive) {
                Task {
                    busy = true
                    defer { busy = false }
                    do { try await session.community.deleteQuestion(id: questionID); dismiss() }
                    catch { self.error = "Couldn't delete the question. Please retry." }
                }
            }
        }
        .confirmationDialog("Delete your answer?", isPresented: $showingAnswerDeletion, titleVisibility: .visible, presenting: deletingAnswer) { id in
            Button("Delete answer", role: .destructive) {
                Task {
                    busy = true
                    defer { busy = false; deletingAnswer = nil }
                    do {
                        try await session.community.deleteAnswer(id: id)
                        answers.removeAll { $0.id == id }
                        error = nil
                    } catch { self.error = "Couldn't delete the answer. Please retry." }
                }
            }
        }
    }

    private var detailContent: some View {
            VStack(alignment: .leading, spacing: 16) {
                if loading { ProgressView() }
                if let error { CampusRetry(message: error) { await load() } }
                if let question {
                    Text(question.topic.uppercased()).font(Typography.eyebrow).foregroundStyle(Theme.cardinal)
                    Text(question.title).font(.title2.bold())
                    Text(question.body).font(Typography.body).textSelection(.enabled)
                    Text(question.createdAt, style: .date).font(Typography.caption).foregroundStyle(Theme.secondaryText)
                    if question.authorId == session.currentUser?.id {
                        Button("Delete question", role: .destructive) { deletingQuestion = true }.disabled(busy)
                    }
                    Divider()
                    Text("Answers").font(.headline)
                    if answers.isEmpty { Text("No answers yet.").foregroundStyle(Theme.secondaryText) }
                    ForEach(answers) { answer in answerCard(answer) }
                    if answers.count == 100 { Text("Showing the first 100 answers.").font(Typography.caption) }
                    TextField("Write an answer (up to 5,000 characters)", text: $reply, axis: .vertical)
                        .lineLimit(3...10).textFieldStyle(.roundedBorder)
                    Button(busy ? "Saving…" : "Post answer") { Task { await postAnswer() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(busy || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reply.count > 5000)
                }
            }.padding(Theme.screenPadding)
    }

    private func answerCard(_ answer: CampusAnswer) -> some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(answer.authorId == session.currentUser?.id ? "You" : "Wesleyan student")
                                .font(.subheadline.bold())
                            Text(answer.body).textSelection(.enabled)
                            Text(answer.createdAt, style: .date).font(Typography.caption)
                            if answer.authorId == session.currentUser?.id {
                                Button("Delete answer", role: .destructive) {
                                    deletingAnswer = answer.id
                                    showingAnswerDeletion = true
                                }.disabled(busy)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            async let q = session.community.question(id: questionID)
            async let a = session.community.answers(questionID: questionID)
            let result = try await (q, a)
            guard !Task.isCancelled else { return }
            question = result.0
            answers = result.1
            error = nil
        } catch {
            guard !Task.isCancelled else { return }
            self.error = "Couldn't load this question. It may have been removed."
        }
    }

    private func postAnswer() async {
        busy = true
        defer { busy = false }
        do {
            let answer = try await session.community.postAnswer(questionID: questionID, body: reply.trimmingCharacters(in: .whitespacesAndNewlines))
            answers.append(answer)
            reply = ""
            error = nil
        } catch { self.error = "Couldn't post your answer. Your draft is preserved." }
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
