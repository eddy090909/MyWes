//
//  SearchView.swift
//  MyWes
//

import SwiftUI

struct SearchView: View {
    @Environment(AppSession.self) private var session
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var catalogMatches: (events: [Event], organizations: [Organization]) {
        session.catalog.search(query: query)
    }

    @State private var questionResults: [CampusQuestion] = []
    @State private var questionError: String?
    @State private var searchingQuestions = false

    private var hasQuery: Bool {
        !trimmedQuery.isEmpty
    }

    private var hasResults: Bool {
        !catalogMatches.events.isEmpty || !catalogMatches.organizations.isEmpty || !questionResults.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchField

                if case .failed = session.catalog.status {
                    CampusRetry(message: "Couldn't load events and organizations.") { await session.catalog.refresh() }
                }
                if searchingQuestions { ProgressView("Searching AskWes…") }
                if let questionError { Text(questionError).font(Typography.bodySmall).foregroundStyle(.red) }
                searchResults
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle("Search")
        .scrollDismissesKeyboard(.interactively)
        .task(id: trimmedQuery) {
            questionResults = []
            questionError = nil
            guard hasQuery else { searchingQuestions = false; return }
            searchingQuestions = true
            do {
                try await Task.sleep(for: .milliseconds(250))
                let result = try await session.community.searchQuestions(trimmedQuery)
                try Task.checkCancellation()
                questionResults = result
                searchingQuestions = false
            } catch {
                guard !Task.isCancelled else { return }
                questionError = "Couldn't search AskWes. Change your search to retry."
                searchingQuestions = false
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private var searchField: some View {
        TextField("Search events, orgs, AskWes…", text: $query)
            .font(Typography.body)
            .foregroundStyle(Theme.ink)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isSearchFocused)
            .submitLabel(.search)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .accessibilityLabel("Search")
    }

    @ViewBuilder
    private var searchResults: some View {
        if !hasQuery {
            Text("Try “dining”, “internship”, or an org name.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.secondaryText)
                .padding(.top, 4)
        } else if hasResults {
            if !catalogMatches.events.isEmpty {
                searchSection(title: "Events") {
                    ForEach(catalogMatches.events) { event in
                        NavigationLink(value: AppRoute.event(event.id)) {
                            SearchResultRow(title: event.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !catalogMatches.organizations.isEmpty {
                searchSection(title: "Organizations") {
                    ForEach(catalogMatches.organizations) { organization in
                        NavigationLink(value: AppRoute.organization(organization.id)) {
                            SearchResultRow(title: organization.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !questionResults.isEmpty {
                searchSection(title: "AskWes") {
                    ForEach(questionResults) { question in
                        NavigationLink(value: AppRoute.question(question.id)) {
                            CampusQuestionRow(question: question)
                        }.buttonStyle(.plain)
                    }
                }
            }
        } else if !searchingQuestions && questionError == nil {
            Text("No results for “\(trimmedQuery)”")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.secondaryText)
                .padding(.top, 4)
        }
    }

    private func searchSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
            VStack(spacing: 8) {
                content()
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SearchView()
            .appDestinations()
    }
    .environment(AppSession.preview())
}
#endif
