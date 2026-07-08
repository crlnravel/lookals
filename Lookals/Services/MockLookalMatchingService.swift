//
//  MockLookalMatchingService.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation

struct MockLookalMatchingService: LookalMatchingServicing {
    private let matches: [LookalMatch]

    init(matches: [LookalMatch] = LookalMatch.sampleMatches) {
        self.matches = matches
    }

    func fetchMatches() async throws -> [LookalMatch] {
        matches
    }
}
