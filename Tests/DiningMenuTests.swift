import Foundation

// Run against saved Bon Appétit pages: pass HTML file paths as arguments.
// Without arguments, checks a small synthetic page.
@main struct DiningMenuTests {
    static func main() throws {
        let synthetic = #"""
        <script>
        Bamco.menu_items = {"10":{"id":"10","label":"tofu scramble","description":"soy tofu &amp; miso<br \/>fresh vegetables","cor_icon":{"4":"Vegan","9":"Made without Gluten-Containing Ingredients"},"nutrition":{"kcal":"210"},"tier":1,"special":1,"nutrition_details":{"calories":{"label":"Calories","value":"210","unit":""},"proteinContent":{"label":"Protein","value":"14","unit":"g"}}},"11":{"id":"11","label":"Bagel \"plain\" {toasted}","description":"","cor_icon":[],"nutrition":{"kcal":""},"tier":"2","special":0},"12":{"id":"12","label":"ham","description":"","cor_icon":{"18":"Humane"},"nutrition":{"kcal":"90"},"tier":"1","special":0}};
        Bamco.dayparts = Bamco.dayparts || {};
        Bamco.dayparts['4'] = {"starttime":"17:00","endtime":"20:00","id":"4","label":"Dinner","stations":[{"id":"7","label":"classics","note":"","items":["12","99"]}]};
        Bamco.dayparts['1'] = {"starttime":"08:00","endtime":"10:30","id":"1","label":"Breakfast","stations":[{"id":"5","label":"vegan","note":"Chef&#8217;s pick","items":["10","11","10"]},{"id":"6","label":"empty","items":[]}]};
        </script>
        """#
        let meals = try BonAppetitMenu.parse(html: synthetic)
        precondition(meals.map(\.name) == ["Breakfast", "Dinner"], "meals sorted by start time")
        precondition(meals[0].timeLabel == "8:00 AM – 10:30 AM")
        precondition(meals[0].stations.count == 1, "empty stations dropped")
        let station = meals[0].stations[0]
        precondition(station.name == "Vegan" && station.note == "Chef’s pick")
        precondition(station.items.map(\.id) == ["10", "11"], "duplicates removed, order kept")
        let tofu = station.items[0]
        precondition(tofu.name == "Tofu scramble" && tofu.details == "soy tofu & miso\nfresh vegetables")
        precondition(tofu.dietary == ["Vegan", "No gluten ingredients"] && tofu.isVegetarian && tofu.isMadeWithoutGluten)
        precondition(tofu.calories == "210" && tofu.isFeatured && tofu.nutrients.count == 2)
        let bagel = station.items[1]
        precondition(bagel.name == "Bagel \"plain\" {toasted}" && bagel.calories == nil && !bagel.isFeatured && bagel.dietary.isEmpty)
        precondition(meals[1].stations[0].items.map(\.name) == ["Ham"], "missing item ids skipped")
        precondition(meals[1].stations[0].items[0].isFeatured, "string tier 1 is featured")
        precondition(!bagel.matches(.vegetarian) && tofu.matches(.vegetarian) && bagel.matches(nil))

        precondition(BonAppetitMenu.defaultMeal(meals, minuteOfDay: 9 * 60)?.name == "Breakfast")
        precondition(BonAppetitMenu.defaultMeal(meals, minuteOfDay: 12 * 60)?.name == "Dinner")
        precondition(BonAppetitMenu.defaultMeal(meals, minuteOfDay: 22 * 60)?.name == "Dinner")
        precondition(BonAppetitMenu.defaultMeal(meals, minuteOfDay: nil)?.name == "Breakfast")

        let closed = try BonAppetitMenu.parse(html: "Bamco.menu_items = [];")
        precondition(closed.isEmpty, "closed day")
        do { _ = try BonAppetitMenu.parse(html: "<html>maintenance</html>"); preconditionFailure("should throw") }
        catch DiningMenuError.unrecognizedPage {}
        precondition(BonAppetitMenu.url(slug: "summerfields", dateKey: "2026-11-14")?.absoluteString
                     == "https://wesleyan.cafebonappetit.com/cafe/summerfields/2026-11-14/")
        precondition(BonAppetitMenu.url(slug: "../x", dateKey: "2026-11-14") == nil)
        precondition(BonAppetitMenu.url(slug: "pi-cafe", dateKey: "tomorrow") == nil)
        print("Dining menu checks passed: synthetic page.")

        for path in CommandLine.arguments.dropFirst() {
            let html = try String(contentsOfFile: path, encoding: .utf8)
            let start = Date()
            let meals = try BonAppetitMenu.parse(html: html)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            precondition(!meals.isEmpty, "\(path): no meals")
            let summary = meals.map { "\($0.name) \($0.timeLabel ?? "?") \($0.stations.count) stations/\($0.itemCount) items" }
            print("\((path as NSString).lastPathComponent): \(summary.joined(separator: "; ")) [\(ms) ms]")
            if let sample = meals.first?.stations.first?.items.first {
                print("  e.g. \(sample.name) — \(sample.dietary.joined(separator: ", ")) \(sample.calories ?? "") kcal")
            }
        }
    }
}
