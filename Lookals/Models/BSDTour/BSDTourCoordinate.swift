//
//  BSDTourCoordinate.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import Foundation

nonisolated struct BSDTourCoordinate: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
