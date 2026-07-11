//
//  MemoryImageSource.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Foundation

enum MemoryImageSource: Hashable {
    case asset(String)
    case captured(UUID)
    case cloud(UUID)
}
