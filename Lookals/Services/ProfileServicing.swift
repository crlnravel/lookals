//
//  ProfileServicing.swift
//  Lookals
//
//  Created by Codex on 13/07/26.
//

import Foundation

protocol ProfileServicing: Sendable {
    func loadProfile() async throws -> User?
    func saveProfile(_ user: User) async throws
}

enum ProfileServiceError: LocalizedError {
    case invalidRecord

    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            "Lookals received an incomplete profile."
        }
    }
}
