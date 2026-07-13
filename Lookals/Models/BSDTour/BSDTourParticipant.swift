//
//  BSDTourParticipant.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

nonisolated enum BSDTourParticipantStatus: String, Codable, Sendable {
    case invited
    case joined
    case removed
}

nonisolated struct BSDTourParticipant: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var avatarImageName: String?
    var ringColorName: String
    var isCurrentUser: Bool
    var status: BSDTourParticipantStatus
    var coordinate: BSDTourCoordinate

    var hasJoined: Bool {
        status == .joined
    }

    var isActive: Bool {
        status == .joined
    }
}
