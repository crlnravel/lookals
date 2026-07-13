import CoreLocation
import Foundation

nonisolated struct BSDTourShareableLocation: Equatable, Sendable {
    let coordinate: BSDTourCoordinate
    let accuracyMeters: Double
    let observedAt: Date

    init(coordinate: BSDTourCoordinate, accuracyMeters: Double, observedAt: Date = .now) {
        self.coordinate = coordinate
        self.accuracyMeters = accuracyMeters
        self.observedAt = observedAt
    }
}

nonisolated struct BSDTourLivePresence: Equatable, Sendable {
    let participantID: String
    let coordinate: BSDTourCoordinate
    let accuracyMeters: Double
    let observedAt: Date
    let serverReceivedAt: Date
}

nonisolated enum BSDTourLiveRoomEvent: Equatable, Sendable {
    case snapshot([BSDTourLivePresence])
    case location(BSDTourLivePresence)
    case locationExpired(participantID: String)
    case left(participantID: String, reason: String)
    case unavailable(String)
}

nonisolated enum BSDTourLiveRoomSessionError: Error, Equatable, Sendable {
    case alreadyStarted
    case joinTimedOut
    case stopped
    case unavailable
}

nonisolated protocol BSDTourLiveRoomClock: Sendable {
    var now: Date { get }
    func sleep(for duration: Duration) async throws
}

nonisolated struct SystemBSDTourLiveRoomClock: BSDTourLiveRoomClock {
    var now: Date { .now }
    func sleep(for duration: Duration) async throws { try await Task.sleep(for: duration) }
}

nonisolated protocol BSDTourLiveRoomSession: Sendable {
    func start() async throws -> AsyncStream<BSDTourLiveRoomEvent>
    func publish(_ location: BSDTourShareableLocation) async
    func stop() async
}

nonisolated protocol BSDTourLiveRoomSessionFactory: Sendable {
    func makeSession(identity: BSDTourSessionIdentity) -> any BSDTourLiveRoomSession
}

struct NoopBSDTourLiveRoomSessionFactory: BSDTourLiveRoomSessionFactory, Sendable {
    func makeSession(identity: BSDTourSessionIdentity) -> any BSDTourLiveRoomSession {
        NoopBSDTourLiveRoomSession()
    }
}

private actor NoopBSDTourLiveRoomSession: BSDTourLiveRoomSession {
    private var hasStarted = false

    func start() async throws -> AsyncStream<BSDTourLiveRoomEvent> {
        guard !hasStarted else { throw BSDTourLiveRoomSessionError.alreadyStarted }
        hasStarted = true
        return AsyncStream<BSDTourLiveRoomEvent> { continuation in
            continuation.yield(.unavailable("Live location is unavailable"))
            continuation.finish()
        }
    }
    func publish(_ location: BSDTourShareableLocation) async {}
    func stop() async {}
}

struct URLSessionBSDTourLiveRoomSessionFactory: BSDTourLiveRoomSessionFactory, Sendable {
    let endpoint: URL
    let token: String
    let client: any WebSocketClient
    let clock: any BSDTourLiveRoomClock

    init(
        configuration: BSDTourLiveLocationConfiguration,
        client: any WebSocketClient = URLSessionWebSocketClient(),
        clock: any BSDTourLiveRoomClock = SystemBSDTourLiveRoomClock()
    ) {
        endpoint = configuration.endpoint
        token = configuration.demoJoinToken
        self.client = client
        self.clock = clock
    }

    init(
        endpoint: URL,
        token: String,
        client: any WebSocketClient,
        clock: any BSDTourLiveRoomClock = SystemBSDTourLiveRoomClock()
    ) {
        self.endpoint = endpoint
        self.token = token
        self.client = client
        self.clock = clock
    }

    func makeSession(identity: BSDTourSessionIdentity) -> any BSDTourLiveRoomSession {
        BSDTourLiveRoomSessionActor(identity: identity, endpoint: endpoint, token: token, client: client, clock: clock)
    }
}

private actor BSDTourLiveRoomSessionActor: BSDTourLiveRoomSession {
    private enum State { case idle, connecting, joined, stopping }

    private let identity: BSDTourSessionIdentity
    private let endpoint: URL
    private let token: String
    private let client: any WebSocketClient
    private let clock: any BSDTourLiveRoomClock

    private var state = State.idle
    private var generation = 0
    private var connection: (any WebSocketConnection)?
    private var receiveTask: Task<Void, Never>?
    private var streamContinuation: AsyncStream<BSDTourLiveRoomEvent>.Continuation?
    private var stream: AsyncStream<BSDTourLiveRoomEvent>?
    private var joinAcknowledgementContinuation: AsyncStream<Void>.Continuation?
    private var pendingLocation: BSDTourShareableLocation?
    private var lastSentLocation: BSDTourShareableLocation?
    private var lastSentAt: Date?
    private var hasStarted = false
    private var terminalEventEmitted = false

    init(identity: BSDTourSessionIdentity, endpoint: URL, token: String, client: any WebSocketClient, clock: any BSDTourLiveRoomClock) {
        self.identity = identity
        self.endpoint = endpoint
        self.token = token
        self.client = client
        self.clock = clock
    }

    func start() async throws -> AsyncStream<BSDTourLiveRoomEvent> {
        guard !hasStarted else { throw BSDTourLiveRoomSessionError.alreadyStarted }
        hasStarted = true
        generation += 1
        let generation = self.generation
        state = .connecting

        do {
            let connection = try await client.connect(to: endpoint)
            guard generation == self.generation, state == .connecting else {
                await connection.disconnect(code: .normal, reason: nil)
                throw BSDTourLiveRoomSessionError.stopped
            }
            self.connection = connection
            let messages = try await connection.messages()
            let (stream, eventContinuation) = AsyncStream<BSDTourLiveRoomEvent>.makeStream(bufferingPolicy: .bufferingOldest(64))
            self.stream = stream
            streamContinuation = eventContinuation
            receiveTask = Task { [weak self] in
                await self?.receive(messages, generation: generation)
            }

            let join = BSDTourOutboundFrame.join(tourID: identity.tourID, participantID: identity.participantID, token: token)
            let (acknowledgements, continuation) = AsyncStream<Void>.makeStream()
            joinAcknowledgementContinuation = continuation
            try await connection.send(.text(try encodedText(join)))
            try await waitForJoinAcknowledgement(acknowledgements, generation: generation)
            guard generation == self.generation, state == .connecting else { throw BSDTourLiveRoomSessionError.stopped }
            state = .joined
            if let pendingLocation {
                self.pendingLocation = nil
                await sendIfAllowed(pendingLocation, generation: generation)
            }
            return stream
        } catch is CancellationError {
            await stop()
            throw BSDTourLiveRoomSessionError.stopped
        } catch let error as BSDTourLiveRoomSessionError {
            await stop()
            throw error
        } catch {
            await stop()
            throw BSDTourLiveRoomSessionError.unavailable
        }
    }

    func publish(_ location: BSDTourShareableLocation) async {
        guard location.accuracyMeters.isFinite, (0...50).contains(location.accuracyMeters),
              location.coordinate.latitude.isFinite, location.coordinate.longitude.isFinite else { return }
        guard state == .connecting || state == .joined else { return }
        guard state == .joined else {
            pendingLocation = location
            return
        }
        await sendIfAllowed(location, generation: generation)
    }

    func stop() async {
        guard state != .idle else { return }
        generation += 1
        state = .stopping
        joinAcknowledgementContinuation?.finish()
        joinAcknowledgementContinuation = nil
        let connection = self.connection
        let receiveTask = self.receiveTask
        self.connection = nil
        self.receiveTask = nil
        pendingLocation = nil
        lastSentLocation = nil
        lastSentAt = nil
        streamContinuation?.finish()
        streamContinuation = nil
        stream = nil
        await connection?.disconnect(code: .normal, reason: nil)
        receiveTask?.cancel()
        await receiveTask?.value
        state = .idle
    }

    private func waitForJoinAcknowledgement(_ acknowledgements: AsyncStream<Void>, generation: Int) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [clock] in
                try await clock.sleep(for: .seconds(10))
                throw BSDTourLiveRoomSessionError.joinTimedOut
            }
            group.addTask {
                guard await self.canAwaitJoin(generation: generation) else { throw BSDTourLiveRoomSessionError.stopped }
                for await _ in acknowledgements { return }
                throw BSDTourLiveRoomSessionError.stopped
            }
            defer { group.cancelAll() }
            try await group.next()
        }
    }

    private func canAwaitJoin(generation: Int) -> Bool {
        generation == self.generation && state == .connecting
    }

    private func receive(_ messages: AsyncThrowingStream<WebSocketMessage, Error>, generation: Int) async {
        do {
            for try await message in messages {
                guard generation == self.generation else { return }
                guard case let .text(text) = message, let event = try BSDTourProtocolCodec.decode(text) else {
                    await stopForReceiveFailure(generation: generation, message: "Invalid live-room message")
                    return
                }
                switch event {
                case let .snapshot(presences):
                    emit(.snapshot(presences), generation: generation)
                    joinAcknowledgementContinuation?.yield(())
                    joinAcknowledgementContinuation?.finish()
                    joinAcknowledgementContinuation = nil
                case let .location(presence): emit(.location(presence), generation: generation)
                case let .locationExpired(participantID): emit(.locationExpired(participantID: participantID), generation: generation)
                case let .left(participantID, reason): emit(.left(participantID: participantID, reason: reason), generation: generation)
                case let .protocolError(code, message):
                    if code == .rateLimited || code == .staleLocation || code == .invalidLocation || code == .notJoined {
                        continue
                    }
                    await stopForReceiveFailure(generation: generation, message: message)
                    return
                }
            }
            await stopForReceiveFailure(generation: generation, message: "Live-room connection ended")
        } catch {
            await stopForReceiveFailure(generation: generation, message: "Live-room connection failed")
        }
    }

    private func stopForReceiveFailure(generation: Int, message: String) async {
        guard generation == self.generation, state != .stopping, state != .idle else { return }
        guard !terminalEventEmitted else { return }
        terminalEventEmitted = true
        emit(.unavailable(message), generation: generation)
        state = .idle
        let activeConnection = self.connection
        connection = nil
        receiveTask = nil
        joinAcknowledgementContinuation?.finish()
        joinAcknowledgementContinuation = nil
        streamContinuation?.finish()
        streamContinuation = nil
        await activeConnection?.disconnect(code: .normal, reason: nil)
    }

    private func emit(_ event: BSDTourLiveRoomEvent, generation: Int) {
        guard generation == self.generation, state != .stopping, state != .idle else { return }
        streamContinuation?.yield(event)
    }

    private func sendIfAllowed(_ location: BSDTourShareableLocation, generation: Int) async {
        guard generation == self.generation, state == .joined, let connection else { return }
        let now = clock.now
        if let lastSentAt, now.timeIntervalSince(lastSentAt) < 1 { return }
        let moved = lastSentLocation.map { distance(from: $0.coordinate, to: location.coordinate) >= 5 } ?? true
        let refreshed = lastSentAt.map { now.timeIntervalSince($0) >= 15 } ?? true
        guard moved || refreshed else { return }
        let frame = BSDTourOutboundFrame.location(location)
        do {
            try await connection.send(.text(try encodedText(frame)))
            guard generation == self.generation, state == .joined else { return }
            lastSentLocation = location
            lastSentAt = now
        } catch {
            await stopForReceiveFailure(generation: generation, message: "Live-room connection failed")
        }
    }

    private func distance(from lhs: BSDTourCoordinate, to rhs: BSDTourCoordinate) -> Double {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }
}

nonisolated private enum BSDTourOutboundFrame: Sendable {
    case join(tourID: String, participantID: String, token: String)
    case location(BSDTourShareableLocation)
}

nonisolated enum BSDTourProtocolEvent: Sendable {
    case snapshot([BSDTourLivePresence])
    case location(BSDTourLivePresence)
    case locationExpired(String)
    case left(String, String)
    case protocolError(BSDTourProtocolErrorCode, String)
}

nonisolated enum BSDTourProtocolErrorCode: String, Codable, Sendable {
    case notJoined = "not_joined"
    case invalidSchema = "invalid_schema"
    case invalidLocation = "invalid_location"
    case staleLocation = "stale_location"
    case rateLimited = "rate_limited"
    case unknownType = "unknown_type"
    case unauthorized
    case serverClosing = "server_closing"
}

nonisolated enum BSDTourProtocolCodec {
    static func decode(_ text: String) throws -> BSDTourProtocolEvent? {
        guard let data = text.data(using: .utf8) else { throw BSDTourLiveRoomSessionError.unavailable }
        let decoder = JSONDecoder()
        let header = try decoder.decode(Header.self, from: data)
        guard header.v == 1 else { throw BSDTourLiveRoomSessionError.unavailable }
        switch header.type {
        case "room.snapshot":
            let frame = try decoder.decode(RoomSnapshot.self, from: data)
            return .snapshot(frame.participants.map(\.presence))
        case "participant.location":
            return .location(try decoder.decode(ParticipantLocation.self, from: data).presence)
        case "participant.locationExpired":
            return .locationExpired(try decoder.decode(LocationExpired.self, from: data).participantID)
        case "participant.left":
            let frame = try decoder.decode(ParticipantLeft.self, from: data)
            return .left(frame.participantID, frame.reason.rawValue)
        case "protocol.error":
            let frame = try decoder.decode(ProtocolError.self, from: data)
            return .protocolError(frame.code, frame.message)
        default:
            throw BSDTourLiveRoomSessionError.unavailable
        }
    }

    fileprivate static func encode(_ frame: BSDTourOutboundFrame) throws -> Data {
        switch frame {
        case let .join(tourID, participantID, token):
            return Data("{\"v\":1,\"type\":\"room.join\",\"tourId\":\(try jsonString(tourID)),\"participantId\":\(try jsonString(participantID)),\"token\":\(try jsonString(token))}".utf8)
        case let .location(location):
            let observedAt = try jsonString(LiveLocationTimestampCodec.string(from: location.observedAt))
            return Data("{\"v\":1,\"type\":\"location.update\",\"latitude\":\(location.coordinate.latitude),\"longitude\":\(location.coordinate.longitude),\"accuracyMeters\":\(location.accuracyMeters),\"observedAt\":\(observedAt)}".utf8)
        }
    }

    private static func jsonString(_ value: String) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let result = String(data: data, encoding: .utf8) else { throw BSDTourLiveRoomSessionError.unavailable }
        return result
    }

    fileprivate static func encodedText(_ frame: BSDTourOutboundFrame) throws -> String {
        guard let text = String(data: try encode(frame), encoding: .utf8) else {
            throw BSDTourLiveRoomSessionError.unavailable
        }
        return text
    }
}

private func encodedText(_ frame: BSDTourOutboundFrame) throws -> String {
    try BSDTourProtocolCodec.encodedText(frame)
}

nonisolated private enum LiveLocationTimestampCodec {
    static func string(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    static func date(from string: String) throws -> Date {
        guard string.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"#, options: .regularExpression) != nil else {
            throw BSDTourLiveRoomSessionError.unavailable
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: string) else { throw BSDTourLiveRoomSessionError.unavailable }
        return date
    }
}

nonisolated private func validateIdentifier(_ value: String) throws {
    guard value.range(of: #"^[a-z0-9][a-z0-9-]{0,63}$"#, options: .regularExpression) != nil else {
        throw BSDTourLiveRoomSessionError.unavailable
    }
}

nonisolated private func validateCoordinate(latitude: Double, longitude: Double) throws {
    guard latitude.isFinite, (-90...90).contains(latitude), longitude.isFinite, (-180...180).contains(longitude) else {
        throw BSDTourLiveRoomSessionError.unavailable
    }
}

nonisolated private func validateAccuracy(_ value: Double) throws {
    guard value.isFinite, (0...50).contains(value) else { throw BSDTourLiveRoomSessionError.unavailable }
}

nonisolated private protocol StrictDecodable: Decodable {
    static var allowedKeys: Set<String> { get }
}

nonisolated private extension StrictDecodable {
    static func rejectUnknownKeys(_ container: KeyedDecodingContainer<AnyCodingKey>) throws {
        let keys = Set(container.allKeys.map(\.stringValue))
        guard keys.isSubset(of: allowedKeys) else { throw BSDTourLiveRoomSessionError.unavailable }
    }
}

nonisolated private struct AnyCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; intValue = nil }
    init?(intValue: Int) { stringValue = String(intValue); self.intValue = intValue }
}

nonisolated private struct Header: StrictDecodable {
    let v: Int
    let type: String
    static let allowedKeys: Set<String> = ["v", "type", "tourId", "participantId", "token", "serverReceivedAt", "participants", "latitude", "longitude", "accuracyMeters", "observedAt", "reason", "code", "message"]
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        try Self.rejectUnknownKeys(container)
        v = try container.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!)
        type = try container.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!)
    }
}

nonisolated private struct RoomJoin: Codable { let v: Int; let type: String; let tourID: String; let participantID: String; let token: String; enum CodingKeys: String, CodingKey { case v, type, tourID = "tourId", participantID = "participantId", token } }
nonisolated private struct LocationUpdate: Codable { let v: Int; let type: String; let latitude: Double; let longitude: Double; let accuracyMeters: Double; let observedAt: String }

nonisolated private struct WireLocation: StrictDecodable {
    let participantID: String
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double
    let observedAt: Date
    let serverReceivedAt: Date
    static let allowedKeys: Set<String> = ["v", "type", "participantId", "latitude", "longitude", "accuracyMeters", "observedAt", "serverReceivedAt"]
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        try Self.rejectUnknownKeys(container)
        func key(_ value: String) -> AnyCodingKey { AnyCodingKey(stringValue: value)! }
        participantID = try container.decode(String.self, forKey: key("participantId"))
        latitude = try container.decode(Double.self, forKey: key("latitude"))
        longitude = try container.decode(Double.self, forKey: key("longitude"))
        accuracyMeters = try container.decode(Double.self, forKey: key("accuracyMeters"))
        observedAt = try LiveLocationTimestampCodec.date(from: container.decode(String.self, forKey: key("observedAt")))
        serverReceivedAt = try LiveLocationTimestampCodec.date(from: container.decode(String.self, forKey: key("serverReceivedAt")))
        guard try container.decode(Int.self, forKey: key("v")) == 1,
              try container.decode(String.self, forKey: key("type")) == "participant.location" else { throw BSDTourLiveRoomSessionError.unavailable }
        try validateIdentifier(participantID)
        try validateCoordinate(latitude: latitude, longitude: longitude)
        try validateAccuracy(accuracyMeters)
    }
    var presence: BSDTourLivePresence { BSDTourLivePresence(participantID: participantID, coordinate: BSDTourCoordinate(latitude: latitude, longitude: longitude), accuracyMeters: accuracyMeters, observedAt: observedAt, serverReceivedAt: serverReceivedAt) }
}

nonisolated private struct SnapshotLocation: StrictDecodable {
    let participantID: String
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double
    let observedAt: Date
    let serverReceivedAt: Date
    static let allowedKeys: Set<String> = ["participantId", "latitude", "longitude", "accuracyMeters", "observedAt", "serverReceivedAt"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self)
        try Self.rejectUnknownKeys(c)
        func key(_ value: String) -> AnyCodingKey { AnyCodingKey(stringValue: value)! }
        participantID = try c.decode(String.self, forKey: key("participantId"))
        latitude = try c.decode(Double.self, forKey: key("latitude"))
        longitude = try c.decode(Double.self, forKey: key("longitude"))
        accuracyMeters = try c.decode(Double.self, forKey: key("accuracyMeters"))
        observedAt = try LiveLocationTimestampCodec.date(from: c.decode(String.self, forKey: key("observedAt")))
        serverReceivedAt = try LiveLocationTimestampCodec.date(from: c.decode(String.self, forKey: key("serverReceivedAt")))
        try validateIdentifier(participantID)
        try validateCoordinate(latitude: latitude, longitude: longitude)
        try validateAccuracy(accuracyMeters)
    }
    var presence: BSDTourLivePresence { BSDTourLivePresence(participantID: participantID, coordinate: BSDTourCoordinate(latitude: latitude, longitude: longitude), accuracyMeters: accuracyMeters, observedAt: observedAt, serverReceivedAt: serverReceivedAt) }
}

nonisolated private struct ParticipantLocation: StrictDecodable {
    let presence: BSDTourLivePresence
    static let allowedKeys: Set<String> = ["v", "type", "participantId", "latitude", "longitude", "accuracyMeters", "observedAt", "serverReceivedAt"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self)
        try Self.rejectUnknownKeys(c)
        guard try c.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!) == 1,
              try c.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!) == "participant.location" else { throw BSDTourLiveRoomSessionError.unavailable }
        presence = try WireLocation(from: decoder).presence
    }
}

nonisolated private struct RoomSnapshot: StrictDecodable {
    let participants: [SnapshotLocation]
    static let allowedKeys: Set<String> = ["v", "type", "serverReceivedAt", "participants"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self); try Self.rejectUnknownKeys(c)
        let key = AnyCodingKey(stringValue: "participants")!
        participants = try c.decode([SnapshotLocation].self, forKey: key)
        _ = try LiveLocationTimestampCodec.date(from: c.decode(String.self, forKey: AnyCodingKey(stringValue: "serverReceivedAt")!))
        guard try c.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!) == 1,
              try c.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!) == "room.snapshot" else { throw BSDTourLiveRoomSessionError.unavailable }
    }
}

nonisolated private struct LocationExpired: StrictDecodable {
    let participantID: String
    static let allowedKeys: Set<String> = ["v", "type", "participantId"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self); try Self.rejectUnknownKeys(c)
        guard try c.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!) == 1,
              try c.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!) == "participant.locationExpired" else { throw BSDTourLiveRoomSessionError.unavailable }
        participantID = try c.decode(String.self, forKey: AnyCodingKey(stringValue: "participantId")!)
        try validateIdentifier(participantID)
    }
}

nonisolated private struct ParticipantLeft: StrictDecodable {
    enum Reason: String, Decodable { case disconnect, heartbeatTimeout = "heartbeat_timeout" }
    let participantID: String
    let reason: Reason
    static let allowedKeys: Set<String> = ["v", "type", "participantId", "reason"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self); try Self.rejectUnknownKeys(c)
        guard try c.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!) == 1,
              try c.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!) == "participant.left" else { throw BSDTourLiveRoomSessionError.unavailable }
        participantID = try c.decode(String.self, forKey: AnyCodingKey(stringValue: "participantId")!)
        try validateIdentifier(participantID)
        reason = try c.decode(Reason.self, forKey: AnyCodingKey(stringValue: "reason")!)
    }
}

nonisolated private struct ProtocolError: StrictDecodable {
    let code: BSDTourProtocolErrorCode
    let message: String
    static let allowedKeys: Set<String> = ["v", "type", "code", "message"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self); try Self.rejectUnknownKeys(c)
        guard try c.decode(Int.self, forKey: AnyCodingKey(stringValue: "v")!) == 1,
              try c.decode(String.self, forKey: AnyCodingKey(stringValue: "type")!) == "protocol.error" else { throw BSDTourLiveRoomSessionError.unavailable }
        code = try c.decode(BSDTourProtocolErrorCode.self, forKey: AnyCodingKey(stringValue: "code")!)
        message = try c.decode(String.self, forKey: AnyCodingKey(stringValue: "message")!)
        guard message.count <= 160 else { throw BSDTourLiveRoomSessionError.unavailable }
    }
}
