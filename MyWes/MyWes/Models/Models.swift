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
}

struct Organization: Identifiable, Equatable {
    var id: UUID
    var name: String
    var category: String
    var memberCount: Int
    var description: String
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
