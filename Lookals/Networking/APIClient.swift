//
//  APIClient.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

protocol APIClient: Sendable {
    func send<Response: Decodable>(_ endpoint: APIEndpoint<Response>) async throws -> Response
}
