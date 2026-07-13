//
//  BSDTourClock.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

protocol BSDTourClock: Sendable {
    var now: Date { get }
}

nonisolated struct SystemBSDTourClock: BSDTourClock {
    var now: Date {
        Date()
    }
}
