//
//  BSDTourSnapshot.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

nonisolated struct BSDTourQuestCompletionSnapshot: Codable, Equatable, Sendable {
    var completedParticipantIDs: [String]
    var completedByParticipantID: String?
    var isGroupComplete: Bool
}

nonisolated struct BSDTourSnapshot: Codable, Equatable, Sendable {
    var tourID: String
    var phase: BSDTourPhase
    var scheduledStartTime: Date
    var participants: [BSDTourParticipant]
    var currentCheckpointIndex: Int
    var currentQuestIndex: Int
    var currentStepIndex: Int
    var earnedPoints: Int
    var revealedCheckpointIDs: [String]
    var reachedCheckpointIDs: [String]
    var questCompletions: [String: BSDTourQuestCompletionSnapshot]
    var userJoined: Bool
    var waitingRoomClosed: Bool
    var tourCompleted: Bool
    var userEndedTour: Bool
}
