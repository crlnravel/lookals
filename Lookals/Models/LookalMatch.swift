//
//  LookalMatch.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation

struct LookalMatch: Identifiable, Equatable {
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
