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

    init(
        lookalMatchRepository: any LookalMatchRepository,
        bsdTourPersistenceStore: any BSDTourPersistenceStore
    ) {
        self.lookalMatchRepository = lookalMatchRepository
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
        let store = SwiftDataLookalMatchStore(
            modelContainer: modelContainer
        )
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        let tourStore = SwiftDataBSDTourPersistenceStore(modelContainer: modelContainer)
        return AppDependencies(
            lookalMatchRepository: repository,
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
            bsdTourPersistenceStore: tourStore
        )
    }

    private static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            return try ModelContainer(
                for: LookalMatchRecord.self,
                BSDTourStateRecord.self,
                configurations: configuration
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error.localizedDescription)")
        }
    }
}
