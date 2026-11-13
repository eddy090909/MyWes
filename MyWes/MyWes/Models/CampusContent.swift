import Foundation

nonisolated struct CampusQuestion: Codable, Identifiable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case title
        case body
        case topic
        case createdAt = "created_at"
    }

    var id: UUID
    var authorId: UUID
    var title: String
    var body: String
    var topic: String
    var createdAt: Date
}

nonisolated struct CampusAnswer: Codable, Identifiable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case authorId = "author_id"
        case body
        case createdAt = "created_at"
    }

    var id: UUID
    var questionId: UUID
    var authorId: UUID
    var body: String
    var createdAt: Date
}

nonisolated struct DiningPeriod: Codable, Equatable, Sendable {
    var start: Int
    var end: Int

    var label: String { "\(Self.clock(start)) – \(Self.clock(end))" }

    static func clock(_ minutes: Int) -> String {
        let hour = (minutes / 60) % 24
        return "\(hour % 12 == 0 ? 12 : hour % 12):\(String(format: "%02d", minutes % 60)) \(hour < 12 ? "AM" : "PM")"
    }
}

nonisolated struct DiningVenue: Codable, Identifiable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case weeklyHours = "weekly_hours"
        case specialHours = "special_hours"
        case notes
        case sourceUrl = "source_url"
        case menuSlug = "menu_slug"
        case sortOrder = "sort_order"
        case operatorKind = "operator"
        case menuUrl = "menu_url"
        case specialsSource = "specials_source"
        case hoursPublished = "hours_published"
        case verifiedOn = "verified_on"
        case validThrough = "valid_through"
    }

    var id: UUID
    var name: String
    var location: String
    var weeklyHours: [[DiningPeriod]]
    var notes: String
    var sourceUrl: String
    var verifiedOn: String
    var validThrough: String
    /// Date-specific hours ("YYYY-MM-DD" in campus time) that replace the
    /// regular weekly schedule, e.g. Thanksgiving break. Empty array = closed.
    var specialHours: [String: [DiningPeriod]] = [:]
    /// Bon Appétit cafe slug, e.g. "summerfields". Nil when no menu is published.
    var menuSlug: String?
    var sortOrder: Int = 100
    /// "bon_appetit" or "independent" (prices and hours set by the restaurant).
    var operatorKind: String = "bon_appetit"
    /// Official menu page for locations without a Bon Appétit feed.
    var menuUrl: String?
    /// "weswings" or "red_black_cafe": daily specials posted on weswings.com.
    var specialsSource: String?
    /// False when the location publishes no hours we can verify.
    var hoursPublished: Bool = true

    init(id: UUID, name: String, location: String, weeklyHours: [[DiningPeriod]], notes: String,
         sourceUrl: String, verifiedOn: String, validThrough: String,
         specialHours: [String: [DiningPeriod]] = [:], menuSlug: String? = nil, sortOrder: Int = 100,
         operatorKind: String = "bon_appetit", menuUrl: String? = nil, specialsSource: String? = nil,
         hoursPublished: Bool = true) {
        self.id = id
        self.name = name
        self.location = location
        self.weeklyHours = weeklyHours
        self.notes = notes
        self.sourceUrl = sourceUrl
        self.verifiedOn = verifiedOn
        self.validThrough = validThrough
        self.specialHours = specialHours
        self.menuSlug = menuSlug ?? Self.legacyMenuSlug(for: name)
        self.sortOrder = sortOrder
        self.operatorKind = operatorKind
        self.menuUrl = menuUrl
        self.specialsSource = specialsSource
        self.hoursPublished = hoursPublished
    }

    // Newer columns are optional so the app still decodes rows from a
    // database that hasn't applied the dining expansion migration yet.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            location: try c.decode(String.self, forKey: .location),
            weeklyHours: try c.decode([[DiningPeriod]].self, forKey: .weeklyHours),
            notes: try c.decodeIfPresent(String.self, forKey: .notes) ?? "",
            sourceUrl: try c.decode(String.self, forKey: .sourceUrl),
            verifiedOn: try c.decode(String.self, forKey: .verifiedOn),
            validThrough: try c.decode(String.self, forKey: .validThrough),
            specialHours: try c.decodeIfPresent([String: [DiningPeriod]].self, forKey: .specialHours) ?? [:],
            menuSlug: try c.decodeIfPresent(String.self, forKey: .menuSlug),
            sortOrder: try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 100,
            operatorKind: try c.decodeIfPresent(String.self, forKey: .operatorKind) ?? "bon_appetit",
            menuUrl: try c.decodeIfPresent(String.self, forKey: .menuUrl),
            specialsSource: try c.decodeIfPresent(String.self, forKey: .specialsSource),
            hoursPublished: try c.decodeIfPresent(Bool.self, forKey: .hoursPublished) ?? true
        )
    }

    private static func legacyMenuSlug(for name: String) -> String? {
        switch name {
        case "Usdan Marketplace": "the-marketplace-at-usdan"
        case "Summerfields": "summerfields"
        case "Usdan Café": "usdan-cafe"
        default: nil
        }
    }

    /// Only plain Bon Appétit slugs are turned into URLs.
    var menuURLSlug: String? {
        guard let menuSlug, !menuSlug.isEmpty,
              menuSlug.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }) else { return nil }
        return menuSlug
    }

    var isIndependent: Bool { operatorKind == "independent" }

    /// Official menu link, HTTPS only.
    var officialMenuURL: URL? {
        guard let menuUrl, let url = URL(string: menuUrl), url.scheme == "https", url.host != nil else { return nil }
        return url
    }

    var specialsFeed: WesWingsSpecials.Source? { specialsSource.flatMap(WesWingsSpecials.Source.init(rawValue:)) }

    /// Whether MyWes can show menu content itself (a full menu or posted specials).
    var hasInAppMenu: Bool { menuURLSlug != nil || specialsFeed != nil }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    static func dateKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    func hasCurrentSchedule(at date: Date) -> Bool {
        let key = Self.dateKey(date)
        return hoursPublished && weeklyHours.count == 7 && key >= verifiedOn && key <= validThrough
    }

    /// Service periods that open on this campus day, honoring special hours.
    func periods(on date: Date) -> [DiningPeriod]? {
        guard weeklyHours.count == 7 else { return nil }
        if let special = specialHours[Self.dateKey(date)] { return special }
        return weeklyHours[Self.calendar.component(.weekday, from: date) - 1]
    }

    func hasSpecialHours(on date: Date) -> Bool {
        specialHours[Self.dateKey(date)] != nil
    }

    func hours(on date: Date) -> String {
        guard hoursPublished else { return "Hours not published" }
        guard let periods = periods(on: date) else { return "Hours unavailable" }
        if periods.isEmpty { return hasSpecialHours(on: date) ? "Closed today" : "Regularly closed" }
        return periods.map(\.label).joined(separator: " · ")
    }

    // Use campus time even when the device is elsewhere. Check yesterday's
    // service too: a 9:30 PM–1 AM period belongs to its opening day.
    func scheduledOpen(at date: Date) -> Bool? {
        guard hasCurrentSchedule(at: date), let todayPeriods = periods(on: date) else { return nil }
        let calendar = Self.calendar
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let today = todayPeriods.contains { minute >= $0.start && minute < $0.end }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        let overnight = hasCurrentSchedule(at: yesterday) && (periods(on: yesterday) ?? []).contains {
            $0.end > 1440 && minute + 1440 >= $0.start && minute + 1440 < $0.end
        }
        return today || overnight
    }

    /// A short status such as "Open until 8:00 PM" or "Opens at 5:00 PM".
    func statusDetail(at date: Date) -> String? {
        guard let open = scheduledOpen(at: date), let todayPeriods = periods(on: date) else { return nil }
        let calendar = Self.calendar
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        if open {
            if let current = todayPeriods.first(where: { minute >= $0.start && minute < $0.end }) {
                return "Open until \(DiningPeriod.clock(current.end))"
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
            if let late = (periods(on: yesterday) ?? []).first(where: { $0.end > 1440 && minute + 1440 < $0.end }) {
                return "Open until \(DiningPeriod.clock(late.end))"
            }
            return "Open now"
        }
        if let next = todayPeriods.filter({ $0.start > minute }).min(by: { $0.start < $1.start }) {
            return "Opens at \(DiningPeriod.clock(next.start))"
        }
        return "Closed for the day"
    }
}
