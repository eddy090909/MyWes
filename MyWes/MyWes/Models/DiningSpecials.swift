//
//  DiningSpecials.swift
//  MyWes
//
//  WesWings and Red & Black Café post their daily specials on weswings.com
//  (WordPress) as photos of the specials board. The public WordPress API
//  gives us each post's title, date, link, and image — not menu text — so
//  MyWes shows them as posted photos, never as parsed menu items.
//

import Foundation

nonisolated struct DiningSpecialPost: Identifiable, Equatable, Hashable, Sendable {
    var id: Int
    var title: String
    var postedAt: Date
    var link: URL
    var imageURLs: [URL]
}

nonisolated enum WesWingsSpecials {
    enum Source: String, Sendable {
        case weswings
        case redBlackCafe = "red_black_cafe"

        /// Post titles look like "WesWings Specials Friday 11/13/26" or "RBC Saturday Brunch".
        func matches(title: String) -> Bool {
            let lower = title.lowercased()
            switch self {
            case .weswings: return lower.hasPrefix("weswings special")
            case .redBlackCafe: return lower.hasPrefix("rbc ") || lower.hasPrefix("red & black special") || lower.hasPrefix("red and black special")
            }
        }
    }

    static let postsURL = URL(string: "https://weswings.com/wp-json/wp/v2/posts?per_page=20&_fields=id,date_gmt,link,title,content")!
    static let allowedImageHosts: Set<String> = ["weswings.com", "i0.wp.com", "i1.wp.com", "i2.wp.com"]

    /// Posts for one location from the last `maxAgeDays`, newest first.
    static func parse(_ data: Data, source: Source, now: Date = Date(), maxAgeDays: Double = 4) throws -> [DiningSpecialPost] {
        guard let posts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw DiningMenuError.unrecognizedPage
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let cutoff = now.addingTimeInterval(-maxAgeDays * 86_400)

        return posts.compactMap { post -> DiningSpecialPost? in
            guard let id = post["id"] as? Int,
                  let title = (post["title"] as? [String: Any])?["rendered"] as? String,
                  let dateString = post["date_gmt"] as? String, let posted = formatter.date(from: dateString),
                  let linkString = post["link"] as? String, let link = URL(string: linkString),
                  link.scheme == "https", link.host == "weswings.com" else { return nil }
            let cleanTitle = BonAppetitMenu.plainText(title)
            guard source.matches(title: cleanTitle), posted >= cutoff else { return nil }
            let html = (post["content"] as? [String: Any])?["rendered"] as? String ?? ""
            return DiningSpecialPost(id: id, title: cleanTitle, postedAt: posted, link: link, imageURLs: imageURLs(in: html))
        }
        .sorted { $0.postedAt > $1.postedAt }
    }

    /// Display-size images (`data-large-file`, else `src`) in post order.
    static func imageURLs(in html: String) -> [URL] {
        var urls: [URL] = []
        let imgTags = matches(of: #"<img\b[^>]*>"#, in: html)
        for tag in imgTags {
            let candidate = attribute("data-large-file", in: tag) ?? attribute("src", in: tag)
            guard let raw = candidate,
                  let url = URL(string: BonAppetitMenu.plainText(raw)),
                  url.scheme == "https", let host = url.host, allowedImageHosts.contains(host),
                  !urls.contains(url) else { continue }
            urls.append(url)
        }
        return urls
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        guard let range = tag.range(of: #"\b\#(name)="([^"]*)""#, options: .regularExpression) else { return nil }
        let match = tag[range]
        guard let start = match.firstIndex(of: "\"") else { return nil }
        return String(match[match.index(after: start)..<match.index(before: match.endIndex)])
    }

    private static func matches(of pattern: String, in text: String) -> [String] {
        var results: [String] = []
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive], range: searchRange) {
            results.append(String(text[range]))
            searchRange = range.upperBound..<text.endIndex
        }
        return results
    }
}
