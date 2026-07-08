//
//  DefaultLookalMatchRepository.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

struct DefaultLookalMatchRepository: LookalMatchRepository {
    private let service: any LookalMatchingServicing
    private let store: any LookalMatchStoring

    init(
        service: any LookalMatchingServicing,
        store: any LookalMatchStoring
    ) {
        self.service = service
        self.store = store
    }

    func fetchMatches(refresh: Bool = false) async throws -> [LookalMatch] {
        let cachedMatches = try await store.fetchMatches()

        if !refresh, !cachedMatches.isEmpty {
            return cachedMatches
        }

        let remoteMatches = try await service.fetchMatches()
        try await store.saveMatches(remoteMatches)
        return remoteMatches
    }
}
