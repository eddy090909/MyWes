//
//  MockData.swift
//  MyWes
//

import Foundation

enum MockData {
    // Stable UUIDs for cross-references
    enum IDs {
        static let org1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        static let org2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        static let org3 = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        static let org4 = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        static let org5 = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        static let org6 = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
        static let org7 = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
        static let org8 = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!

        static let evt1 = UUID(uuidString: "00000000-0000-0000-0001-000000000001")!
        static let evt2 = UUID(uuidString: "00000000-0000-0000-0001-000000000002")!
        static let evt3 = UUID(uuidString: "00000000-0000-0000-0001-000000000003")!
        static let evt4 = UUID(uuidString: "00000000-0000-0000-0001-000000000004")!
        static let evt5 = UUID(uuidString: "00000000-0000-0000-0001-000000000005")!
        static let evt6 = UUID(uuidString: "00000000-0000-0000-0001-000000000006")!

        static let d1 = UUID(uuidString: "00000000-0000-0000-0002-000000000001")!
        static let d2 = UUID(uuidString: "00000000-0000-0000-0002-000000000002")!
        static let d3 = UUID(uuidString: "00000000-0000-0000-0002-000000000003")!
        static let d4 = UUID(uuidString: "00000000-0000-0000-0002-000000000004")!

        static let q1 = UUID(uuidString: "00000000-0000-0000-0003-000000000001")!
        static let q2 = UUID(uuidString: "00000000-0000-0000-0003-000000000002")!
        static let q3 = UUID(uuidString: "00000000-0000-0000-0003-000000000003")!
        static let q4 = UUID(uuidString: "00000000-0000-0000-0003-000000000004")!
        static let q5 = UUID(uuidString: "00000000-0000-0000-0003-000000000005")!
        static let q6 = UUID(uuidString: "00000000-0000-0000-0003-000000000006")!
    }

    static let classYears = ["2027", "2028", "2029", "2030"]

    static let interests = [
        "Music",
        "Sports",
        "Community Service",
        "Tech & Startups",
        "Arts",
        "Sustainability",
        "Greek Life",
        "Research",
    ]

    static let organizations: [Organization] = [
        Organization(
            id: IDs.org1,
            name: "Wesleyan Student Assembly",
            category: "Governance",
            memberCount: 45,
            description: "The elected student government representing all Wesleyan undergraduates."
        ),
        Organization(
            id: IDs.org2,
            name: "WesWings Radio",
            category: "Media",
            memberCount: 60,
            description: "Student-run radio station broadcasting music, talk, and live event coverage."
        ),
        Organization(
            id: IDs.org3,
            name: "Fries Center for Global Studies",
            category: "Academic",
            memberCount: 20,
            description: "Supports study abroad, global fellowships, and international student life."
        ),
        Organization(
            id: IDs.org4,
            name: "First-Gen Network",
            category: "Community",
            memberCount: 80,
            description: "A community and resource hub for first-generation college students."
        ),
        Organization(
            id: IDs.org5,
            name: "Eclectic Society",
            category: "Social",
            memberCount: 35,
            description: "One of Wesleyan's program houses, known for concerts and community events."
        ),
        Organization(
            id: IDs.org6,
            name: "Career Center",
            category: "Academic",
            memberCount: 15,
            description: "Helps students find internships, jobs, and plan life after Wesleyan."
        ),
        Organization(
            id: IDs.org7,
            name: "Class of 2027 Council",
            category: "Governance",
            memberCount: 12,
            description: "Plans class events and represents first-years to the administration."
        ),
        Organization(
            id: IDs.org8,
            name: "Wesleyan Dining",
            category: "Campus Services",
            memberCount: 25,
            description: "Runs Usdan, Summerfield, and Pi Cafe, and coordinates dining events."
        ),
    ]

    /// Orgs shown during the onboarding follow step
    static let onboardingOrganizations: [Organization] = Array(organizations.prefix(4))

    static let events: [Event] = [
        Event(
            id: IDs.evt1,
            title: "Fall Formal Kickoff",
            category: "Social",
            dateLabel: "Fri, Sep 12",
            time: "8:00 PM",
            location: "Beckham Hall",
            orgID: IDs.org7,
            description: "Kick off the semester with music, food trucks, and the whole class of 2027. Dress: campus casual."
        ),
        Event(
            id: IDs.evt2,
            title: "AskWes Live: Internship Panel",
            category: "Academic",
            dateLabel: "Wed, Sep 17",
            time: "6:30 PM",
            location: "PAC Rm 001",
            orgID: IDs.org6,
            description: "Upperclassmen share how they landed summer internships in tech, finance, and research."
        ),
        Event(
            id: IDs.evt3,
            title: "Midnight Breakfast",
            category: "Dining",
            dateLabel: "Thu, Dec 10",
            time: "10:00 PM",
            location: "Usdan Marketplace",
            orgID: IDs.org8,
            description: "Free breakfast-for-dinner before finals, hosted by Dining Services and WSA."
        ),
        Event(
            id: IDs.evt4,
            title: "WesFest: First-Gen Mixer",
            category: "Community",
            dateLabel: "Sat, Sep 20",
            time: "2:00 PM",
            location: "Fauver Field",
            orgID: IDs.org4,
            description: "Meet other first-generation students and alumni mentors over lawn games and lunch."
        ),
        Event(
            id: IDs.evt5,
            title: "Battle of the Bands",
            category: "Social",
            dateLabel: "Sat, Oct 4",
            time: "9:00 PM",
            location: "Eclectic",
            orgID: IDs.org2,
            description: "Six student bands compete for a slot at Spring Fling."
        ),
        Event(
            id: IDs.evt6,
            title: "Study Abroad Info Night",
            category: "Academic",
            dateLabel: "Tue, Sep 23",
            time: "5:00 PM",
            location: "Allbritton 311",
            orgID: IDs.org3,
            description: "Learn about semester and year-long programs, funding, and how credits transfer."
        ),
    ]

    static let diningLocations: [DiningLocation] = [
        DiningLocation(id: IDs.d1, name: "Usdan Marketplace", hoursText: "7:30 AM – 8:00 PM", isOpen: true, rating: 4.1),
        DiningLocation(id: IDs.d2, name: "Summerfield", hoursText: "8:00 AM – 2:00 AM", isOpen: true, rating: 4.4),
        DiningLocation(id: IDs.d3, name: "Pi Cafe", hoursText: "8:00 AM – 11:00 PM", isOpen: true, rating: 4.6),
        DiningLocation(id: IDs.d4, name: "Weshop", hoursText: "9:00 AM – 12:00 AM", isOpen: false, rating: 4.0),
    ]

    static let questions: [Question] = [
        Question(id: IDs.q1, title: "How competitive is the CS major at Wesleyan?", topic: "Academics", voteCount: 34, answerCount: 2),
        Question(id: IDs.q2, title: "Best study abroad programs for econ majors?", topic: "Study Abroad", voteCount: 19, answerCount: 1),
        Question(id: IDs.q3, title: "Is it worth living in a program house?", topic: "Housing", voteCount: 27, answerCount: 1),
        Question(id: IDs.q4, title: "How do I get research with a professor?", topic: "Academics", voteCount: 41, answerCount: 2),
        Question(id: IDs.q5, title: "What's the vibe at Eclectic vs Earth House?", topic: "Campus Life", voteCount: 15, answerCount: 1),
        Question(id: IDs.q6, title: "Tips for landing a summer internship freshman year?", topic: "Careers", voteCount: 52, answerCount: 2),
    ]

    private static let orgUpdateCopy: [UUID: String] = [
        IDs.org1: "General Assembly tonight at 7 PM in Usdan 108.",
        IDs.org2: "New show schedule for the week is up.",
        IDs.org3: "Study abroad applications open next Monday.",
        IDs.org4: "Peer mentor sign-ups close Friday.",
        IDs.org5: "Open mic this Thursday — submit a song.",
        IDs.org6: "Resume drop-in hours Tue/Thu 1–4 PM.",
        IDs.org7: "Fall Formal Kickoff tickets go on sale soon.",
        IDs.org8: "Midnight Breakfast returns during finals week.",
    ]

    static var homeEvents: [Event] {
        Array(events.prefix(4))
    }

    static var homeDining: [DiningLocation] {
        Array(diningLocations.prefix(2))
    }

    static var popularQuestions: [Question] {
        Array(questions.sorted { $0.voteCount > $1.voteCount }.prefix(3))
    }

    static func updates(for followedOrgIDs: Set<UUID>) -> [OrgUpdate] {
        organizations
            .filter { followedOrgIDs.contains($0.id) }
            .prefix(3)
            .map { org in
                OrgUpdate(
                    orgID: org.id,
                    orgName: org.name,
                    updateText: orgUpdateCopy[org.id] ?? "New update posted."
                )
            }
    }

    static func defaultUser(email: String = "alex@wesleyan.edu", firstName: String = "Alex") -> AppUser {
        AppUser(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A001")!,
            email: email,
            firstName: firstName,
            classYear: "2027",
            interests: ["Music", "Tech & Startups"],
            followedOrgIDs: [IDs.org7]
        )
    }
}
