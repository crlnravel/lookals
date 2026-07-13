import Foundation

nonisolated protocol BSDTourInfoProviding: Sendable {
    func string(forKey key: String) -> String?
}

struct BundleBSDTourInfoProvider: BSDTourInfoProviding, Sendable {
    private let bundle: Bundle
    init(bundle: Bundle = .main) { self.bundle = bundle }
    func string(forKey key: String) -> String? { bundle.object(forInfoDictionaryKey: key) as? String }
}

struct DictionaryBSDTourInfoProvider: BSDTourInfoProviding, Sendable {
    let values: [String: String]
    func string(forKey key: String) -> String? { values[key] }
}

struct BSDTourLiveLocationConfiguration: Equatable, Sendable {
    let participantID: String
    let websocketHost: String
    let demoJoinToken: String
    let endpoint: URL

    init?(participantID: String, websocketHost: String, demoJoinToken: String) {
        let participantID = participantID.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = websocketHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = demoJoinToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !participantID.isEmpty, !host.isEmpty, !token.isEmpty,
              !host.contains("/"), !host.contains(":") else { return nil }
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
        components.path = "/v1/tours"
        guard let endpoint = components.url, endpoint.scheme == "wss", endpoint.host == host else { return nil }
        self.participantID = participantID
        self.websocketHost = host
        self.demoJoinToken = token
        self.endpoint = endpoint
    }
}

struct BSDTourRuntimeContext: Sendable {
    let identity: BSDTourSessionIdentity
    let liveRoomSessionFactory: any BSDTourLiveRoomSessionFactory
    let liveLocationConfiguration: BSDTourLiveLocationConfiguration?

    init(identity: BSDTourSessionIdentity, liveRoomSessionFactory: any BSDTourLiveRoomSessionFactory, liveLocationConfiguration: BSDTourLiveLocationConfiguration? = nil) {
        self.identity = identity
        self.liveRoomSessionFactory = liveRoomSessionFactory
        self.liveLocationConfiguration = liveLocationConfiguration
    }

    static func resolve(infoProvider: any BSDTourInfoProviding = BundleBSDTourInfoProvider(), liveRoomSessionFactory: (any BSDTourLiveRoomSessionFactory)? = nil) -> BSDTourRuntimeContext {
        let fallback = BSDTourRuntimeContext(identity: .offlineDefault, liveRoomSessionFactory: NoopBSDTourLiveRoomSessionFactory())
        guard let participantID = infoProvider.string(forKey: "LOOKALS_BSD_TOUR_PARTICIPANT_ID"),
              let host = infoProvider.string(forKey: "LOOKALS_BSD_TOUR_WEBSOCKET_HOST"),
              let token = infoProvider.string(forKey: "LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN"),
              let configuration = BSDTourLiveLocationConfiguration(participantID: participantID, websocketHost: host, demoJoinToken: token),
              configuration.participantID != BSDTourConfiguration.defaultParticipantID,
              BSDTourConfiguration.participantProfiles.contains(where: { $0.id == configuration.participantID }) else { return fallback }
        let identity = BSDTourSessionIdentity(tourID: BSDTourConfiguration.tourID, participantID: configuration.participantID)
        return BSDTourRuntimeContext(
            identity: identity,
            liveRoomSessionFactory: liveRoomSessionFactory ?? URLSessionBSDTourLiveRoomSessionFactory(configuration: configuration),
            liveLocationConfiguration: configuration
        )
    }
}
