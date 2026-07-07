//
//  MockLookalMatchingService.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation

struct MockLookalMatchingService: LookalMatchingServicing {
    func fetchMatches() async throws -> [LookalMatch] {
        [
            LookalMatch(name: "Alex", resemblanceScore: 92, category: "Style match"),
            LookalMatch(name: "Mika", resemblanceScore: 87, category: "Face shape"),
            LookalMatch(name: "Raya", resemblanceScore: 81, category: "Expression")
        ]
    }
}
