//
//  SwiftDataBSDTourPersistenceStore.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataBSDTourPersistenceStore: BSDTourPersistenceStore {
    func load(session: BSDTourSessionIdentity) async throws -> BSDTourSnapshot? {
        let key = Self.storageKey(for: session)
        var descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == key }
        )
        descriptor.fetchLimit = 1

        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }

        guard let envelope = try? JSONDecoder().decode(BSDTourPersistedStateV2.self, from: record.payload),
              envelope.schemaVersion == BSDTourPersistedStateV2.currentSchemaVersion,
              envelope.identity == session,
              envelope.snapshot.tourID == session.tourID else {
            modelContext.delete(record)
            if modelContext.hasChanges { try modelContext.save() }
            return nil
        }
        return envelope.snapshot
    }

    func save(_ snapshot: BSDTourSnapshot, for session: BSDTourSessionIdentity) async throws {
        guard snapshot.tourID == session.tourID else { throw BSDTourPersistenceError.snapshotIdentityMismatch }
        let key = Self.storageKey(for: session)
        let payload = try JSONEncoder().encode(BSDTourPersistedStateV2(identity: session, snapshot: snapshot))
        var descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == key }
        )
        descriptor.fetchLimit = 1

        if let record = try modelContext.fetch(descriptor).first {
            record.updatedAt = Date()
            record.payload = payload
        } else {
            modelContext.insert(
                BSDTourStateRecord(
                    id: key,
                    updatedAt: Date(),
                    payload: payload
                )
            )
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func reset(session: BSDTourSessionIdentity) async throws {
        let key = Self.storageKey(for: session)
        let descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == key }
        )

        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    nonisolated static func storageKey(for session: BSDTourSessionIdentity) -> String {
        "bsd-tour-v2/\(session.tourID)/\(session.participantID)"
    }
}
