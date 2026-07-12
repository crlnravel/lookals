//
//  MemoryPhoto.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation

struct MemoryPhoto: Identifiable, Hashable {
    let id: UUID
    var title: String
    var time: String
    var source: MemoryImageSource
    var accessibilityLabel: String

    init(
        id: UUID = UUID(),
        title: String,
        time: String,
        source: MemoryImageSource,
        accessibilityLabel: String
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.source = source
        self.accessibilityLabel = accessibilityLabel
    }
}
