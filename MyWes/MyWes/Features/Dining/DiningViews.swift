//
//  DiningViews.swift
//  MyWes
//

import SwiftUI
import SafariServices

// MARK: - Dining tab

struct DiningView: View {
    @Environment(AppSession.self) private var session
    @State private var showOpenOnly = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Campus dining").font(Typography.headlineLarge)
                Text("Hours are Eastern Time from Wesleyan Dining. Menus come from Bon Appétit and can change.")
                    .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
                if let error = session.community.diningError {
                    CampusRetry(message: error) { await session.community.refresh() }
                }
                if session.community.isLoading && session.community.dining.isEmpty { ProgressView() }
                if session.community.dining.isEmpty && !session.community.isLoading && session.community.diningError == nil {
                    Text("No dining schedules have been published yet.")
                }
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let venues = session.community.sortedDining
                    let visible = showOpenOnly ? venues.filter { $0.scheduledOpen(at: context.date) == true } : venues
                    VStack(alignment: .leading, spacing: 16) {
                        if !venues.isEmpty {
                            HStack(spacing: 8) {
                                SelectionChip(title: "All locations", isSelected: !showOpenOnly) { showOpenOnly = false }
                                SelectionChip(title: "Open now", isSelected: showOpenOnly) { showOpenOnly = true }
                            }
                        }
                        if showOpenOnly && visible.isEmpty && !venues.isEmpty {
                            Text("Nothing is scheduled to be open right now.")
                                .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
                        }
                        ForEach(visible) { venue in
                            DiningVenueCard(venue: venue, date: context.date)
                        }
                    }
                }
            }.padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dining").navigationBarTitleDisplayMode(.inline)
        .task { await session.community.refresh() }
        .refreshable { await session.community.refresh() }
    }
}

// MARK: - Venue card

struct DiningVenueCard: View {
    let venue: DiningVenue
    let date: Date
    /// Compact cards (Home) skip weekly hours and notes.
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(venue.name).font(.headline).foregroundStyle(Theme.ink)
                Spacer()
                statusPill
            }
            Text(venue.location).font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)

            if venue.scheduledOpen(at: date) != nil {
                HStack(spacing: 6) {
                    Text("Today: \(venue.hours(on: date))").font(Typography.bodySmall)
                    if venue.hasSpecialHours(on: date) {
                        Text("Special hours")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.cardinal)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.savedBannerBackground)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text("Schedule needs updating. Check official hours.")
                    .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
            }

            if venue.menuURLSlug != nil {
                NavigationLink(value: AppRoute.diningMenu(venue.id)) {
                    Label("See today’s menu", systemImage: "fork.knife")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.cardinal)
                }
            }

            if !compact {
                DisclosureGroup("Hours this week") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<7, id: \.self) { offset in
                            weekRow(offset: offset)
                        }
                    }.padding(.top, 4)
                }
                .font(Typography.bodySmall)
                .tint(Theme.ink)
                if !venue.notes.isEmpty {
                    Text(venue.notes).font(Typography.caption).foregroundStyle(Theme.secondaryText)
                }
                Text("Verified \(venue.verifiedOn) · valid through \(venue.validThrough)")
                    .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                if let url = URL(string: venue.sourceUrl), url.scheme == "https", url.host == "www.wesleyan.edu" {
                    Link("Official hours and exceptions", destination: url).font(Typography.bodySmall)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
    }

    @ViewBuilder private var statusPill: some View {
        if let open = venue.scheduledOpen(at: date) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(open ? "Open" : "Closed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(open ? Theme.success : Theme.secondaryText)
                if let detail = venue.statusDetail(at: date), detail != "Open now" {
                    Text(detail).font(Typography.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func weekRow(offset: Int) -> some View {
        let day = DiningVenue.calendar.date(byAdding: .day, value: offset, to: date) ?? date
        return HStack(alignment: .top) {
            Text(offset == 0 ? "Today" : DiningDateFormat.weekday.string(from: day))
                .frame(width: 56, alignment: .leading)
                .fontWeight(offset == 0 ? .semibold : .regular)
            Text(venue.hasCurrentSchedule(at: day) ? venue.hours(on: day) : "Not yet published")
                .foregroundStyle(venue.hasCurrentSchedule(at: day) ? Theme.ink : Theme.secondaryText)
            if venue.hasSpecialHours(on: day) && venue.hasCurrentSchedule(at: day) {
                Text("•").foregroundStyle(Theme.cardinal).accessibilityLabel("Special hours")
            }
        }.font(Typography.caption)
    }
}

enum DiningDateFormat {
    static let weekday: DateFormatter = make("EEE M/d")
    static let chipDay: DateFormatter = make("EEE")
    static let chipDate: DateFormatter = make("MMM d")
    static let long: DateFormatter = make("EEEE, MMMM d")

    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = CampusTime.timeZone
        f.dateFormat = format
        return f
    }
}

// MARK: - Menu

struct DiningMenuView: View {
    let venueID: UUID
    @Environment(AppSession.self) private var session

    @State private var dayOffset = 0
    @State private var meals: [DiningMeal] = []
    @State private var selectedMealID: String?
    @State private var diet: DiningDiet?
    @State private var searchText = ""
    @State private var expandedStations: Set<String> = []
    @State private var loading = false
    @State private var error: String?
    @State private var selectedItem: DiningMenuItem?
    @State private var showingOfficialPage = false

    private var venue: DiningVenue? { session.community.dining.first { $0.id == venueID } }

    private func day(_ offset: Int) -> Date {
        DiningVenue.calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }

    private var dateKey: String { DiningVenue.dateKey(day(dayOffset)) }

    private var selectedMeal: DiningMeal? {
        meals.first { $0.id == selectedMealID } ?? meals.first
    }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isFiltering: Bool { diet != nil || !query.isEmpty }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: []) {
                header
                dayPicker
                if meals.count > 1 { mealPicker }
                dietPicker
                content
                footer
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(venue?.name ?? "Menu")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search this menu")
        .task(id: dateKey) { await load(force: false) }
        .refreshable { await load(force: true) }
        .sheet(item: $selectedItem) { item in DiningItemDetail(item: item) }
        .sheet(isPresented: $showingOfficialPage) {
            if let url = officialURL { OfficialDiningMenu(url: url).ignoresSafeArea() }
        }
    }

    private var officialURL: URL? {
        venue?.menuURLSlug.flatMap { BonAppetitMenu.url(slug: $0, dateKey: dateKey) }
    }

    // MARK: Sections

    @ViewBuilder private var header: some View {
        if let venue {
            VStack(alignment: .leading, spacing: 4) {
                Text(DiningDateFormat.long.string(from: day(dayOffset)))
                    .font(Typography.eyebrow).foregroundStyle(Theme.cardinal)
                if venue.hasCurrentSchedule(at: day(dayOffset)) {
                    Text("Hours: \(venue.hours(on: day(dayOffset)))")
                        .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let date = day(offset)
                    Button {
                        guard dayOffset != offset else { return }
                        dayOffset = offset
                        selectedMealID = nil
                        expandedStations = []
                    } label: {
                        VStack(spacing: 2) {
                            Text(offset == 0 ? "Today" : DiningDateFormat.chipDay.string(from: date))
                                .font(.system(size: 13, weight: .bold))
                            Text(DiningDateFormat.chipDate.string(from: date))
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(dayOffset == offset ? .white : Theme.ink)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(dayOffset == offset ? Theme.cardinal : Theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                            .stroke(dayOffset == offset ? Theme.cardinal : Theme.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(dayOffset == offset ? .isSelected : [])
                }
            }
        }
    }

    private var mealPicker: some View {
        Picker("Meal", selection: Binding(
            get: { selectedMeal?.id ?? "" },
            set: { selectedMealID = $0; expandedStations = [] }
        )) {
            ForEach(meals) { meal in Text(meal.name).tag(meal.id) }
        }
        .pickerStyle(.segmented)
    }

    private var dietPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                dietChip(nil, title: "Everything")
                ForEach(DiningDiet.allCases) { option in dietChip(option, title: option.label) }
            }
        }
    }

    private func dietChip(_ option: DiningDiet?, title: String) -> some View {
        let selected = diet == option
        return Button { diet = option } label: {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(selected ? .white : Theme.ink)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Theme.ink : Theme.background)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? Theme.ink : Theme.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var content: some View {
        if loading && meals.isEmpty {
            ProgressView("Loading menu…").frame(maxWidth: .infinity).padding(.vertical, 24)
        } else if let error, meals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(error).foregroundStyle(Theme.secondaryText)
                HStack {
                    Button("Retry") { Task { await load(force: true) } }
                        .buttonStyle(.borderedProminent).tint(Theme.cardinal)
                    if officialURL != nil {
                        Button("Open Bon Appétit page") { showingOfficialPage = true }
                    }
                }
            }
        } else if meals.isEmpty {
            Text("No menu has been published for this day. The location may be closed.")
                .foregroundStyle(Theme.secondaryText)
        } else if let meal = selectedMeal {
            if let time = meal.timeLabel {
                Text("\(meal.name) · \(time)")
                    .font(Typography.bodySmall).foregroundStyle(Theme.secondaryText)
            }
            let stations = filteredStations(meal)
            if stations.isEmpty {
                Text(!query.isEmpty ? "No items match “\(query)”."
                     : diet.map { "No \($0.label.lowercased()) items listed for \(meal.name.lowercased())." }
                     ?? "Nothing is listed for \(meal.name.lowercased()).")
                    .foregroundStyle(Theme.secondaryText)
            }
            ForEach(stations) { station in stationSection(station) }
        }
    }

    private func filteredStations(_ meal: DiningMeal) -> [DiningStation] {
        guard isFiltering else { return meal.stations }
        return meal.stations.compactMap { station in
            var copy = station
            copy.items = station.items.filter { item in
                item.matches(diet) && (query.isEmpty
                    || item.name.localizedCaseInsensitiveContains(query)
                    || item.details.localizedCaseInsensitiveContains(query))
            }
            return copy.items.isEmpty ? nil : copy
        }
    }

    private func stationSection(_ station: DiningStation) -> some View {
        let expanded = isFiltering || expandedStations.contains(station.id)
        let featured = station.featuredItems
        // Show featured items by default; stations with nothing featured
        // (salad bar, beverages) start collapsed unless they're short.
        let collapsedItems = featured.isEmpty ? (station.items.count <= 4 ? station.items : []) : featured
        let visible = expanded ? station.items : collapsedItems
        let hiddenCount = station.items.count - visible.count

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(station.name).font(Typography.sectionTitle).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(station.items.count) item\(station.items.count == 1 ? "" : "s")")
                    .font(Typography.caption).foregroundStyle(Theme.secondaryText)
            }
            if !station.note.isEmpty {
                Text(station.note).font(Typography.caption).foregroundStyle(Theme.secondaryText)
            }
            ForEach(visible) { item in
                Button { selectedItem = item } label: { DiningItemRow(item: item) }
                    .buttonStyle(.plain)
            }
            if !isFiltering && (hiddenCount > 0 || expandedStations.contains(station.id)) {
                Button(expanded ? "Show fewer" : "Show \(hiddenCount) more") {
                    if expanded { expandedStations.remove(station.id) } else { expandedStations.insert(station.id) }
                }
                .font(Typography.label).foregroundStyle(Theme.cardinal)
            }
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text("From Bon Appétit’s published menu. Items and labels can change, and dishes may share equipment with allergens. Ask dining staff about your dietary needs.")
                .font(Typography.caption).foregroundStyle(Theme.secondaryText)
            if officialURL != nil {
                Button("Open on Bon Appétit") { showingOfficialPage = true }.font(Typography.bodySmall)
            }
        }
    }

    // MARK: Loading

    private func load(force: Bool) async {
        guard let slug = venue?.menuURLSlug else {
            meals = []
            error = "This location doesn’t publish a menu."
            return
        }
        let key = dateKey
        loading = true
        defer { loading = false }
        do {
            let result = try await DiningMenuService.shared.meals(slug: slug, dateKey: key, forceRefresh: force)
            guard key == dateKey, !Task.isCancelled else { return }
            meals = result
            error = nil
            if selectedMealID == nil || !result.contains(where: { $0.id == selectedMealID }) {
                let calendar = DiningVenue.calendar
                let now = Date()
                let minute = dayOffset == 0 ? calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now) : nil
                selectedMealID = BonAppetitMenu.defaultMeal(result, minuteOfDay: minute)?.id
            }
        } catch is CancellationError {
            return
        } catch {
            guard key == dateKey, !Task.isCancelled else { return }
            meals = []
            self.error = (error as? URLError)?.code == .notConnectedToInternet
                ? "You’re offline. Connect to load the menu."
                : "Couldn’t load the menu right now."
        }
    }
}

// MARK: - Item views

struct DiningItemRow: View {
    let item: DiningMenuItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(Typography.bodyEmphasized).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                if !item.details.isEmpty {
                    Text(item.details.replacingOccurrences(of: "\n", with: " · "))
                        .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                        .lineLimit(2).multilineTextAlignment(.leading)
                }
                if !item.dietary.isEmpty { DietaryTags(labels: item.dietary) }
            }
            Spacer(minLength: 8)
            if let calories = item.calories {
                Text("\(calories) cal").font(Typography.caption).foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows details and nutrition")
    }
}

struct DietaryTags: View {
    let labels: [String]

    var body: some View {
        // Wraps onto extra lines on narrow screens.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) { tags }
            VStack(alignment: .leading, spacing: 4) { tags }
        }
    }

    @ViewBuilder private var tags: some View {
        ForEach(labels, id: \.self) { label in
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(color(for: label))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color(for: label).opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private func color(for label: String) -> Color {
        switch label {
        case DiningDiet.vegan.label, DiningDiet.vegetarian.label: Theme.success
        case DiningDiet.withoutGluten.label: Theme.blueAccent
        default: Theme.secondaryText
        }
    }
}

struct DiningItemDetail: View {
    let item: DiningMenuItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name).font(.title3.bold())
                        if !item.details.isEmpty { Text(item.details).font(Typography.body) }
                        if !item.dietary.isEmpty { DietaryTags(labels: item.dietary) }
                    }.padding(.vertical, 4)
                }
                if !item.nutrients.isEmpty {
                    Section("Nutrition") {
                        ForEach(item.nutrients, id: \.label) { nutrient in
                            LabeledContent(nutrient.label, value: nutrient.amount)
                        }
                    }
                } else if let calories = item.calories {
                    Section("Nutrition") { LabeledContent("Calories", value: calories) }
                }
                Section {
                    Text("Labels come from Bon Appétit. Recipes and ingredients can change, and food may be prepared alongside allergens. If you have an allergy, confirm with dining staff before eating.")
                        .font(Typography.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Menu item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(Theme.cardinal)
        .presentationDetents([.medium, .large])
    }
}

struct OfficialDiningMenu: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
