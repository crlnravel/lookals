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
        if participantID == BSDTourConfiguration.currentUserID {
            next.userJoined = true
        }
        return next
    }

    func joinNextMockParticipant(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        guard let nextMock = snapshot.participants.first(where: { !$0.isCurrentUser && $0.status == .invited }) else {
            return snapshot
        }

        var next = join(participantID: nextMock.id, in: snapshot)
        positionJoinedMocksNearCurrentUser(in: &next)
        return next
    }

    func joinAllParticipants(in snapshot: BSDTourSnapshot) -> BSDTourSnapshot {
        var next = snapshot
        guard !next.waitingRoomClosed else {
            return snapshot
        }

        for index in next.participants.indices where next.participants[index].status != .removed {
            next.participants[index].status = .joined
        }

        next.userJoined = next.participants.contains { $0.id == BSDTourConfiguration.currentUserID && $0.status == .joined }
        positionJoinedMocksNearCurrentUser(in: &next)
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

    private func positionJoinedMocksNearCurrentUser(in snapshot: inout BSDTourSnapshot) {
        guard let currentUser = snapshot.participants.first(where: \.isCurrentUser) else { return }

        let offsetsByParticipantID: [String: (latitude: Double, longitude: Double)] = [
            "zee": (0.00005, 0.00007),
            "gisella": (-0.00005, 0.00007),
            "kevin": (0.00006, -0.00005)
        ]
        let joinedMockIndexes = snapshot.participants.indices.filter {
            !snapshot.participants[$0].isCurrentUser && snapshot.participants[$0].status == .joined
        }

        for participantIndex in joinedMockIndexes {
            let participantID = snapshot.participants[participantIndex].id
            guard let offset = offsetsByParticipantID[participantID] else { continue }
            snapshot.participants[participantIndex].coordinate = BSDTourCoordinate(
                latitude: currentUser.coordinate.latitude + offset.latitude,
                longitude: currentUser.coordinate.longitude + offset.longitude
            )
        }
    }
}
