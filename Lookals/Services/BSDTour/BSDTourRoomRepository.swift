//
//  BSDTourRoomRepository.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

protocol BSDTourRoomRepository: Sendable {
    func join(participantID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func joinNextMockParticipant(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func joinAllParticipants(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func joinAllParticipants(identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func removeUnjoinedParticipants(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func completeQuest(_ questID: String, participantID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func completeQuestForAllActiveParticipants(_ questID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
    func completeQuestForAllActiveParticipants(_ questID: String, identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot
}

extension BSDTourRoomRepository {
    func joinAllParticipants(identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot { joinAllParticipants(in: snapshot) }
    func completeQuestForAllActiveParticipants(_ questID: String, identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot { completeQuestForAllActiveParticipants(questID, in: snapshot) }
}
