//
//  MemoryAlbum.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation

struct MemoryAlbum: Identifiable, Hashable {
    let id: UUID
    var title: String
    var coverSource: MemoryImageSource
    var photos: [MemoryPhoto]

    init(
        id: UUID = UUID(),
        title: String,
        coverSource: MemoryImageSource,
        photos: [MemoryPhoto]
    ) {
        self.id = id
        self.title = title
        self.coverSource = coverSource
        self.photos = photos
    }
}
