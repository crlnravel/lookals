//
//  CloudMemoryService.swift
//  Lookals
//
//  Created by Codex on 10/07/26.
//

import CloudKit
import UIKit

actor CloudMemoryService: MemoryPhotoServicing {
    static let shared = CloudMemoryService()

    private enum Field {
        static let albumPartitionID = "albumPartitionID"
        static let title = "title"
        static let createdAt = "createdAt"
        static let image = "image"
    }

    private static let recordType = "MemoryPhoto"
    private static let desiredKeys = [
        Field.albumPartitionID,
        Field.title,
        Field.createdAt,
        Field.image
    ]

    private let database: CKDatabase

    init(
        container: CKContainer = .default(),
        databaseScope: CKDatabase.Scope = .public
    ) {
        self.database = container.database(with: databaseScope)
    }

    func saveMemoryPhoto(
        image: UIImage,
        albumPartitionID: String,
        title: String,
        createdAt: Date
    ) async throws -> CloudMemoryPhoto {
        let photoID = UUID()
        let assetFileURL = try Self.writeJPEGAsset(image, photoID: photoID)
        defer {
            try? FileManager.default.removeItem(at: assetFileURL)
        }

        let record = CKRecord(
            recordType: Self.recordType,
            recordID: CKRecord.ID(recordName: photoID.uuidString)
        )
        record[Field.albumPartitionID] = albumPartitionID as CKRecordValue
        record[Field.title] = title as CKRecordValue
        record[Field.createdAt] = createdAt as CKRecordValue
        record[Field.image] = CKAsset(fileURL: assetFileURL)

        let savedRecord = try await database.save(record)
        return try Self.memoryPhoto(from: savedRecord)
    }

    func fetchMemoryPhotos(albumPartitionID: String) async throws -> [CloudMemoryPhoto] {
        let predicate = NSPredicate(
            format: "%K == %@",
            Field.albumPartitionID,
            albumPartitionID
        )
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: Field.createdAt, ascending: false)
        ]

        let records = try await fetchRecords(matching: query)
        return try records.map(Self.memoryPhoto(from:))
    }

    private func fetchRecords(matching query: CKQuery) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        let firstBatch = try await database.records(
            matching: query,
            desiredKeys: Self.desiredKeys,
            resultsLimit: 100
        )

        records.append(contentsOf: Self.successfulRecords(from: firstBatch.matchResults))

        var cursor = firstBatch.queryCursor
        while let nextCursor = cursor {
            let nextBatch = try await database.records(
                continuingMatchFrom: nextCursor,
                desiredKeys: Self.desiredKeys,
                resultsLimit: 100
            )
            records.append(contentsOf: Self.successfulRecords(from: nextBatch.matchResults))
            cursor = nextBatch.queryCursor
        }

        return records
    }

    private static func successfulRecords(
        from matchResults: [(CKRecord.ID, Result<CKRecord, Error>)]
    ) -> [CKRecord] {
        matchResults.compactMap { _, result in
            try? result.get()
        }
    }

    private static func memoryPhoto(from record: CKRecord) throws -> CloudMemoryPhoto {
        guard let albumPartitionID = record[Field.albumPartitionID] as? String,
              let title = record[Field.title] as? String,
              let createdAt = record[Field.createdAt] as? Date,
              let asset = record[Field.image] as? CKAsset,
              let fileURL = asset.fileURL else {
            throw MemoryPhotoServiceError.invalidRecord
        }

        let imageData = try Data(contentsOf: fileURL)
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()

        return CloudMemoryPhoto(
            id: id,
            recordName: record.recordID.recordName,
            albumPartitionID: albumPartitionID,
            title: title,
            createdAt: createdAt,
            imageData: imageData
        )
    }

    private static func writeJPEGAsset(_ image: UIImage, photoID: UUID) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw MemoryPhotoServiceError.imageEncodingFailed
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "\(photoID.uuidString).jpg")
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }
}
