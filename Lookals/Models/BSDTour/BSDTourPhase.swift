//
//  BSDTourPhase.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

nonisolated enum BSDTourPhase: String, Codable, Sendable {
    case navigatingToMeetingPoint
    case waitingToShake
    case joinedWaitingRoom
    case unavailable
    case quest
    case questSuccess
    case navigatingToCheckpoint
    case tourCompleted
    case tourEnded
}
