//
//  RemoteLookalMatchingService.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

struct RemoteLookalMatchingService: LookalMatchingServicing {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func fetchMatches() async throws -> [LookalMatch] {
        let endpoint = APIEndpoint<[LookalMatch]>(path: "matches")
        return try await apiClient.send(endpoint)
    }
}
