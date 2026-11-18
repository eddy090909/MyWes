//
//  AskWesViews.swift
//  MyWes
//

import SwiftUI

// MARK: - Shared pieces

/// Topic pill shared by AskWes rows, details, and the composer.
struct QuestionTopicTag: View {
    let topic: String

    var body: some View {
        Text(topic)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.cardinal)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.savedBannerBackground)
            .clipShape(Capsule())
    }
}

struct CampusQuestionRow: View {
    let question: CampusQuestion
    @Environment(AppSession.self) private var session

    private var isMine: Bool { question.authorId == session.currentUser?.id }
    private var answers: Int { question.answerCount ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                QuestionTopicTag(topic: question.topic)
                if isMine {
                    Text("Your question")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer(minLength: 0)
                Text(question.createdAt, format: .relative(presentation: .named))
                    .font(Typography.caption).foregroundStyle(Theme.secondaryText)
            }
            Text(question.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
            Text(question.body)
                .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
                .lineLimit(2).multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                Image(systemName: answers == 0 ? "bubble.left" : "bubble.left.and.bubble.right.fill")
                Text(answers == 0 ? "No answers yet" : "\(answers) answer\(answers == 1 ? "" : "s")")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(answers == 0 ? Theme.cardinal : Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - AskWes tab

struct AskWesView: View {
    @Environment(AppSession.self) private var session
    @State private var composing = false
    @State private var topic: String?
    @State private var searchText = ""
    @State private var searchResults: [CampusQuestion]?
    @State private var searching = false
    @State private var searchFailed = false

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Search results when searching, otherwise the latest questions; then topic filter.
    private var visibleQuestions: [CampusQuestion] {
        let base = query.isEmpty ? session.community.questions : (searchResults ?? [])
        guard let topic else { return base }
        return base.filter { $0.topic == topic }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.listGap) {
                if query.isEmpty {
                    intro
                }
                topicChips
                    .padding(.bottom, 4)
                content
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("AskWes")
        .searchable(text: $searchText, prompt: "Search questions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Ask a question", systemImage: "square.and.pencil") { composing = true }
            }
        }
        .sheet(isPresented: $composing) { QuestionComposer(initialTopic: topic) }
        .task { await session.community.refresh() }
        .refreshable { await session.community.refresh(force: true) }
        .task(id: query) { await search() }
    }

    private var intro: some View {
        Button { composing = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.cardinal)
                    .frame(width: 44, height: 44)
                    .background(Theme.savedBannerBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("What do you want to know?")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                    Text("Ask Wesleyan students about majors, classes, housing, and life after Wes.")
                        .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.secondaryText)
            }
            .padding(14)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .accessibilityLabel("Ask a question")
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: topic == nil) { topic = nil }
                ForEach(CampusQuestion.topics, id: \.self) { option in
                    FilterChip(title: option, isSelected: topic == option) { topic = option }
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        if !query.isEmpty {
            if searching && searchResults == nil {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
            } else if searchFailed {
                CampusRetry(message: "Search didn’t go through.") { await search() }
            } else if visibleQuestions.isEmpty {
                emptyMessage("No questions match “\(query)”.", action: "Ask it yourself")
            }
        } else if let error = session.community.questionError, session.community.questions.isEmpty {
            CampusRetry(message: error) { await session.community.refresh(force: true) }
        } else if !session.community.hasLoaded && session.community.questions.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 32)
        } else if visibleQuestions.isEmpty {
            if let topic {
                emptyMessage("No \(topic.lowercased()) questions yet.", action: "Ask the first one")
            } else {
                emptyMessage("No questions yet. Start a conversation with your campus.", action: "Ask the first question")
            }
        }

        ForEach(visibleQuestions) { question in
            NavigationLink(value: AppRoute.question(question.id)) {
                CampusQuestionRow(question: question)
            }
            .buttonStyle(.plain)
        }

        if query.isEmpty && session.community.questions.count == 100 {
            Text("Showing the 100 newest questions. Search to find older ones.")
                .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                .padding(.top, 8)
        }
    }

    private func emptyMessage(_ text: String, action: String) -> some View {
        VStack(spacing: 12) {
            Text(text).font(Typography.body).foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button(action) { composing = true }
                .buttonStyle(.borderedProminent).tint(Theme.cardinal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func search() async {
        let text = query
        guard text.count >= 2 else {
            searchResults = nil
            searchFailed = false
            return
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        searching = true
        defer { searching = false }
        do {
            let rows = try await session.community.searchQuestions(text)
            guard !Task.isCancelled, text == query else { return }
            searchResults = rows
            searchFailed = false
        } catch {
            guard !Task.isCancelled else { return }
            searchFailed = true
        }
    }
}

// MARK: - Composer

struct QuestionComposer: View {
    var initialTopic: String?
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var topic = "Campus life"
    @State private var posting = false
    @State private var error: String?
    @FocusState private var titleFocused: Bool

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedBody: String { bodyText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool { (5...180).contains(trimmedTitle.count) && (1...5000).contains(trimmedBody.count) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your question", text: $title, axis: .vertical)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1...3)
                        .focused($titleFocused)
                } header: {
                    Text("Question")
                } footer: {
                    Text(trimmedTitle.count < 5 ? "At least 5 characters" : "\(trimmedTitle.count)/180")
                        .foregroundStyle(trimmedTitle.count > 180 ? .red : Theme.secondaryText)
                }

                Section("Topic") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CampusQuestion.topics, id: \.self) { option in
                                FilterChip(title: option, isSelected: topic == option) { topic = option }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }

                Section {
                    TextField("Add details so people can give useful answers", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Visible to signed-in Wesleyan students. Your name and email are never shown. Be kind, and don’t share anyone’s private information.")
                }

                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Ask AskWes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(posting) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(posting ? "Posting…" : "Post") { Task { await post() } }
                        .fontWeight(.bold)
                        .disabled(!valid || posting)
                }
            }
            .interactiveDismissDisabled(posting || !trimmedTitle.isEmpty || !trimmedBody.isEmpty)
            .onAppear {
                if let initialTopic, CampusQuestion.topics.contains(initialTopic) { topic = initialTopic }
                titleFocused = true
            }
        }
        .tint(Theme.cardinal)
    }

    private func post() async {
        posting = true
        error = nil
        defer { posting = false }
        do {
            _ = try await session.community.postQuestion(title: trimmedTitle, body: trimmedBody, topic: topic)
            dismiss()
        } catch {
            self.error = "Couldn’t post. Your draft is saved here; please try again."
        }
    }
}

// MARK: - Question detail

struct QuestionDetailView: View {
    let questionID: UUID
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var question: CampusQuestion?
    @State private var answers: [CampusAnswer] = []
    @State private var reply = ""
    @State private var error: String?
    @State private var actionError: String?
    @State private var loading = true
    @State private var busy = false
    @State private var deletingQuestion = false
    @State private var deletingAnswer: UUID?
    @State private var showingAnswerDeletion = false
    @FocusState private var replyFocused: Bool

    private var trimmedReply: String { reply.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading && question == nil {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
                } else if let error, question == nil {
                    CampusRetry(message: error) { await load() }
                }
                if let question {
                    questionHeader(question)
                    Divider()
                    answersSection(question)
                }
            }
            .padding(Theme.screenPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("AskWes").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let question, question.authorId == session.currentUser?.id {
                    Menu {
                        Button("Delete question", systemImage: "trash", role: .destructive) { deletingQuestion = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(busy)
                    .accessibilityLabel("Question options")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if question != nil { replyBar }
        }
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog("Delete this question and its answers?", isPresented: $deletingQuestion, titleVisibility: .visible) {
            Button("Delete question", role: .destructive) {
                Task {
                    busy = true
                    defer { busy = false }
                    do { try await session.community.deleteQuestion(id: questionID); dismiss() }
                    catch { actionError = "Couldn’t delete the question. Please try again." }
                }
            }
        }
        .confirmationDialog("Delete your answer?", isPresented: $showingAnswerDeletion, titleVisibility: .visible, presenting: deletingAnswer) { id in
            Button("Delete answer", role: .destructive) {
                Task {
                    busy = true
                    defer { busy = false; deletingAnswer = nil }
                    do {
                        try await session.community.deleteAnswer(id: id, questionID: questionID)
                        withAnimation { answers.removeAll { $0.id == id } }
                        actionError = nil
                    } catch { actionError = "Couldn’t delete the answer. Please try again." }
                }
            }
        }
    }

    private func questionHeader(_ question: CampusQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            QuestionTopicTag(topic: question.topic)
            Text(question.title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text(question.body)
                .font(Typography.body)
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(3)
                .textSelection(.enabled)
            HStack(spacing: 4) {
                Text(question.authorId == session.currentUser?.id ? "Asked by you" : "Asked by a Wesleyan student")
                Text("·")
                Text(question.createdAt, format: .relative(presentation: .named))
            }
            .font(Typography.caption).foregroundStyle(Theme.secondaryText)
        }
    }

    private func answersSection(_ question: CampusQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(answers.isEmpty ? "Answers" : "\(answers.count) answer\(answers.count == 1 ? "" : "s")")
                .font(Typography.sectionTitle).foregroundStyle(Theme.ink)
            if answers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No answers yet.").font(Typography.bodyEmphasized).foregroundStyle(Theme.ink)
                    Text("Know something that would help? Answer below. Your name stays hidden.")
                        .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
                }
                .padding(.vertical, 4)
            }
            ForEach(answers) { answer in answerCard(answer, question: question) }
            if answers.count == 100 {
                Text("Showing the first 100 answers.").font(Typography.caption).foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func answerCard(_ answer: CampusAnswer, question: CampusQuestion) -> some View {
        let mine = answer.authorId == session.currentUser?.id
        let byAsker = answer.authorId == question.authorId
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(mine ? Theme.cardinal : Theme.border)
                Text(mine ? "You" : (byAsker ? "Asker" : "Wesleyan student"))
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                Text(answer.createdAt, format: .relative(presentation: .named))
                    .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 0)
                if mine {
                    Menu {
                        Button("Delete answer", systemImage: "trash", role: .destructive) {
                            deletingAnswer = answer.id
                            showingAnswerDeletion = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 28, height: 28)
                    }
                    .disabled(busy)
                    .accessibilityLabel("Answer options")
                }
            }
            Text(answer.body)
                .font(Typography.body).foregroundStyle(Theme.ink)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(mine ? Theme.savedBannerBackground.opacity(0.35) : Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
    }

    private var replyBar: some View {
        VStack(spacing: 6) {
            if let actionError {
                Text(actionError)
                    .font(Typography.caption).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if reply.count > 4500 {
                Text("\(reply.count)/5,000")
                    .font(Typography.caption)
                    .foregroundStyle(reply.count > 5000 ? .red : Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Write an answer", text: $reply, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($replyFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.border))
                Button {
                    Task { await postAnswer() }
                } label: {
                    Image(systemName: busy ? "ellipsis" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(trimmedReply.isEmpty || reply.count > 5000 ? Theme.border : Theme.cardinal)
                        .clipShape(Circle())
                }
                .disabled(busy || trimmedReply.isEmpty || reply.count > 5000)
                .accessibilityLabel("Post answer")
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 10)
        .background(.bar)
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
            if question == nil { self.error = "Couldn’t load this question. It may have been removed." }
        }
    }

    private func postAnswer() async {
        busy = true
        defer { busy = false }
        do {
            let answer = try await session.community.postAnswer(questionID: questionID, body: trimmedReply)
            withAnimation { answers.append(answer) }
            reply = ""
            replyFocused = false
            actionError = nil
        } catch {
            actionError = "Couldn’t post your answer. Your draft is still in the box."
        }
    }
}
