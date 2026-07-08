//
//  APIError.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The API URL is invalid."
        case .invalidResponse:
            "The server returned an invalid response."
        case .serverError(let statusCode):
            "The server returned status code \(statusCode)."
        case .decodingFailed:
            "The response could not be decoded."
        }
    }
}
