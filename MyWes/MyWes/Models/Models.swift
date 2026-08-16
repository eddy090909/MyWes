//
//  Models.swift
//  MyWes
//

import Foundation

struct AppUser: Identifiable, Equatable {
    var id: UUID
    var email: String
    var firstName: String
    var classYear: String?
    var interests: [String]
    var followedOrgIDs: Set<UUID>
}

struct Event: Identifiable, Equatable {
    var id: UUID
    var title: String
    var category: String
    var dateLabel: String
    var time: String
    var location: String
    var orgID: UUID
    var description: String

    /// Temporary display split of `dateLabel` (e.g. "Fri, Sep 12" → "SEP" / "12").
    /// Replace with real `start_at` formatting when events are loaded from Supabase.
    var monthLabel: String {
        dateParts.month
    }

    var dayNumber: String {
        dateParts.day
    }

    private var dateParts: (month: String, day: String) {
        let cleaned = dateLabel.replacingOccurrences(of: ",", with: "")
        let parts = cleaned.split(separator: " ").map(String.init)
        guard parts.count >= 3 else { return ("", "") }
        return (parts[1].uppercased(), parts[2])
    }
}

struct Organization: Identifiable, Equatable {
    var id: UUID
    var name: String
    var category: String
    var memberCount: Int
    var description: String
    var contactEmail: String? = nil
    var instagramHandle: String? = nil
}

struct DiningLocation: Identifiable, Equatable {
    var id: UUID
    var name: String
    var hoursText: String
    var isOpen: Bool
    var rating: Double
}

struct Question: Identifiable, Equatable {
    var id: UUID
    var title: String
    var topic: String
    var voteCount: Int
    var answerCount: Int
}

struct OrgUpdate: Identifiable, Equatable {
    var id: UUID { orgID }
    var orgID: UUID
    var orgName: String
    var updateText: String
}
