//
//  MemoryPhotoServicing.swift
//  Lookals
//
//  Created by Codex on 12/07/26.
//

import UIKit

protocol MemoryPhotoServicing: Sendable {
    func saveMemoryPhoto(
        image: UIImage,
        albumPartitionID: String,
        title: String,
        createdAt: Date
    ) async throws -> CloudMemoryPhoto

    func fetchMemoryPhotos(albumPartitionID: String) async throws -> [CloudMemoryPhoto]
}

enum MemoryPhotoServiceError: LocalizedError {
    case imageEncodingFailed
    case invalidRecord

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            "Lookals could not prepare this photo for upload."
        case .invalidRecord:
            "Lookals received an incomplete memory photo."
        }
    }
}
