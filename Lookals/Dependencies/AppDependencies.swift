//
//  AppDependencies.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation
import SwiftData

struct AppDependencies: Sendable {
    let lookalMatchRepository: any LookalMatchRepository
    let bsdTourPersistenceStore: any BSDTourPersistenceStore
    let memoryPhotoService: any MemoryPhotoServicing
    let profileService: any ProfileServicing

    init(
        lookalMatchRepository: any LookalMatchRepository,
        memoryPhotoService: any MemoryPhotoServicing,
        profileService: any ProfileServicing,
        bsdTourPersistenceStore: any BSDTourPersistenceStore
    ) {
        self.lookalMatchRepository = lookalMatchRepository
        self.memoryPhotoService = memoryPhotoService
        self.profileService = profileService
        self.bsdTourPersistenceStore = bsdTourPersistenceStore
    }
}

extension AppDependencies {
    static var preview: AppDependencies {
        mock()
    }

    static func mock(
        matches: [LookalMatch] = LookalMatch.sampleMatches,
        isStoredInMemoryOnly: Bool = true
    ) -> AppDependencies {
        let service = MockLookalMatchingService(matches: matches)
        let modelContainer = makeModelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        let store = InMemoryLookalMatchStore()
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        let tourStore = SwiftDataBSDTourPersistenceStore(modelContainer: modelContainer)
        return AppDependencies(
            lookalMatchRepository: repository,
            memoryPhotoService: LocalMemoryPhotoService.shared,
            profileService: LocalProfileService.shared,
            bsdTourPersistenceStore: tourStore
        )
    }

    static func live(baseURL: URL) -> AppDependencies {
        let apiClient = URLSessionAPIClient(baseURL: baseURL)
        let service = RemoteLookalMatchingService(apiClient: apiClient)
        let modelContainer = makeModelContainer(isStoredInMemoryOnly: false)
        let store = SwiftDataLookalMatchStore(
            modelContainer: modelContainer
        )
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        let tourStore = SwiftDataBSDTourPersistenceStore(modelContainer: modelContainer)
        return AppDependencies(
            lookalMatchRepository: repository,
            memoryPhotoService: configuredMemoryPhotoService,
            profileService: configuredProfileService,
            bsdTourPersistenceStore: tourStore
        )
    }

    private static var configuredMemoryPhotoService: any MemoryPhotoServicing {
        #if LOOKALS_CLOUDKIT
        CloudMemoryService.shared
        #else
        LocalMemoryPhotoService.shared
        #endif
    }

    private static var configuredProfileService: any ProfileServicing {
        #if LOOKALS_CLOUDKIT
        CloudProfileService.shared
        #else
        LocalProfileService.shared
        #endif
    }

    // MARK: - Model Container
    private static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            LookalMatchRecord.self,
            BSDTourStateRecord.self
        ])
        let configuration = makeModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            return try ModelContainer(
                for: LookalMatchRecord.self,
                BSDTourStateRecord.self,
                configurations: configuration
            )
        } catch {
            print("SwiftData container creation failed (\(error.localizedDescription)). Deleting the local store and retrying with a fresh one.")

            deleteExistingStore(for: configuration)

            do {
                return try ModelContainer(
                    for: LookalMatchRecord.self,
                    BSDTourStateRecord.self,
                    configurations: configuration
                )
            } catch {
                print("SwiftData container reset failed (\(error.localizedDescription)). Falling back to in-memory persistence for this launch.")
                return makeInMemoryModelContainer(schema: schema)
            }
        }
    }

    private static func makeModelConfiguration(
        schema: Schema,
        isStoredInMemoryOnly: Bool
    ) -> ModelConfiguration {
        if isStoredInMemoryOnly {
            return ModelConfiguration(
                "LookalsStore",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        }

        return ModelConfiguration(
            "LookalsStore",
            schema: schema,
            url: persistentStoreURL(),
            cloudKitDatabase: .none
        )
    }

    private static func makeInMemoryModelContainer(schema: Schema) -> ModelContainer {
        let fallbackConfiguration = ModelConfiguration(
            "LookalsFallbackStore",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: LookalMatchRecord.self,
                BSDTourStateRecord.self,
                configurations: fallbackConfiguration
            )
        } catch {
            fatalError("Unable to create fallback in-memory SwiftData container: \(error.localizedDescription)")
        }
    }

    private static func persistentStoreURL() -> URL {
        let fileManager = FileManager.default

        do {
            let directory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return directory.appendingPathComponent("LookalsStore.sqlite")
        } catch {
            let directory = fileManager.temporaryDirectory
                .appendingPathComponent("Lookals", isDirectory: true)
            try? fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory.appendingPathComponent("LookalsStore.sqlite")
        }
    }

    /// Deletes the SQLite store file(s) backing a ModelConfiguration so a
    /// fresh ModelContainer can be created in its place. No-op for
    /// in-memory-only configurations, since there's no file to delete.
    private static func deleteExistingStore(for configuration: ModelConfiguration) {
        guard let storeURL = configuration.url as URL?,
              storeURL.isFileURL else {
            return
        }

        let fileManager = FileManager.default
        // SwiftData/Core Data stores are typically a trio: the main sqlite
        // file plus -wal and -shm sidecar files. Remove all three if present.
        let suffixes = ["", "-wal", "-shm"]

        for suffix in suffixes {
            let candidate = URL(fileURLWithPath: storeURL.path + suffix)
            if fileManager.fileExists(atPath: candidate.path) {
                try? fileManager.removeItem(at: candidate)
            }
        }
    }
}
