//
//  MemoriesRoute.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation

enum MemoriesRoute: Hashable {
    case album(UUID)
    case photo(UUID)
    case addMemory(UUID)
}
