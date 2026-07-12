//
//  InMemoryLookalMatchStore.swift
//  Lookals
//
//  Created by Codex on 11/07/26.
//

import Foundation

actor InMemoryLookalMatchStore: LookalMatchStoring {
    private var matches: [LookalMatch]

    init(matches: [LookalMatch] = []) {
        self.matches = matches
    }

    func fetchMatches() async throws -> [LookalMatch] {
        matches
    }

    func saveMatches(_ matches: [LookalMatch]) async throws {
        self.matches = matches
    }

    func removeAllMatches() async throws {
        matches.removeAll()
    }
}
