//
//  LookalMatchingServicing.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation

protocol LookalMatchingServicing {
    func fetchMatches() async throws -> [LookalMatch]
}
