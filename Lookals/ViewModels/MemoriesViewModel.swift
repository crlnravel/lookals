//
//  MemoriesViewModel.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class MemoriesViewModel {
    private(set) var albums: [MemoryAlbum]
    private(set) var memoryImages: [UUID: UIImage]
    private(set) var syncingAlbumIDs: Set<UUID>
    private(set) var cloudErrorMessage: String?

    private let memoryPhotoService: any MemoryPhotoServicing

    init(memoryPhotoService: any MemoryPhotoServicing = LocalMemoryPhotoService.shared) {
        self.albums = [.sampleHypeRadarMap]
        self.memoryImages = [:]
        self.syncingAlbumIDs = []
        self.cloudErrorMessage = nil
        self.memoryPhotoService = memoryPhotoService
    }

    init(
        albums: [MemoryAlbum],
        memoryPhotoService: any MemoryPhotoServicing = LocalMemoryPhotoService.shared
    ) {
        self.albums = albums
        self.memoryImages = [:]
        self.syncingAlbumIDs = []
        self.cloudErrorMessage = nil
        self.memoryPhotoService = memoryPhotoService
    }

    func album(for id: UUID) -> MemoryAlbum? {
        albums.first { $0.id == id }
    }

    func photo(for id: UUID) -> MemoryPhoto? {
        albums
            .lazy
            .flatMap(\.photos)
            .first { $0.id == id }
    }

    func album(containing photoID: UUID) -> MemoryAlbum? {
        albums.first { album in
            album.photos.contains { $0.id == photoID }
        }
    }

    func memoryImage(for id: UUID) -> UIImage? {
        memoryImages[id]
    }

    @discardableResult
    func addCapturedPhoto(_ image: UIImage, to albumID: UUID) async -> MemoryPhoto? {
        guard let albumIndex = albums.firstIndex(where: { $0.id == albumID }) else {
            return nil
        }

        let album = albums[albumIndex]
        let createdAt = Date.now

        do {
            let cloudPhoto = try await memoryPhotoService.saveMemoryPhoto(
                image: image,
                albumPartitionID: album.partitionID,
                title: album.title,
                createdAt: createdAt
            )
            let photo = memoryPhoto(from: cloudPhoto, fallbackImage: image)

            insertOrReplace(photo, in: albumID)
            cloudErrorMessage = nil
            return photo
        } catch {
            cloudErrorMessage = error.localizedDescription
            return nil
        }
    }

    func loadCloudPhotos(for albumID: UUID) async {
        guard let album = album(for: albumID),
              !syncingAlbumIDs.contains(albumID) else {
            return
        }

        syncingAlbumIDs.insert(albumID)
        defer {
            syncingAlbumIDs.remove(albumID)
        }

        do {
            let cloudPhotos = try await memoryPhotoService.fetchMemoryPhotos(
                albumPartitionID: album.partitionID
            )
            cloudPhotos
                .map { memoryPhoto(from: $0) }
                .forEach { insertOrReplace($0, in: albumID) }
            cloudErrorMessage = nil
        } catch {
            cloudErrorMessage = error.localizedDescription
        }
    }

    private func memoryPhoto(
        from cloudPhoto: CloudMemoryPhoto,
        fallbackImage: UIImage? = nil
    ) -> MemoryPhoto {
        if let image = UIImage(data: cloudPhoto.imageData) ?? fallbackImage {
            memoryImages[cloudPhoto.id] = image
        }

        return MemoryPhoto(
            id: cloudPhoto.id,
            title: cloudPhoto.title,
            time: Self.captureTimeString(from: cloudPhoto.createdAt),
            source: .cloud(cloudPhoto.id),
            accessibilityLabel: "Cloud memory photo"
        )
    }

    private func insertOrReplace(_ photo: MemoryPhoto, in albumID: UUID) {
        guard let albumIndex = albums.firstIndex(where: { $0.id == albumID }) else {
            return
        }

        if let photoIndex = albums[albumIndex].photos.firstIndex(where: { $0.id == photo.id }) {
            albums[albumIndex].photos[photoIndex] = photo
        } else {
            albums[albumIndex].photos.insert(photo, at: 0)
        }
    }

    private static func captureTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH.mm"
        return formatter.string(from: date)
    }
}

private extension MemoryAlbum {
    static var sampleHypeRadarMap: MemoryAlbum {
        MemoryAlbum(
            id: UUID(uuidString: "8CE8D91C-C8A0-42FC-9610-62DF35A0C60D")!,
            partitionID: "hype-radar-map",
            title: "Hype Radar Map",
            coverSource: .asset("Memory Album Cover"),
            photos: [
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.02",
                    source: .asset("Memory Photo 1"),
                    accessibilityLabel: "Friends taking a selfie by a bridge"
                ),
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.07",
                    source: .asset("Memory Photo 2"),
                    accessibilityLabel: "Friends posing together on stairs"
                ),
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.18",
                    source: .asset("Memory Photo 3"),
                    accessibilityLabel: "Friends sharing drinks around a table"
                ),
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.31",
                    source: .asset("Memory Photo 4"),
                    accessibilityLabel: "Friends posing together at night"
                ),
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.43",
                    source: .asset("Memory Photo 5"),
                    accessibilityLabel: "Friends taking a mirror photo outdoors"
                ),
                MemoryPhoto(
                    title: "Kelontong Poet Tea",
                    time: "14.56",
                    source: .asset("Memory Photo 6"),
                    accessibilityLabel: "Friends lying on the ground in a star shape"
                )
            ]
        )
    }
}
