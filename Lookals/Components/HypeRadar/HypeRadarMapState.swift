//
//  HypeRadarMapState.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import CoreLocation
import MapKit
import Observation

enum HypeRadarMapPhase {
    case goingToMeetingPoint
    case arrived
    case shakeYourPhone
    case quiz
}

struct HypeRadarMapPlace {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D

    nonisolated static let poetTea = HypeRadarMapPlace(
        name: "Kelontong Poet-Tea",
        address: "Jl. BSD Raya Barat.",
        coordinate: CLLocationCoordinate2D(latitude: 40.7478, longitude: -73.9854)
    )
}

@MainActor
@Observable
final class HypeRadarMapState {
    var phase: HypeRadarMapPhase

    let title: String
    let place: HypeRadarMapPlace
    let region: MKCoordinateRegion

    init(
        phase: HypeRadarMapPhase = .goingToMeetingPoint,
        title: String = "Hype Radar Map",
        place: HypeRadarMapPlace = .poetTea
    ) {
        self.phase = phase
        self.title = title
        self.place = place
        self.region = MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.055)
        )
    }

    var markers: [CustomMapMarker] {
        switch phase {
        case .goingToMeetingPoint:
            [
                CustomMapMarker(id: "destination", style: .smallDestination, xRatio: 0.30, yRatio: 0.56),
                CustomMapMarker(id: "avatar", style: .avatar, xRatio: 0.36, yRatio: 0.66),
                CustomMapMarker(id: "zone", style: .mapBadge("9A"), xRatio: 0.30, yRatio: 0.42)
            ]

        case .arrived, .shakeYourPhone, .quiz:
            [
                CustomMapMarker(id: "place", style: .place, xRatio: 0.43, yRatio: 0.56),
                CustomMapMarker(id: "avatar", style: .avatar, xRatio: 0.54, yRatio: 0.59)
            ]
        }
    }

    var statusCardPhase: HypeRadarMapPhase {
        phase == .goingToMeetingPoint ? .goingToMeetingPoint : .arrived
    }
}
