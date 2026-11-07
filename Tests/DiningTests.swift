import Foundation

@main struct DiningTests {
    static func main() throws {
        let date: (String) -> Date = { ISO8601DateFormatter().date(from: $0)! }
        var venue = DiningVenue(id: UUID(), name: "Test", location: "Campus", weeklyHours: Array(repeating: [], count: 7), notes: "", sourceUrl: "", verifiedOn: "2026-11-01", validThrough: "2026-11-20")
        // Friday night period carries into Saturday morning in campus time.
        venue.weeklyHours[5] = [DiningPeriod(start: 1290, end: 1500)]
        assert(venue.scheduledOpen(at: date("2026-11-07T05:30:00Z")) == true)
        assert(venue.scheduledOpen(at: date("2026-11-07T06:00:00Z")) == false)
        assert(venue.scheduledOpen(at: date("2026-11-07T02:30:00Z")) == true)
        assert(venue.scheduledOpen(at: date("2026-11-28T05:30:00Z")) == nil)
        assert(venue.scheduledOpen(at: date("2026-10-31T04:30:00Z")) == nil)
        venue.weeklyHours[0] = [DiningPeriod(start: 480, end: 630)]
        // DST ended Nov 1: Eastern 8 AM is 13:00 UTC, not 12:00.
        assert(venue.scheduledOpen(at: date("2026-11-01T12:59:00Z")) == false)
        assert(venue.scheduledOpen(at: date("2026-11-01T13:00:00Z")) == true)
        assert(venue.scheduledOpen(at: date("2026-11-01T15:30:00Z")) == false)
        venue.weeklyHours = []
        assert(venue.scheduledOpen(at: date("2026-11-07T05:30:00Z")) == nil)
        print("Dining checks passed: overnight, exact boundaries, expiry, campus timezone, DST, malformed schedule.")
    }
}
