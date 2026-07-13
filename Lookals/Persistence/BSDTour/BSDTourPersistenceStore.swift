//
//  BSDTourPersistenceStore.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

protocol BSDTourPersistenceStore: Sendable {
    func loadSnapshot(tourID: String) async throws -> BSDTourSnapshot?
    func saveSnapshot(_ snapshot: BSDTourSnapshot) async throws
    func reset(tourID: String) async throws
}
