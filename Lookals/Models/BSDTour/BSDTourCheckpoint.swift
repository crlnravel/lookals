//
//  BSDTourCheckpoint.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation
import MapKit

struct BSDTourCheckpoint: Identifiable, Equatable {
    let id: String
    let locationCode: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let landmarkImageName: String
    let cloudStage: Int
    let quests: [BSDQuest]

    var codableCoordinate: BSDTourCoordinate {
        BSDTourCoordinate(coordinate)
    }

    static func == (lhs: BSDTourCheckpoint, rhs: BSDTourCheckpoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.locationCode == rhs.locationCode &&
        lhs.name == rhs.name &&
        lhs.address == rhs.address &&
        lhs.codableCoordinate == rhs.codableCoordinate &&
        lhs.landmarkImageName == rhs.landmarkImageName &&
        lhs.cloudStage == rhs.cloudStage &&
        lhs.quests == rhs.quests
    }
}
