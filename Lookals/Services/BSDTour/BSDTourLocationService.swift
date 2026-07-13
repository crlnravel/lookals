//
//  BSDTourLocationService.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import Foundation
import Observation

enum BSDTourLocationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
}

@MainActor
@Observable
final class BSDTourLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorization: BSDTourLocationAuthorization = .notDetermined
    private(set) var currentLocation: CLLocation?

    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        updateAuthorization(from: manager.authorizationStatus)
    }

    func requestAuthorizationAndStart() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            start()
        case .denied, .restricted:
            updateAuthorization(from: manager.authorizationStatus)
        @unknown default:
            updateAuthorization(from: manager.authorizationStatus)
        }
    }

    func start() {
        guard authorization == .authorized else { return }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorization(from: manager.authorizationStatus)

        if authorization == .authorized {
            start()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onLocationUpdate?(location)
    }

    private func updateAuthorization(from status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            authorization = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            authorization = .authorized
        case .denied, .restricted:
            authorization = .denied
        @unknown default:
            authorization = .denied
        }
    }
}
