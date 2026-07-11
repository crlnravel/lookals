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

    init(lookalMatchRepository: any LookalMatchRepository) {
        self.lookalMatchRepository = lookalMatchRepository
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
        return AppDependencies(lookalMatchRepository: repository)
    }

    static func live(baseURL: URL) -> AppDependencies {
        let apiClient = URLSessionAPIClient(baseURL: baseURL)
        let service = RemoteLookalMatchingService(apiClient: apiClient)
        let store = SwiftDataLookalMatchStore(
            modelContainer: makeModelContainer(isStoredInMemoryOnly: false)
        )
        let repository = DefaultLookalMatchRepository(service: service, store: store)
        return AppDependencies(lookalMatchRepository: repository)
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
