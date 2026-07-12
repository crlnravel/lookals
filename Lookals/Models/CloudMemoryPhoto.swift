//
//  CloudMemoryPhoto.swift
//  Lookals
//
//  Created by Codex on 10/07/26.
//

import Foundation

struct CloudMemoryPhoto: Identifiable, Hashable {
    let id: UUID
    let recordName: String
    let albumPartitionID: String
    let title: String
    let createdAt: Date
    let imageData: Data
}
