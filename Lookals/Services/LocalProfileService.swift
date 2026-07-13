//
//  LocalProfileService.swift
//  Lookals
//
//  Created by Codex on 13/07/26.
//

import Foundation

actor LocalProfileService: ProfileServicing {
    static let shared = LocalProfileService()

    private let profileURL: URL
    private let profileImageURL: URL

    init(
        rootDirectoryURL: URL = .applicationSupportDirectory
            .appending(path: "Lookals/Profile", directoryHint: .isDirectory)
    ) {
        self.profileURL = rootDirectoryURL.appending(path: "profile.json")
        self.profileImageURL = rootDirectoryURL.appending(path: "profile-image.data")
    }

    func loadProfile() async throws -> User? {
        guard FileManager.default.fileExists(atPath: profileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: profileURL)
        var user = try JSONDecoder().decode(User.self, from: data)

        if FileManager.default.fileExists(atPath: profileImageURL.path) {
            user.customImageData = try Data(contentsOf: profileImageURL)
        }

        return user
    }

    func saveProfile(_ user: User) async throws {
        var storedUser = user
        let imageData = storedUser.customImageData
        storedUser.customImageData = nil

        try FileManager.default.createDirectory(
            at: profileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(storedUser)
        try data.write(to: profileURL, options: [.atomic])

        if let imageData {
            try imageData.write(to: profileImageURL, options: [.atomic])
        } else if FileManager.default.fileExists(atPath: profileImageURL.path) {
            try FileManager.default.removeItem(at: profileImageURL)
        }
    }
}
