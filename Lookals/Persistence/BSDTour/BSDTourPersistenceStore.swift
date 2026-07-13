//
//  BSDTourPersistenceStore.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

protocol BSDTourPersistenceStore: Sendable {
    func load(session: BSDTourSessionIdentity) async throws -> BSDTourSnapshot?
    func save(_ snapshot: BSDTourSnapshot, for session: BSDTourSessionIdentity) async throws
    func reset(session: BSDTourSessionIdentity) async throws
}

nonisolated enum BSDTourPersistenceError: Error, Equatable, Sendable {
    case snapshotIdentityMismatch
}

extension BSDTourPersistenceStore {
    func loadSnapshot(tourID: String) async throws -> BSDTourSnapshot? { try await load(session: BSDTourSessionIdentity(tourID: tourID, participantID: BSDTourConfiguration.defaultParticipantID)) }
    func saveSnapshot(_ snapshot: BSDTourSnapshot) async throws { try await save(snapshot, for: BSDTourSessionIdentity(tourID: snapshot.tourID, participantID: BSDTourConfiguration.defaultParticipantID)) }
    func reset(tourID: String) async throws { try await reset(session: BSDTourSessionIdentity(tourID: tourID, participantID: BSDTourConfiguration.defaultParticipantID)) }
}

nonisolated struct BSDTourPersistedStateV2: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    let schemaVersion: Int
    let identity: BSDTourSessionIdentity
    let snapshot: BSDTourSnapshot

    init(identity: BSDTourSessionIdentity, snapshot: BSDTourSnapshot, schemaVersion: Int = currentSchemaVersion) {
        self.schemaVersion = schemaVersion
        self.identity = identity
        self.snapshot = snapshot
    }
}
