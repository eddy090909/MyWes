import Foundation

// Pass a saved weswings.com posts response (see WesWingsSpecials.postsURL) to also check real data.
@main struct DiningSpecialsTests {
    static func main() throws {
        let json = #"""
        [{"id":3,"date_gmt":"2026-11-13T19:05:52","link":"https://weswings.com/2026/11/13/rbc-friday-specials/","title":{"rendered":"RBC Friday Specials"},
          "content":{"rendered":"<figure><img data-large-file=\"https://i0.wp.com/weswings.com/wp-content/uploads/2026/09/a.jpg?fit=584%2C779&amp;ssl=1\" src=\"https://i0.wp.com/weswings.com/x.jpg\"></figure><img src=\"https://evil.example/tracker.gif\">"}},
         {"id":2,"date_gmt":"2026-11-12T15:31:29","link":"https://weswings.com/2026/11/12/weswings-specials-friday-11-13-26/","title":{"rendered":"Weswings Specials Friday 11\/13\/26"},
          "content":{"rendered":"<img src=\"https://i0.wp.com/weswings.com/b.jpg?resize=584%2C779&#038;ssl=1\"><img src=\"https://i0.wp.com/weswings.com/b.jpg?resize=584%2C779&#038;ssl=1\">"}},
         {"id":1,"date_gmt":"2026-11-01T15:31:29","link":"https://weswings.com/old/","title":{"rendered":"WesWings Specials Sunday 11\/1\/26"},"content":{"rendered":""}},
         {"id":4,"date_gmt":"2026-11-13T10:00:00","link":"https://weswings.com/news/","title":{"rendered":"News Release"},"content":{"rendered":""}},
         {"id":5,"date_gmt":"2026-11-13T10:00:00","link":"https://elsewhere.example/p","title":{"rendered":"WesWings Specials Today"},"content":{"rendered":""}}]
        """#
        let now = ISO8601DateFormatter().date(from: "2026-11-14T00:00:00Z")!
        let wings = try WesWingsSpecials.parse(Data(json.utf8), source: .weswings, now: now)
        precondition(wings.map(\.id) == [2], "only recent WesWings posts on weswings.com")
        precondition(wings[0].title == "Weswings Specials Friday 11/13/26")
        precondition(wings[0].imageURLs.map(\.absoluteString) == ["https://i0.wp.com/weswings.com/b.jpg?resize=584%2C779&ssl=1"], "entities decoded, duplicates removed")
        let rbc = try WesWingsSpecials.parse(Data(json.utf8), source: .redBlackCafe, now: now)
        precondition(rbc.map(\.id) == [3])
        precondition(rbc[0].imageURLs.map(\.absoluteString) == ["https://i0.wp.com/weswings.com/wp-content/uploads/2026/09/a.jpg?fit=584%2C779&ssl=1"], "large file preferred, foreign hosts dropped")
        do { _ = try WesWingsSpecials.parse(Data("{}".utf8), source: .weswings); preconditionFailure("should throw") }
        catch DiningMenuError.unrecognizedPage {}

        let venue = DiningVenue(id: UUID(), name: "Star & Crescent", location: "ADP", weeklyHours: Array(repeating: [], count: 7),
                                notes: "", sourceUrl: "", verifiedOn: "2026-11-13", validThrough: "2026-12-13",
                                operatorKind: "independent", menuUrl: "https://middletown.adps.org/", hoursPublished: false)
        let noon = ISO8601DateFormatter().date(from: "2026-11-16T17:00:00Z")!
        precondition(venue.scheduledOpen(at: noon) == nil && venue.hours(on: noon) == "Hours not published")
        precondition(venue.isIndependent && !venue.hasInAppMenu && venue.officialMenuURL?.host == "middletown.adps.org")
        var wingsVenue = venue
        wingsVenue.specialsSource = "weswings"
        wingsVenue.menuUrl = "http://insecure.example/"
        precondition(wingsVenue.specialsFeed == .weswings && wingsVenue.hasInAppMenu && wingsVenue.officialMenuURL == nil)
        print("Dining specials checks passed: source matching, recency, link/image host allowlist, hours-not-published venues.")

        for path in CommandLine.arguments.dropFirst() {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            for source in [WesWingsSpecials.Source.weswings, .redBlackCafe] {
                let posts = try WesWingsSpecials.parse(data, source: source, maxAgeDays: 7)
                print("\(source.rawValue): \(posts.map { "\($0.title) [\($0.imageURLs.count) img]" })")
            }
        }
    }
}
