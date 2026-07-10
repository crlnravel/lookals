//
//  BSDTourStateRecord.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation
import SwiftData

@Model
final class BSDTourStateRecord {
    var id: String
    var updatedAt: Date
    var payload: Data

    init(id: String, updatedAt: Date, payload: Data) {
        self.id = id
        self.updatedAt = updatedAt
        self.payload = payload
    }
}
