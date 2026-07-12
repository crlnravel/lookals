//
//  LocalMemoryPhotoService.swift
//  Lookals
//
//  Created by Codex on 12/07/26.
//

import UIKit

actor LocalMemoryPhotoService: MemoryPhotoServicing {
    static let shared = LocalMemoryPhotoService()

    private struct StoredPhoto: Codable {
        let id: UUID
        let recordName: String
        let albumPartitionID: String
        let title: String
        let createdAt: Date
        let imageFilename: String
    }

    private let metadataURL: URL
    private let imageDirectoryURL: URL
    private var photosByAlbumPartitionID: [String: [StoredPhoto]]?

    init(
        rootDirectoryURL: URL = .applicationSupportDirectory
            .appending(path: "Lookals/LocalMemoryPhotos", directoryHint: .isDirectory)
    ) {
        self.metadataURL = rootDirectoryURL.appending(path: "metadata.json")
        self.imageDirectoryURL = rootDirectoryURL.appending(path: "Images", directoryHint: .isDirectory)
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

        var photosByAlbumPartitionID = try loadPhotosByAlbumPartitionID()
        let photoID = UUID()
        let imageFilename = "\(photoID.uuidString).jpg"
        let storedPhoto = StoredPhoto(
            id: photoID,
            recordName: photoID.uuidString,
            albumPartitionID: albumPartitionID,
            title: title,
            createdAt: createdAt,
            imageFilename: imageFilename
        )

        try FileManager.default.createDirectory(
            at: imageDirectoryURL,
            withIntermediateDirectories: true
        )
        try imageData.write(
            to: imageURL(for: imageFilename),
            options: [.atomic]
        )

        photosByAlbumPartitionID[albumPartitionID, default: []].insert(storedPhoto, at: 0)
        try savePhotosByAlbumPartitionID(photosByAlbumPartitionID)

        return CloudMemoryPhoto(
            id: storedPhoto.id,
            recordName: storedPhoto.recordName,
            albumPartitionID: storedPhoto.albumPartitionID,
            title: storedPhoto.title,
            createdAt: storedPhoto.createdAt,
            imageData: imageData
        )
    }

    func fetchMemoryPhotos(albumPartitionID: String) async throws -> [CloudMemoryPhoto] {
        try loadPhotosByAlbumPartitionID()[albumPartitionID, default: []]
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap(cloudMemoryPhoto)
    }

    private func loadPhotosByAlbumPartitionID() throws -> [String: [StoredPhoto]] {
        if let photosByAlbumPartitionID {
            return photosByAlbumPartitionID
        }

        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            photosByAlbumPartitionID = [:]
            return [:]
        }

        let data = try Data(contentsOf: metadataURL)
        let decodedPhotos = try JSONDecoder().decode([String: [StoredPhoto]].self, from: data)
        photosByAlbumPartitionID = decodedPhotos
        return decodedPhotos
    }

    private func savePhotosByAlbumPartitionID(
        _ photosByAlbumPartitionID: [String: [StoredPhoto]]
    ) throws {
        try FileManager.default.createDirectory(
            at: metadataURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(photosByAlbumPartitionID)
        try data.write(to: metadataURL, options: [.atomic])
        self.photosByAlbumPartitionID = photosByAlbumPartitionID
    }

    private func cloudMemoryPhoto(from storedPhoto: StoredPhoto) -> CloudMemoryPhoto? {
        guard let imageData = try? Data(contentsOf: imageURL(for: storedPhoto.imageFilename)) else {
            return nil
        }

        return CloudMemoryPhoto(
            id: storedPhoto.id,
            recordName: storedPhoto.recordName,
            albumPartitionID: storedPhoto.albumPartitionID,
            title: storedPhoto.title,
            createdAt: storedPhoto.createdAt,
            imageData: imageData
        )
    }

    private func imageURL(for imageFilename: String) -> URL {
        imageDirectoryURL.appending(path: imageFilename)
    }
}
