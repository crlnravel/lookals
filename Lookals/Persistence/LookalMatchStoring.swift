//
//  LookalMatchStoring.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

protocol LookalMatchStoring: Sendable {
    func fetchMatches() async throws -> [LookalMatch]
    func saveMatches(_ matches: [LookalMatch]) async throws
    func removeAllMatches() async throws
}
