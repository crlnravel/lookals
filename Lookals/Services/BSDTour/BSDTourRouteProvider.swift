//
//  BSDTourRouteProvider.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import Foundation
import MapKit

protocol BSDTourRouteProvider: Sendable {
    func route(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
}

nonisolated struct MapKitBSDTourRouteProvider: BSDTourRouteProvider {
    func route(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            location: CLLocation(latitude: source.latitude, longitude: source.longitude),
            address: nil
        )
        request.destination = MKMapItem(
            location: CLLocation(latitude: destination.latitude, longitude: destination.longitude),
            address: nil
        )
        request.transportType = .walking

        let response = try await MKDirections(request: request).calculate()

        guard let route = response.routes.first else {
            throw BSDTourRouteError.noRoute
        }

        return route
    }
}

enum BSDTourRouteError: Error {
    case noRoute
}
