import Foundation

nonisolated struct CampusQuestion: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var authorId: UUID
    var title: String
    var body: String
    var topic: String
    var createdAt: Date
}

nonisolated struct CampusAnswer: Codable, Identifiable, Equatable, Sendable {
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

    private static func clock(_ minutes: Int) -> String {
        let hour = (minutes / 60) % 24
        return "\(hour % 12 == 0 ? 12 : hour % 12):\(String(format: "%02d", minutes % 60)) \(hour < 12 ? "AM" : "PM")"
    }
}

nonisolated struct DiningVenue: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var location: String
    var weeklyHours: [[DiningPeriod]]
    var notes: String
    var sourceUrl: String
    var verifiedOn: String
    var validThrough: String

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private static func dateKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    func hasCurrentSchedule(at date: Date) -> Bool {
        let key = Self.dateKey(date)
        return weeklyHours.count == 7 && key >= verifiedOn && key <= validThrough
    }

    func hours(on date: Date) -> String {
        guard weeklyHours.count == 7 else { return "Hours unavailable" }
        let periods = weeklyHours[Self.calendar.component(.weekday, from: date) - 1]
        return periods.isEmpty ? "Regularly closed" : periods.map(\.label).joined(separator: " · ")
    }

    // Use campus time even when the device is elsewhere. Check yesterday's
    // service too: a 9:30 PM–1 AM period belongs to its opening day.
    func scheduledOpen(at date: Date) -> Bool? {
        guard hasCurrentSchedule(at: date) else { return nil }
        let calendar = Self.calendar
        let weekday = calendar.component(.weekday, from: date) - 1
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let today = weeklyHours[weekday].contains { minute >= $0.start && minute < $0.end }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        let overnight = hasCurrentSchedule(at: yesterday) && weeklyHours[(weekday + 6) % 7].contains {
            $0.end > 1440 && minute + 1440 >= $0.start && minute + 1440 < $0.end
        }
        return today || overnight
    }
}
