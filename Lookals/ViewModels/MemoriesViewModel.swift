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
    private(set) var capturedImages: [UUID: UIImage]

    init() {
        self.albums = [.sampleHypeRadarMap]
        self.capturedImages = [:]
    }

    init(albums: [MemoryAlbum]) {
        self.albums = albums
        self.capturedImages = [:]
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

    func capturedImage(for id: UUID) -> UIImage? {
        capturedImages[id]
    }

    @discardableResult
    func addCapturedPhoto(_ image: UIImage, to albumID: UUID) -> MemoryPhoto? {
        guard let albumIndex = albums.firstIndex(where: { $0.id == albumID }) else {
            return nil
        }

        let imageID = UUID()
        capturedImages[imageID] = image

        let photo = MemoryPhoto(
            title: albums[albumIndex].title,
            time: Self.captureTimeString(from: Date.now),
            source: .captured(imageID),
            accessibilityLabel: "Captured memory photo"
        )

        albums[albumIndex].photos.insert(photo, at: 0)
        return photo
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
