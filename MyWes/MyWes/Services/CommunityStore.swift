import Foundation
import Observation
import Supabase

@Observable
final class CommunityStore {
    private(set) var questions: [CampusQuestion] = []
    private(set) var dining: [DiningVenue] = []
    private(set) var isLoading = false
    private(set) var questionError: String?
    private(set) var diningError: String?
    private var client: SupabaseClient?
    private var isPreview = false
    private var generation = 0

    init(client: SupabaseClient?) { self.client = client }

    #if DEBUG
    func disableNetworkForPreview() {
        client = nil
        isPreview = true
        reset()
    }
    #endif

    private func configuredClient() throws -> SupabaseClient {
        guard let client else { throw SupabaseConfigError.missingConfiguration }
        return client
    }

    func reset() {
        generation += 1
        questions = []
        dining = []
        questionError = nil
        diningError = nil
        isLoading = false
    }

    func refresh() async {
        guard !isLoading, !isPreview else { return }
        isLoading = true
        let token = generation
        async let q: () = loadQuestions(token: token)
        async let d: () = loadDining(token: token)
        _ = await (q, d)
        guard token == generation else { return }
        isLoading = false
    }

    private func loadQuestions(token: Int) async {
        do {
            let rows: [CampusQuestion] = try await configuredClient().from("questions")
                .select().order("created_at", ascending: false).limit(100).execute().value
            guard token == generation, !Task.isCancelled else { return }
            questions = rows
            questionError = nil
        } catch {
            guard token == generation, !Task.isCancelled else { return }
            questionError = "Couldn't load AskWes. Please retry."
        }
    }

    private func loadDining(token: Int) async {
        do {
            let rows: [DiningVenue] = try await configuredClient().from("dining_locations")
                .select().order("name").execute().value
            guard token == generation, !Task.isCancelled else { return }
            dining = rows
            diningError = nil
        } catch {
            guard token == generation, !Task.isCancelled else { return }
            diningError = "Couldn't load dining hours. Please retry."
        }
    }

    func searchQuestions(_ text: String) async throws -> [CampusQuestion] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        // Escape SQL LIKE wildcards so search text is literal.
        let escaped = needle.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        return try await configuredClient().from("questions").select()
            .ilike("title", pattern: "%\(escaped)%")
            .order("created_at", ascending: false).limit(100).execute().value
    }

    func question(id: UUID) async throws -> CampusQuestion {
        try await configuredClient().from("questions").select().eq("id", value: id)
            .single().execute().value
    }

    func answers(questionID: UUID) async throws -> [CampusAnswer] {
        try await configuredClient().from("answers").select().eq("question_id", value: questionID)
            .order("created_at").limit(100).execute().value
    }

    func postQuestion(title: String, body: String, topic: String) async throws -> CampusQuestion {
        let token = generation
        let row: CampusQuestion = try await configuredClient().from("questions")
            .insert(NewQuestion(title: title, body: body, topic: topic)).select().single().execute().value
        if token == generation { questions.insert(row, at: 0) }
        return row
    }

    func postAnswer(questionID: UUID, body: String) async throws -> CampusAnswer {
        try await configuredClient().from("answers")
            .insert(NewAnswer(questionId: questionID, body: body)).select().single().execute().value
    }

    func deleteQuestion(id: UUID) async throws {
        let token = generation
        try await configuredClient().from("questions").delete().eq("id", value: id).execute()
        if token == generation { questions.removeAll { $0.id == id } }
    }

    func deleteAnswer(id: UUID) async throws {
        try await configuredClient().from("answers").delete().eq("id", value: id).execute()
    }
}
