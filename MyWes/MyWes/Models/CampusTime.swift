//
//  CampusTime.swift
//  MyWes
//

import Foundation

enum CampusTime {
    static let timeZone = TimeZone(identifier: "America/New_York")!

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    static let dateLabel: DateFormatter = formatter("E, MMM d")
    static let time: DateFormatter = formatter("h:mm a")
    static let month: DateFormatter = formatter("MMM")
    static let day: DateFormatter = formatter("d")

    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    static func isInCurrentWeek(_ date: Date, now: Date = Date()) -> Bool {
        calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
    }

    static func startOfToday(now: Date = Date()) -> Date {
        calendar.startOfDay(for: now)
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }
}
