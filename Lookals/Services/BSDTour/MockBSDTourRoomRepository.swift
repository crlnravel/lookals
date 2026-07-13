//
//  MockBSDTourRoomRepository.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

nonisolated struct MockBSDTourRoomRepository: BSDTourRoomRepository {
    func join(participantID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        guard !snapshot.waitingRoomClosed else {
            return snapshot
        }

        var next = snapshot
        guard let index = next.participants.firstIndex(where: { $0.id == participantID }) else {
            return snapshot
        }

        guard next.participants[index].status != .removed else {
            return snapshot
        }

        next.participants[index].status = .joined
        if next.participants[index].isCurrentUser {
            next.userJoined = true
        }
        return next
    }

    func joinNextMockParticipant(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        guard let nextMock = snapshot.participants.first(where: { !$0.isCurrentUser && $0.status == .invited }) else {
            return snapshot
        }

        return join(participantID: nextMock.id, in: snapshot)
    }

    func joinAllParticipants(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = snapshot
        guard !next.waitingRoomClosed else {
            return snapshot
        }

        for index in next.participants.indices where next.participants[index].status != .removed {
            next.participants[index].status = .joined
        }

        next.userJoined = next.participants.contains { $0.isCurrentUser && $0.status == .joined }
        return next
    }

    func joinAllParticipants(identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = joinAllParticipants(in: snapshot)
        next.userJoined = next.participants.contains { $0.id == identity.participantID && $0.status == .joined }
        return next
    }

    func removeUnjoinedParticipants(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = snapshot

        for index in next.participants.indices where next.participants[index].status == .invited {
            next.participants[index].status = .removed
        }

        return next
    }

    func completeQuest(_ questID: String, participantID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = snapshot
        var completion = next.questCompletions[questID] ?? BSDTourQuestCompletionSnapshot(
            completedParticipantIDs: [],
            completedByParticipantID: nil,
            isGroupComplete: false
        )

        guard !completion.completedParticipantIDs.contains(participantID) else {
            return snapshot
        }

        completion.completedParticipantIDs.append(participantID)
        completion.completedByParticipantID = completion.completedByParticipantID ?? participantID
        next.questCompletions[questID] = completion
        return next
    }

    func completeQuestForAllActiveParticipants(_ questID: String, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = snapshot
        let activeIDs = next.participants.filter(\.isActive).map(\.id)
        var completion = next.questCompletions[questID] ?? BSDTourQuestCompletionSnapshot(
            completedParticipantIDs: [],
            completedByParticipantID: nil,
            isGroupComplete: false
        )

        for id in activeIDs where !completion.completedParticipantIDs.contains(id) {
            completion.completedParticipantIDs.append(id)
        }

        completion.completedByParticipantID = completion.completedByParticipantID ?? activeIDs.first
        next.questCompletions[questID] = completion
        return next
    }

    func completeQuestForAllActiveParticipants(_ questID: String, identity: BSDTourSessionIdentity, in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        completeQuestForAllActiveParticipants(questID, in: snapshot)
    }
}
