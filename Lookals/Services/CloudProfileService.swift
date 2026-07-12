//
//  CloudProfileService.swift
//  Lookals
//
//  Created by Codex on 13/07/26.
//

import CloudKit
import Foundation

actor CloudProfileService: ProfileServicing {
    static let shared = CloudProfileService()

    private enum Field {
        static let payload = "payload"
        static let profileImage = "profileImage"
    }

    nonisolated private static let recordType = "UserProfile"
    nonisolated private static let recordID = CKRecord.ID(recordName: "current-user-profile")

    private let database: CKDatabase

    init(
        container: CKContainer = .default(),
        databaseScope: CKDatabase.Scope = .private
    ) {
        self.database = container.database(with: databaseScope)
    }

    func loadProfile() async throws -> User? {
        guard let record = try await fetchProfileRecord() else {
            return nil
        }

        let payloadValue = record[Field.payload]
        let payload = payloadValue as? Data
            ?? (payloadValue as? NSData).map { Data(referencing: $0) }

        guard let payload else {
            throw ProfileServiceError.invalidRecord
        }

        var user = try JSONDecoder().decode(User.self, from: payload)
        if let asset = record[Field.profileImage] as? CKAsset,
           let fileURL = asset.fileURL,
           let imageData = try? Data(contentsOf: fileURL) {
            user.customImageData = imageData
        }

        return user
    }

    func saveProfile(_ user: User) async throws {
        var storedUser = user
        let imageData = storedUser.customImageData
        storedUser.customImageData = nil

        let payload = try JSONEncoder().encode(storedUser)
        let record = try await fetchProfileRecord()
            ?? CKRecord(recordType: Self.recordType, recordID: Self.recordID)

        record[Field.payload] = payload as NSData

        let imageFileURL: URL?
        if let imageData {
            let fileURL = FileManager.default.temporaryDirectory
                .appending(path: "\(UUID().uuidString).jpg")
            try imageData.write(to: fileURL, options: [.atomic])
            record[Field.profileImage] = CKAsset(fileURL: fileURL)
            imageFileURL = fileURL
        } else {
            record[Field.profileImage] = nil
            imageFileURL = nil
        }

        defer {
            if let imageFileURL {
                try? FileManager.default.removeItem(at: imageFileURL)
            }
        }

        _ = try await database.save(record)
    }

    private func fetchProfileRecord() async throws -> CKRecord? {
        do {
            return try await database.record(for: Self.recordID)
        } catch {
            if let cloudKitError = error as? CKError,
               cloudKitError.code == .unknownItem {
                return nil
            }

            throw error
        }
    }
}
