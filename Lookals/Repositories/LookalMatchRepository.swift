//
//  LookalMatchRepository.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

protocol LookalMatchRepository: Sendable {
    func fetchMatches(refresh: Bool) async throws -> [LookalMatch]
}
