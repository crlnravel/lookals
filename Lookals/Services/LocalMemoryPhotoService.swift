//
//  LocalMemoryPhotoService.swift
//  Lookals
//
//  Created by Codex on 12/07/26.
//

import UIKit

actor LocalMemoryPhotoService: MemoryPhotoServicing {
    static let shared = LocalMemoryPhotoService()

    private var photosByAlbumPartitionID: [String: [CloudMemoryPhoto]]

    init(photosByAlbumPartitionID: [String: [CloudMemoryPhoto]] = [:]) {
        self.photosByAlbumPartitionID = photosByAlbumPartitionID
    }

    func saveMemoryPhoto(
        image: UIImage,
        albumPartitionID: String,
        title: String,
        createdAt: Date
    ) async throws -> CloudMemoryPhoto {
        guard let imageData = image.jpegData(compressionQuality: 0.86) else {
            throw MemoryPhotoServiceError.imageEncodingFailed
        }

        let photoID = UUID()
        let photo = CloudMemoryPhoto(
            id: photoID,
            recordName: photoID.uuidString,
            albumPartitionID: albumPartitionID,
            title: title,
            createdAt: createdAt,
            imageData: imageData
        )

        photosByAlbumPartitionID[albumPartitionID, default: []].insert(photo, at: 0)
        return photo
    }

    func fetchMemoryPhotos(albumPartitionID: String) async throws -> [CloudMemoryPhoto] {
        (photosByAlbumPartitionID[albumPartitionID] ?? [])
            .sorted { $0.createdAt > $1.createdAt }
    }
}
