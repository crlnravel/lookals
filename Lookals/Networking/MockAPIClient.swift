//
//  MockAPIClient.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

struct MockAPIClient: APIClient {
    private let matches: [LookalMatch]

    init(matches: [LookalMatch] = LookalMatch.sampleMatches) {
        self.matches = matches
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint<Response>) async throws -> Response {
        guard Response.self == [LookalMatch].self,
              let response = matches as? Response else {
            throw APIError.invalidResponse
        }

        return response
    }
}
