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
    func loadSnapshot(tourID: String) async throws -> BSDTourSnapshot? {
        var descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == tourID }
        )
        descriptor.fetchLimit = 1

        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return try JSONDecoder().decode(BSDTourSnapshot.self, from: record.payload)
    }

    func saveSnapshot(_ snapshot: BSDTourSnapshot) async throws {
        let payload = try JSONEncoder().encode(snapshot)
        var descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == snapshot.tourID }
        )
        descriptor.fetchLimit = 1

        if let record = try modelContext.fetch(descriptor).first {
            record.updatedAt = Date()
            record.payload = payload
        } else {
            modelContext.insert(
                BSDTourStateRecord(
                    id: snapshot.tourID,
                    updatedAt: Date(),
                    payload: payload
                )
            )
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func reset(tourID: String) async throws {
        let descriptor = FetchDescriptor<BSDTourStateRecord>(
            predicate: #Predicate { $0.id == tourID }
        )

        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
