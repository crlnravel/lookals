//
//  InMemoryLookalMatchStore.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

actor InMemoryLookalMatchStore: LookalMatchStoring {
    private var cachedMatches: [LookalMatch]

    init(cachedMatches: [LookalMatch] = []) {
        self.cachedMatches = cachedMatches
    }

    func fetchMatches() async throws -> [LookalMatch] {
        cachedMatches
    }

    func saveMatches(_ matches: [LookalMatch]) async throws {
        cachedMatches = matches
    }

    func removeAllMatches() async throws {
        cachedMatches.removeAll()
    }
}
