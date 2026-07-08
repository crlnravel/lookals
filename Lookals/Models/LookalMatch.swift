//
//  LookalMatch.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation

struct LookalMatch: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let resemblanceScore: Int
    let category: String

    init(
        id: UUID = UUID(),
        name: String,
        resemblanceScore: Int,
        category: String
    ) {
        self.id = id
        self.name = name
        self.resemblanceScore = resemblanceScore
        self.category = category
    }
}

extension LookalMatch {
    static let sampleMatches = [
        LookalMatch(name: "Alex", resemblanceScore: 92, category: "Style match"),
        LookalMatch(name: "Mika", resemblanceScore: 87, category: "Face shape"),
        LookalMatch(name: "Raya", resemblanceScore: 81, category: "Expression")
    ]
}
