import Foundation

nonisolated struct BSDTourSessionIdentity: Codable, Equatable, Hashable, Sendable {
    let tourID: String
    let participantID: String

    init(tourID: String = BSDTourConfiguration.tourID, participantID: String) {
        self.tourID = tourID
        self.participantID = participantID
    }

    static let offlineDefault = BSDTourSessionIdentity(
        tourID: BSDTourConfiguration.tourID,
        participantID: BSDTourConfiguration.defaultParticipantID
    )
}
