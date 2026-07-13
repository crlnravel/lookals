//
//  BSDTourConfiguration.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import Foundation

nonisolated enum BSDTourConfiguration {
    static let tourID = "bsd-hype-radar-demo"
    static let defaultParticipantID = "current-user"

    static var scheduledStartTime: Date {
        Calendar.current.date(byAdding: .minute, value: -2, to: Date()) ?? Date()
    }

    static let participantProfiles: [BSDTourParticipant] = [
        BSDTourParticipant(
            id: defaultParticipantID,
            name: "You",
            avatarImageName: "AvatarPlaceholder",
            ringColorName: "orange",
            isCurrentUser: true,
            status: .invited,
            coordinate: BSDTourCoordinate(latitude: -6.29900, longitude: 106.68190)
        ),
        BSDTourParticipant(
            id: "gisella",
            name: "Gisella",
            avatarImageName: "Profile Picture",
            ringColorName: "pink",
            isCurrentUser: false,
            status: .invited,
            coordinate: BSDTourCoordinate(latitude: -6.30470, longitude: 106.67870)
        ),
        BSDTourParticipant(
            id: "kevin",
            name: "Kevin",
            avatarImageName: "AvatarPlaceholder",
            ringColorName: "blue",
            isCurrentUser: false,
            status: .invited,
            coordinate: BSDTourCoordinate(latitude: -6.30458, longitude: 106.67890)
        ),
        BSDTourParticipant(
            id: "julian",
            name: "Julian",
            avatarImageName: "AvatarPlaceholder",
            ringColorName: "green",
            isCurrentUser: false,
            status: .invited,
            coordinate: BSDTourCoordinate(latitude: -6.30438, longitude: 106.67882)
        ),
        BSDTourParticipant(
            id: "carleano",
            name: "Carleano",
            avatarImageName: "AvatarPlaceholder",
            ringColorName: "red",
            isCurrentUser: false,
            status: .invited,
            coordinate: BSDTourCoordinate(latitude: -6.30477, longitude: 106.67902)
        )
    ]

    static var participants: [BSDTourParticipant] { participants(for: .offlineDefault) }

    static func participants(for identity: BSDTourSessionIdentity) -> [BSDTourParticipant] {
        let selectedID = participantProfiles.contains(where: { $0.id == identity.participantID }) ? identity.participantID : defaultParticipantID
        let profiles = selectedID == defaultParticipantID
            ? participantProfiles
            : participantProfiles.filter { $0.id != defaultParticipantID }
        return profiles.map { profile in
            var profile = profile
            profile.isCurrentUser = profile.id == selectedID
            return profile
        }
    }

    static var checkpoints: [BSDTourCheckpoint] {
        let questsByLocation = Dictionary(grouping: BSDTourQuestDemoData.quests, by: \.locationCode)

        return [
            checkpoint(
                code: "L1",
                name: "Prima Flora",
                address: "Jalan Letnan Sutopo No. 10",
                coordinate: CLLocationCoordinate2D(latitude: -6.29807, longitude: 106.68230),
                landmarkImageName: "BSDMap/TreeIcon",
                cloudStage: 0,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L2",
                name: "Pasar Modern BSD",
                address: "Jalan Letnan Sutopo No. 68",
                coordinate: CLLocationCoordinate2D(latitude: -6.30449, longitude: 106.68492),
                landmarkImageName: "BSDMap/CupIcon",
                cloudStage: 1,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L3",
                name: "Rosso Micro Roastery",
                address: "Jalan Letnan Sutopo No. 26",
                coordinate: CLLocationCoordinate2D(latitude: -6.30455, longitude: 106.68429),
                landmarkImageName: "BSDMap/CoffeeIcon",
                cloudStage: 2,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L4",
                name: "Mare Eatery",
                address: "Jl. Cemara Raya Blok C1",
                coordinate: CLLocationCoordinate2D(latitude: -6.30472, longitude: 106.68375),
                landmarkImageName: "BSDMap/PizzaIcon",
                cloudStage: 3,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L5",
                name: "The Goats Dept",
                address: "Jl. Cemara No. 5",
                coordinate: CLLocationCoordinate2D(latitude: -6.30537, longitude: 106.68180),
                landmarkImageName: "BSDMap/ArcadeIcon",
                cloudStage: 4,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L6",
                name: "Taman Perdamaian",
                address: "Jalan Taman Perdamaian Blok A1 No.11",
                coordinate: CLLocationCoordinate2D(latitude: -6.30759, longitude: 106.67919),
                landmarkImageName: "BSDMap/MuseumIcon",
                cloudStage: 5,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L7",
                name: "Tailor Tukang Jahit BSD",
                address: "Jl Palm Anggur No. 1",
                coordinate: CLLocationCoordinate2D(latitude: -6.30639, longitude: 106.67922),
                landmarkImageName: "BSDMap/LaundryIcon",
                cloudStage: 6,
                questsByLocation: questsByLocation
            ),
            checkpoint(
                code: "L8",
                name: "Kelontong Poet-Tea",
                address: "Jalan Palm Sulur I No. BK/31",
                coordinate: CLLocationCoordinate2D(latitude: -6.30467, longitude: 106.67880),
                landmarkImageName: "BSDMap/MatchaIcon",
                cloudStage: 7,
                questsByLocation: questsByLocation
            )
        ]
    }

    private static func checkpoint(
        code: String,
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D,
        landmarkImageName: String,
        cloudStage: Int,
        questsByLocation: [String: [BSDQuest]]
    ) -> BSDTourCheckpoint {
        BSDTourCheckpoint(
            id: code,
            locationCode: code,
            name: name,
            address: address,
            coordinate: coordinate,
            landmarkImageName: landmarkImageName,
            cloudStage: cloudStage,
            quests: questsByLocation[code, default: []]
        )
    }
}
