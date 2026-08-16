//
//  SearchView.swift
//  MyWes
//

import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: (events: [Event], organizations: [Organization], questions: [Question]) {
        MockData.search(query: query)
    }

    private var hasQuery: Bool {
        !trimmedQuery.isEmpty
    }

    private var hasResults: Bool {
        !results.events.isEmpty || !results.organizations.isEmpty || !results.questions.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchField

                if !hasQuery {
                    Text("Try “dining”, “internship”, or an org name.")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.top, 4)
                } else if hasResults {
                    if !results.events.isEmpty {
                        searchSection(title: "Events") {
                            ForEach(results.events) { event in
                                NavigationLink(value: AppRoute.event(event.id)) {
                                    SearchResultRow(title: event.title)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !results.organizations.isEmpty {
                        searchSection(title: "Organizations") {
                            ForEach(results.organizations) { organization in
                                NavigationLink(value: AppRoute.organization(organization.id)) {
                                    SearchResultRow(title: organization.name)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !results.questions.isEmpty {
                        searchSection(title: "AskWes") {
                            ForEach(results.questions) { question in
                                SearchQuestionRow(question: question)
                            }
                        }
                    }
                } else {
                    Text("No results for “\(trimmedQuery)”")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.top, 4)
                }
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

private struct SearchQuestionRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("\(question.topic)")
                .font(Typography.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.background)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.border)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border.opacity(0.7), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel("\(question.title), \(question.topic), AskWes result")
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .appDestinations()
    }
    .environment(AppSession())
}
