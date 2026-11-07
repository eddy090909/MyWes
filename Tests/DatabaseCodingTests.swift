import Foundation
import Darwin

@main struct DatabaseCodingTests {
    static func main() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        var failures: [String] = []
        var passed = 0
        func check(_ name: String, _ body: () throws -> Void) {
            do { try body(); passed += 1 } catch { failures.append("\(name): \(error)") }
        }
        func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
            try decoder.decode(type, from: Data(json.utf8))
        }
        func require(_ valid: Bool) throws {
            if !valid { throw NSError(domain: "DatabaseCodingTests", code: 1) }
        }
        func keys<T: Encodable>(_ value: T) throws -> Set<String> {
            let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
            return Set(object.keys)
        }
        check("profile response") {
            let row = try decode(ProfileRecord.self, """
            {"id":"\(id)","email":"student@wesleyan.edu","full_name":"Test Student","class_year":2028,"interests":["Music"],"onboarding_completed":true}
            """)
            try require(row.onboardingCompleted && row.classYear == 2028 && row.fullName == "Test Student")
        }
        check("event response") {
            let row = try decode(EventRecord.self, """
            {"id":"\(id)","org_id":"\(id)","title":"Test","category":"Social","description":"Details","location":"Campus","start_at":"2026-11-07T18:00:00Z","end_at":null}
            """)
            try require(row.orgId.uuidString.lowercased() == id)
        }
        check("organization response") {
            let row = try decode(OrganizationRecord.self, """
            {"id":"\(id)","name":"Test","category":"Social","description":"Details","member_count":12,"contact_email":"org@wesleyan.edu","instagram_handle":"test"}
            """)
            try require(row.memberCount == 12 && row.contactEmail == "org@wesleyan.edu")
        }
        check("question response") {
            _ = try decode(CampusQuestion.self, """
            {"id":"\(id)","author_id":"\(id)","title":"Question","body":"Details","topic":"Dining","created_at":"2026-11-07T18:00:00Z"}
            """)
        }
        check("answer response") {
            _ = try decode(CampusAnswer.self, """
            {"id":"\(id)","question_id":"\(id)","author_id":"\(id)","body":"Details","created_at":"2026-11-07T18:00:00Z"}
            """)
        }
        check("dining response") {
            let row = try decode(DiningVenue.self, """
            {"id":"\(id)","name":"Test","location":"Campus","weekly_hours":[[],[],[],[],[],[],[]],"notes":"","source_url":"https://www.wesleyan.edu/dining/","verified_on":"2026-11-07","valid_through":"2026-11-20"}
            """)
            try require(row.weeklyHours.count == 7 && row.validThrough == "2026-11-20")
        }
        check("onboarding request") {
            try require(keys(ProfileOnboardingUpdate(classYear: 2028, interests: [], onboardingCompleted: true)) == ["class_year","interests","onboarding_completed"])
        }
        check("profile edit request") {
            try require(keys(ProfileEdit(fullName: "Test", classYear: 2028, interests: [])) == ["full_name","class_year","interests"])
        }
        check("answer request") {
            try require(keys(NewAnswer(questionId: UUID(uuidString: id)!, body: "Answer")) == ["question_id","body"])
        }
        check("question request") {
            try require(keys(NewQuestion(title: "Question", body: "Details", topic: "Dining")) == ["title","body","topic"])
        }
        for failure in failures { print("FAIL \(failure)") }
        print("Database coding checks: \(passed) passed, \(failures.count) failed")
        if !failures.isEmpty { exit(1) }
    }
}
