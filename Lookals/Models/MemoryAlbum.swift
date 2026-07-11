//
//  MemoryAlbum.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation

struct MemoryAlbum: Identifiable, Hashable {
    let id: UUID
    let partitionID: String
    var title: String
    var coverSource: MemoryImageSource
    var photos: [MemoryPhoto]

    init(
        id: UUID = UUID(),
        partitionID: String? = nil,
        title: String,
        coverSource: MemoryImageSource,
        photos: [MemoryPhoto]
    ) {
        self.id = id
        self.partitionID = partitionID ?? id.uuidString
        self.title = title
        self.coverSource = coverSource
        self.photos = photos
    }
}
