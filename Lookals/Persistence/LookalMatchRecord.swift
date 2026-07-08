//
//  LookalMatchRecord.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation
import SwiftData

@Model
final class LookalMatchRecord {
    var id: UUID
    var name: String
    var resemblanceScore: Int
    var category: String

    init(
        id: UUID,
        name: String,
        resemblanceScore: Int,
        category: String
    ) {
        self.id = id
        self.name = name
        self.resemblanceScore = resemblanceScore
        self.category = category
    }

    convenience init(match: LookalMatch) {
        self.init(
            id: match.id,
            name: match.name,
            resemblanceScore: match.resemblanceScore,
            category: match.category
        )
    }

    var lookalMatch: LookalMatch {
        LookalMatch(
            id: id,
            name: name,
            resemblanceScore: resemblanceScore,
            category: category
        )
    }
}
