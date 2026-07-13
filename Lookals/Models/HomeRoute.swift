//
//  HomeRoute.swift
//  Lookals
//

import Foundation

enum HomeRoute: Hashable {
    case profile
    case ongoingItinerary
    case checkAvailability(TourMap)
    case memories
    case gallery
    case memory(MemoriesRoute)
}
