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
    let memoryPhotoService: any MemoryPhotoServicing

    init(
        lookalMatchRepository: any LookalMatchRepository,
        memoryPhotoService: any MemoryPhotoServicing
    ) {
        self.lookalMatchRepository = lookalMatchRepository
        self.memoryPhotoService = memoryPhotoService
    }
}

extension AppDependencies {
    static var preview: AppDependencies {
        mock()
    }

    static func mock(matches: [LookalMatch] = LookalMatch.sampleMatches) -> AppDependencies {
        let service = MockLookalMatchingService(matches: matches)
        let store = InMemoryLookalMatchStore()
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        return AppDependencies(
            lookalMatchRepository: repository,
            memoryPhotoService: LocalMemoryPhotoService.shared
        )
    }

    static func live(baseURL: URL) -> AppDependencies {
        let apiClient = URLSessionAPIClient(baseURL: baseURL)
        let service = RemoteLookalMatchingService(apiClient: apiClient)
        let store = SwiftDataLookalMatchStore(
            modelContainer: makeModelContainer(isStoredInMemoryOnly: false)
        )
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        return AppDependencies(
            lookalMatchRepository: repository,
            memoryPhotoService: configuredMemoryPhotoService
        )
    }

    private static var configuredMemoryPhotoService: any MemoryPhotoServicing {
        #if LOOKALS_CLOUDKIT
        CloudMemoryService.shared
        #else
        LocalMemoryPhotoService.shared
        #endif
    }

    private static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            return try ModelContainer(
                for: LookalMatchRecord.self,
                configurations: configuration
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error.localizedDescription)")
        }
    }
}
