//
//  SwiftDataLookalMatchStore.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataLookalMatchStore: LookalMatchStoring {
    func fetchMatches() async throws -> [LookalMatch] {
        let descriptor = FetchDescriptor<LookalMatchRecord>(
            sortBy: [SortDescriptor(\.resemblanceScore, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return records.map(\.lookalMatch)
    }

    func saveMatches(_ matches: [LookalMatch]) async throws {
        try await removeAllMatches()

        for match in matches {
            modelContext.insert(LookalMatchRecord(match: match))
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func removeAllMatches() async throws {
        let records = try modelContext.fetch(FetchDescriptor<LookalMatchRecord>())

        for record in records {
            modelContext.delete(record)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
