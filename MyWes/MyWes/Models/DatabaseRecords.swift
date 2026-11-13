import Foundation

// Wire formats shared by the Supabase services and coding regression tests.

nonisolated struct ProfileRecord: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case classYear = "class_year"
        case interests
        case onboardingCompleted = "onboarding_completed"
    }

    var id: UUID
    var email: String
    var fullName: String?
    var classYear: Int?
    var interests: [String]
    var onboardingCompleted: Bool
}

nonisolated struct ProfileOnboardingUpdate: Encodable {
    enum CodingKeys: String, CodingKey {
        case classYear = "class_year"
        case interests
        case onboardingCompleted = "onboarding_completed"
    }

    var classYear: Int
    var interests: [String]
    var onboardingCompleted: Bool
}

nonisolated struct ProfileEdit: Encodable {
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case classYear = "class_year"
        case interests
    }

    var fullName: String
    var classYear: Int
    var interests: [String]
}

nonisolated struct EventRecord: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case title
        case category
        case description
        case location
        case startAt = "start_at"
        case endAt = "end_at"
        case isAllDay = "is_all_day"
        case sourceUrl = "source_url"
    }

    var id: UUID
    var orgId: UUID
    var title: String
    var category: String
    var description: String
    var location: String
    var startAt: Date
    var endAt: Date?
    var isAllDay: Bool = false
    var sourceUrl: String? = nil

    init(id: UUID, orgId: UUID, title: String, category: String, description: String, location: String,
         startAt: Date, endAt: Date?, isAllDay: Bool = false, sourceUrl: String? = nil) {
        self.id = id
        self.orgId = orgId
        self.title = title
        self.category = category
        self.description = description
        self.location = location
        self.startAt = startAt
        self.endAt = endAt
        self.isAllDay = isAllDay
        self.sourceUrl = sourceUrl
    }

    // Calendar columns are optional so rows from before that migration decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        orgId = try c.decode(UUID.self, forKey: .orgId)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(String.self, forKey: .category)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        location = try c.decode(String.self, forKey: .location)
        startAt = try c.decode(Date.self, forKey: .startAt)
        endAt = try c.decodeIfPresent(Date.self, forKey: .endAt)
        isAllDay = try c.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? false
        sourceUrl = try c.decodeIfPresent(String.self, forKey: .sourceUrl)
    }
}

nonisolated struct OrganizationRecord: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case memberCount = "member_count"
        case contactEmail = "contact_email"
        case instagramHandle = "instagram_handle"
    }

    var id: UUID
    var name: String
    var category: String
    var description: String
    var memberCount: Int
    var contactEmail: String?
    var instagramHandle: String?
}

nonisolated struct NewQuestion: Encodable {
    let title: String
    let body: String
    let topic: String
}

nonisolated struct NewAnswer: Encodable {
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case body
    }

    let questionId: UUID
    let body: String
}
