//
//  DiningMenu.swift
//  MyWes
//
//  Native menus from Bon Appétit's public cafe pages. Each page embeds the
//  day's menu as JavaScript assignments:
//
//    Bamco.menu_items = {"<item id>": {...}, ...};
//    Bamco.dayparts['3'] = {"label": "Lunch", "starttime": "11:00", "stations": [...]};
//
//  This file is Foundation-only so it can be tested outside Xcode.
//

import Foundation

nonisolated struct DiningNutrient: Equatable, Hashable, Sendable {
    var label: String
    var amount: String
}

nonisolated struct DiningMenuItem: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var details: String
    var dietary: [String]
    var calories: String?
    var isFeatured: Bool
    var nutrients: [DiningNutrient]

    var isVegan: Bool { dietary.contains(DiningDiet.vegan.label) }
    var isVegetarian: Bool { isVegan || dietary.contains(DiningDiet.vegetarian.label) }
    var isMadeWithoutGluten: Bool { dietary.contains(DiningDiet.withoutGluten.label) }

    func matches(_ diet: DiningDiet?) -> Bool {
        switch diet {
        case nil: true
        case .vegetarian: isVegetarian
        case .vegan: isVegan
        case .withoutGluten: isMadeWithoutGluten
        case .halal: dietary.contains(DiningDiet.halal.label)
        case .kosher: dietary.contains(DiningDiet.kosher.label)
        }
    }
}

nonisolated enum DiningDiet: String, CaseIterable, Identifiable, Sendable {
    case vegetarian, vegan, withoutGluten, halal, kosher

    var id: String { rawValue }

    /// Short label shown in the app.
    var label: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .withoutGluten: "No gluten ingredients"
        case .halal: "Halal"
        case .kosher: "Kosher"
        }
    }
}

nonisolated struct DiningStation: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var note: String
    var items: [DiningMenuItem]

    var featuredItems: [DiningMenuItem] { items.filter(\.isFeatured) }
}

nonisolated struct DiningMeal: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    /// Minutes after midnight, campus time.
    var start: Int?
    var end: Int?
    var stations: [DiningStation]

    var timeLabel: String? {
        guard let start, let end else { return nil }
        return "\(DiningPeriod.clock(start)) – \(DiningPeriod.clock(end))"
    }

    var itemCount: Int { stations.reduce(0) { $0 + $1.items.count } }
}

nonisolated enum DiningMenuError: Error, Equatable {
    case unrecognizedPage
}

nonisolated enum BonAppetitMenu {
    static func url(slug: String, dateKey: String) -> URL? {
        guard slug.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }),
              dateKey.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else { return nil }
        return URL(string: "https://wesleyan.cafebonappetit.com/cafe/\(slug)/\(dateKey)/")
    }

    /// The meal whose service is in progress, else the next one today, else the last.
    static func defaultMeal(_ meals: [DiningMeal], minuteOfDay: Int?) -> DiningMeal? {
        guard let minuteOfDay else { return meals.first }
        if let current = meals.first(where: { ($0.start ?? .max) <= minuteOfDay && minuteOfDay < ($0.end ?? .min) }) {
            return current
        }
        if let next = meals.filter({ ($0.start ?? .min) > minuteOfDay }).min(by: { ($0.start ?? 0) < ($1.start ?? 0) }) {
            return next
        }
        return meals.last
    }

    /// Parses a cafe page. A valid page with no published meals returns [].
    static func parse(html: String) throws -> [DiningMeal] {
        guard let itemsJSON = jsonValue(after: "Bamco.menu_items = ", in: html),
              let rawItems = try? JSONSerialization.jsonObject(with: Data(itemsJSON.utf8)) else {
            throw DiningMenuError.unrecognizedPage
        }
        // An empty menu is serialized as [] rather than {}.
        let itemsByID = (rawItems as? [String: Any] ?? [:]).compactMapValues { $0 as? [String: Any] }

        var meals: [DiningMeal] = []
        var searchStart = html.startIndex
        let marker = "Bamco.dayparts['"
        while let range = html.range(of: marker, range: searchStart..<html.endIndex) {
            searchStart = range.upperBound
            guard let assign = html.range(of: "= ", range: range.upperBound..<html.endIndex),
                  html.distance(from: range.upperBound, to: assign.lowerBound) < 20,
                  let json = balancedJSON(in: html, from: assign.upperBound),
                  let daypart = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any]
            else { continue }
            meals.append(meal(from: daypart, items: itemsByID))
        }
        // Dayparts are emitted in page order; keep them chronological regardless.
        return meals.sorted { ($0.start ?? 0) < ($1.start ?? 0) }
    }

    // MARK: - Mapping

    private static func meal(from daypart: [String: Any], items: [String: [String: Any]]) -> DiningMeal {
        let stations = (daypart["stations"] as? [[String: Any]] ?? []).compactMap { station -> DiningStation? in
            let ids = (station["items"] as? [Any] ?? []).map { "\($0)" }
            var seen = Set<String>()
            let stationItems = ids.compactMap { id -> DiningMenuItem? in
                guard seen.insert(id).inserted, let raw = items[id] else { return nil }
                return item(id: id, raw: raw)
            }
            guard !stationItems.isEmpty else { return nil }
            return DiningStation(
                id: string(station["id"]) ?? UUID().uuidString,
                name: displayName(plainText(string(station["label"]) ?? "Station")),
                note: plainText(string(station["note"]) ?? ""),
                items: stationItems
            )
        }
        return DiningMeal(
            id: string(daypart["id"]) ?? UUID().uuidString,
            name: plainText(string(daypart["label"]) ?? "Menu"),
            start: minutes(string(daypart["starttime"])),
            end: minutes(string(daypart["endtime"])),
            stations: stations
        )
    }

    private static func item(id: String, raw: [String: Any]) -> DiningMenuItem {
        // cor_icon is {"1": "Vegetarian", ...} or [] when the item has none.
        let icons = raw["cor_icon"] as? [String: Any] ?? [:]
        let dietary = icons.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
            .compactMap { string($0.value).map(dietaryLabel) }
        let nutrition = raw["nutrition"] as? [String: Any]
        let calories = string(nutrition?["kcal"]).flatMap { $0.isEmpty ? nil : $0 }
        let tier = Int(string(raw["tier"]) ?? "") ?? 2
        let special = Int(string(raw["special"]) ?? "") ?? 0

        var nutrients: [DiningNutrient] = []
        if let details = raw["nutrition_details"] as? [String: Any] {
            for key in ["servingSize", "calories", "proteinContent", "carbohydrateContent", "fatContent",
                        "saturatedFatContent", "fiberContent", "sugarContent", "sodiumContent", "cholesterolContent"] {
                guard let entry = details[key] as? [String: Any],
                      let label = string(entry["label"]), let value = string(entry["value"]), !value.isEmpty else { continue }
                nutrients.append(DiningNutrient(label: label, amount: value + (string(entry["unit"]) ?? "")))
            }
        }

        return DiningMenuItem(
            id: id,
            name: displayName(plainText(string(raw["label"]) ?? "Menu item")),
            details: plainText(string(raw["description"]) ?? ""),
            dietary: dietary,
            calories: calories,
            isFeatured: tier == 1 || special == 1,
            nutrients: nutrients
        )
    }

    private static func dietaryLabel(_ label: String) -> String {
        label == "Made without Gluten-Containing Ingredients" ? DiningDiet.withoutGluten.label : label
    }

    // MARK: - Text helpers

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let s as String: s
        case let n as Int: String(n)
        case let n as Double: n.rounded() == n ? String(Int(n)) : String(n)
        case let n as NSNumber: n.stringValue
        default: nil
        }
    }

    private static func minutes(_ clock: String?) -> Int? {
        guard let parts = clock?.split(separator: ":"), parts.count >= 2,
              let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    /// Bon Appétit labels are often lowercase ("tater tots"); capitalize the first letter only.
    static func displayName(_ text: String) -> String {
        guard let first = text.first, first.isLowercase else { return text }
        return first.uppercased() + text.dropFirst()
    }

    static func plainText(_ html: String) -> String {
        var text = html.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        text = decodeEntities(text)
        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        let named = ["amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">", "nbsp": " ",
                     "ndash": "–", "mdash": "—", "rsquo": "’", "lsquo": "‘", "rdquo": "”", "ldquo": "“", "eacute": "é"]
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            guard text[index] == "&", let semicolon = text[index...].prefix(12).firstIndex(of: ";") else {
                result.append(text[index]); index = text.index(after: index); continue
            }
            let entity = String(text[text.index(after: index)..<semicolon])
            var replacement: String?
            if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
                replacement = UInt32(entity.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
            } else if entity.hasPrefix("#") {
                replacement = UInt32(entity.dropFirst()).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
            } else {
                replacement = named[entity]
            }
            if let replacement {
                result += replacement
                index = text.index(after: semicolon)
            } else {
                result.append("&"); index = text.index(after: index)
            }
        }
        return result
    }

    // MARK: - JSON extraction

    private static func jsonValue(after marker: String, in html: String) -> String? {
        guard let range = html.range(of: marker) else { return nil }
        return balancedJSON(in: html, from: range.upperBound)
    }

    /// Returns the JSON object or array starting at `start`, matching brackets
    /// outside of string literals.
    static func balancedJSON(in text: String, from start: String.Index) -> String? {
        let scalars = text.unicodeScalars
        var i = start
        while i < scalars.endIndex, scalars[i] == " " || scalars[i] == "\t" { i = scalars.index(after: i) }
        guard i < scalars.endIndex, scalars[i] == "{" || scalars[i] == "[" else { return nil }
        let begin = i
        var depth = 0
        var inString = false
        var escaped = false
        while i < scalars.endIndex {
            let c = scalars[i]
            if inString {
                if escaped { escaped = false }
                else if c == "\\" { escaped = true }
                else if c == "\"" { inString = false }
            } else {
                switch c {
                case "\"": inString = true
                case "{", "[": depth += 1
                case "}", "]":
                    depth -= 1
                    if depth == 0 { return String(text[begin...i]) }
                default: break
                }
            }
            i = scalars.index(after: i)
        }
        return nil
    }
}
