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
        // Special hours replace the weekly schedule for that campus date only.
        venue.weeklyHours[4] = [DiningPeriod(start: 480, end: 1200)] // Thursdays 8–8
        venue.specialHours["2026-11-19"] = []
        assert(venue.scheduledOpen(at: date("2026-11-19T17:00:00Z")) == false)
        assert(venue.hours(on: date("2026-11-19T17:00:00Z")) == "Closed today")
        assert(venue.scheduledOpen(at: date("2026-11-12T17:00:00Z")) == true)
        assert(venue.statusDetail(at: date("2026-11-12T17:00:00Z")) == "Open until 8:00 PM")
        assert(venue.statusDetail(at: date("2026-11-12T12:00:00Z")) == "Opens at 8:00 AM")
        assert(venue.statusDetail(at: date("2026-11-13T02:00:00Z")) == "Closed for the day")
        // A special late-night period still carries past midnight.
        venue.specialHours["2026-11-18"] = [DiningPeriod(start: 1290, end: 1500)]
        assert(venue.scheduledOpen(at: date("2026-11-19T05:30:00Z")) == true)
        assert(venue.statusDetail(at: date("2026-11-19T05:30:00Z")) == "Open until 1:00 AM")
        // Rows from before the dining expansion migration still decode.
        let legacy = try JSONDecoder().decode(DiningVenue.self, from: Data(#"{"id":"\#(UUID())","name":"Summerfields","location":"Butterfield C","weekly_hours":[[],[],[],[],[],[],[]],"notes":"","source_url":"https://www.wesleyan.edu/dining/","verified_on":"2026-11-07","valid_through":"2026-11-20"}"#.utf8))
        assert(legacy.menuURLSlug == "summerfields" && legacy.specialHours.isEmpty && legacy.sortOrder == 100)
        let current = try JSONDecoder().decode(DiningVenue.self, from: Data(#"{"id":"\#(UUID())","name":"Pi Café","location":"Casper","weekly_hours":[[],[],[],[],[],[],[]],"special_hours":{"2026-11-26":[]},"menu_slug":"pi-cafe","sort_order":40,"notes":"","source_url":"https://www.wesleyan.edu/dining/","verified_on":"2026-11-13","valid_through":"2026-12-13"}"#.utf8))
        assert(current.menuURLSlug == "pi-cafe" && current.specialHours["2026-11-26"] == [] && current.sortOrder == 40)
        // Hand-entered late-night menu applies on days whose schedule has a 9:30 PM service.
        let withManual = try JSONDecoder().decode(DiningVenue.self, from: Data(#"{"id":"\#(UUID())","name":"Summerfields","location":"Butterfield C","weekly_hours":[[{"start":1290,"end":1500}],[],[],[],[],[],[]],"manual_menus":[{"service":"Late night","start":1290,"end":1500,"source":"Wes2Go","verified_on":"2026-11-18","sections":[{"name":"Grill","items":[{"name":"Cheeseburger","price":"$8.50"},{"name":"Fries"}]},{"name":"Empty","items":[]}]}],"notes":"","source_url":"https://www.wesleyan.edu/dining/","verified_on":"2026-11-13","valid_through":"2026-12-13"}"#.utf8))
        let sunday = date("2026-11-15T17:00:00Z"), monday = date("2026-11-16T17:00:00Z")
        let lateNight = withManual.manualMeals(on: sunday)
        assert(lateNight.map(\.name) == ["Late night"] && lateNight[0].isManual && lateNight[0].stations.count == 1)
        assert(lateNight[0].stations[0].items.map(\.price) == ["$8.50", nil])
        assert(withManual.manualMeals(on: monday).isEmpty)
        let broken = try JSONDecoder().decode(DiningVenue.self, from: Data(#"{"id":"\#(UUID())","name":"X","location":"Y","weekly_hours":[[],[],[],[],[],[],[]],"manual_menus":[{"oops":true}],"notes":"","source_url":"https://www.wesleyan.edu/dining/","verified_on":"2026-11-13","valid_through":"2026-12-13"}"#.utf8))
        assert(broken.manualMenus.isEmpty, "malformed manual menu doesn't break the venue")
        venue.menuSlug = "../evil"
        assert(venue.menuURLSlug == nil)
        venue.weeklyHours = []
        assert(venue.scheduledOpen(at: date("2026-11-07T05:30:00Z")) == nil)
        print("Dining checks passed: overnight, exact boundaries, expiry, campus timezone, DST, special hours, status text, legacy decoding, malformed schedule.")
    }
}
