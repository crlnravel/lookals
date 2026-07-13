import Foundation
import XCTest
@testable import Lookals

nonisolated final class BSDTourLiveRoomSessionTests: XCTestCase {
    func testJoinAcknowledgementAndLocationEncodingUseTheTransportOnce() async throws {
        let connection = FakeLiveRoomConnection()
        let client = FakeLiveRoomClient(connection: connection)
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: client,
            clock: ImmediateLiveRoomClock()
        )
        let identity = BSDTourSessionIdentity(tourID: "bsd-tour", participantID: "alice")
        let session = factory.makeSession(identity: identity)

        let startTask = Task { try await session.start() }
        await connection.waitUntilJoinSent()
        await connection.acknowledgeJoin()
        _ = try await startTask.value
        await session.publish(BSDTourShareableLocation(
            coordinate: BSDTourCoordinate(latitude: -6.1754, longitude: 106.8249),
            accuracyMeters: 12.5,
            observedAt: Date(timeIntervalSince1970: 1_767_268_800)
        ))

        let sent = await connection.sentMessages()
        XCTAssertEqual(sent.count, 2)
        XCTAssertEqual(sent[0], "{\"v\":1,\"type\":\"room.join\",\"tourId\":\"bsd-tour\",\"participantId\":\"alice\",\"token\":\"fixture-token\"}")
        XCTAssertEqual(sent[1], "{\"v\":1,\"type\":\"location.update\",\"latitude\":-6.1754,\"longitude\":106.8249,\"accuracyMeters\":12.5,\"observedAt\":\"2026-01-01T12:00:00.000Z\"}")
        await session.stop()
    }

    func testStartIsSingleUseUntilAnExplicitStopCreatesANewGeneration() async throws {
        let connection = FakeLiveRoomConnection()
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: FakeLiveRoomClient(connection: connection),
            clock: ImmediateLiveRoomClock()
        )
        let session = factory.makeSession(identity: .offlineDefault)

        let startTask = Task { try await session.start() }
        await connection.waitUntilJoinSent()
        await connection.acknowledgeJoin()
        _ = try await startTask.value
        do {
            _ = try await session.start()
            XCTFail("A session generation must only be started once")
        } catch let error as BSDTourLiveRoomSessionError {
            XCTAssertEqual(error, .alreadyStarted)
        }
        await session.stop()
    }

    func testNoopSessionIsAlsoIrreversiblySingleUse() async throws {
        let session = NoopBSDTourLiveRoomSessionFactory().makeSession(identity: .offlineDefault)
        _ = try await session.start()
        await session.stop()
        do {
            _ = try await session.start()
            XCTFail("No-op sessions must not be reusable after stop")
        } catch let error as BSDTourLiveRoomSessionError {
            XCTAssertEqual(error, .alreadyStarted)
        }
    }

    func testJoinTimeoutStopsTheConcreteGeneration() async throws {
        let connection = FakeLiveRoomConnection()
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: FakeLiveRoomClient(connection: connection),
            clock: ImmediateTimeoutLiveRoomClock()
        )
        let session = factory.makeSession(identity: .offlineDefault)
        do {
            _ = try await session.start()
            XCTFail("A missing snapshot must time out")
        } catch let error as BSDTourLiveRoomSessionError {
            XCTAssertEqual(error, .joinTimedOut)
        }
    }

    func testPreAckBufferAndPublicationFiltersUseOnlyControlledClockAdvances() async throws {
        let connection = FakeLiveRoomConnection()
        let clock = PublicationLiveRoomClock(now: Date(timeIntervalSince1970: 1_767_268_800))
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: FakeLiveRoomClient(connection: connection),
            clock: clock
        )
        let session = factory.makeSession(identity: .offlineDefault)
        let location = BSDTourShareableLocation(coordinate: BSDTourCoordinate(latitude: 0, longitude: 0), accuracyMeters: 5, observedAt: clock.now)
        let startTask = Task { try await session.start() }
        await connection.waitUntilJoinSent()
        await session.publish(location)
        await connection.acknowledgeJoin()
        _ = try await startTask.value
        let preAckSentCount = await connection.sentMessages().count
        XCTAssertEqual(preAckSentCount, 2)

        await session.publish(BSDTourShareableLocation(coordinate: location.coordinate, accuracyMeters: 51, observedAt: clock.now))
        clock.advance(by: 1)
        await session.publish(BSDTourShareableLocation(coordinate: location.coordinate, accuracyMeters: 5, observedAt: clock.now))
        let throttledSentCount = await connection.sentMessages().count
        XCTAssertEqual(throttledSentCount, 2)
        clock.advance(by: 14)
        await session.publish(BSDTourShareableLocation(coordinate: location.coordinate, accuracyMeters: 5, observedAt: clock.now))
        let refreshedSentCount = await connection.sentMessages().count
        XCTAssertEqual(refreshedSentCount, 3)
        clock.advance(by: 1)
        await session.publish(BSDTourShareableLocation(coordinate: BSDTourCoordinate(latitude: 0.001, longitude: 0), accuracyMeters: 5, observedAt: clock.now))
        let movedSentCount = await connection.sentMessages().count
        XCTAssertEqual(movedSentCount, 4)
        await session.stop()
    }

    func testNormalTransportCompletionEmitsOneTerminalUnavailableEvent() async throws {
        let connection = FakeLiveRoomConnection()
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: FakeLiveRoomClient(connection: connection),
            clock: ImmediateLiveRoomClock()
        )
        let session = factory.makeSession(identity: .offlineDefault)
        let startTask = Task { try await session.start() }
        await connection.waitUntilJoinSent()
        await connection.acknowledgeJoin()
        let stream = try await startTask.value
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
        await connection.finishMessages()
        guard case .unavailable = await iterator.next() else {
            return XCTFail("Normal transport completion must be terminal")
        }
        let terminal = await iterator.next()
        XCTAssertNil(terminal)
        await session.stop()
    }

    func testStopDuringConnectInvalidatesTheStaleStartGeneration() async throws {
        let connection = FakeLiveRoomConnection()
        let client = BlockingLiveRoomClient(connection: connection)
        let factory = URLSessionBSDTourLiveRoomSessionFactory(
            endpoint: URL(string: "wss://example.test/v1/tours")!,
            token: "fixture-token",
            client: client,
            clock: ImmediateLiveRoomClock()
        )
        let session = factory.makeSession(identity: .offlineDefault)
        let startTask = Task { try await session.start() }
        await client.waitUntilConnectRequested()
        await session.stop()
        await client.releaseConnect()
        do {
            _ = try await startTask.value
            XCTFail("A stopped generation must not complete after connect returns")
        } catch let error as BSDTourLiveRoomSessionError {
            XCTAssertEqual(error, .stopped)
        }
        let disconnectCount = await connection.disconnectCount()
        XCTAssertEqual(disconnectCount, 1)
    }

    func testCanonicalFlattenedAndNestedFixturesAreStrictlyValidated() throws {
        let validLocation = try canonicalFixture(named: "participant.location.valid")
        guard case let .location(presence) = try BSDTourProtocolCodec.decode(validLocation) else {
            return XCTFail("Expected valid participant.location fixture")
        }
        XCTAssertEqual(presence.participantID, "alice")

        let validSnapshot = try canonicalFixture(named: "room.snapshot.valid")
        guard case let .snapshot(presences) = try BSDTourProtocolCodec.decode(validSnapshot) else {
            return XCTFail("Expected valid room.snapshot fixture")
        }
        XCTAssertTrue(presences.isEmpty)

        guard case let .locationExpired(expiredID) = try BSDTourProtocolCodec.decode(try canonicalFixture(named: "participant.locationExpired.valid")) else {
            return XCTFail("Expected valid participant.locationExpired fixture")
        }
        XCTAssertEqual(expiredID, "alice")
        guard case let .left(leftID, reason) = try BSDTourProtocolCodec.decode(try canonicalFixture(named: "participant.left.valid")) else {
            return XCTFail("Expected valid participant.left fixture")
        }
        XCTAssertEqual(leftID, "alice")
        XCTAssertEqual(reason, "disconnect")
        guard case let .protocolError(code, message) = try BSDTourProtocolCodec.decode(try canonicalFixture(named: "protocol.error.valid")) else {
            return XCTFail("Expected valid protocol.error fixture")
        }
        XCTAssertEqual(code, .notJoined)
        XCTAssertEqual(message, "join required")

        for name in ["participant.location.nested-unknown", "location.update.bad-timestamp", "room.join.unknown-key"] {
            XCTAssertThrowsError(try BSDTourProtocolCodec.decode(try canonicalFixture(named: name)))
        }
        let nestedHeaderKeys = "{\"v\":1,\"type\":\"room.snapshot\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\",\"participants\":[{\"v\":1,\"type\":\"participant.location\",\"participantId\":\"alice\",\"latitude\":0,\"longitude\":0,\"accuracyMeters\":1,\"observedAt\":\"2026-01-01T12:00:00.000Z\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\"}]}"
        XCTAssertThrowsError(try BSDTourProtocolCodec.decode(nestedHeaderKeys))
    }

    func testSchemaBoundariesRejectIdentifiersCoordinatesAccuracyAndMessages() throws {
        let longMessage = String(repeating: "x", count: 161)
        let frames = [
            "{\"v\":1,\"type\":\"participant.location\",\"participantId\":\"Alice\",\"latitude\":0,\"longitude\":0,\"accuracyMeters\":1,\"observedAt\":\"2026-01-01T12:00:00.000Z\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\"}",
            "{\"v\":1,\"type\":\"participant.location\",\"participantId\":\"alice\",\"latitude\":91,\"longitude\":0,\"accuracyMeters\":1,\"observedAt\":\"2026-01-01T12:00:00.000Z\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\"}",
            "{\"v\":1,\"type\":\"participant.location\",\"participantId\":\"alice\",\"latitude\":0,\"longitude\":0,\"accuracyMeters\":51,\"observedAt\":\"2026-01-01T12:00:00.000Z\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\"}",
            "{\"v\":1,\"type\":\"protocol.error\",\"code\":\"not_joined\",\"message\":\"\(longMessage)\"}"
        ]
        for frame in frames {
            XCTAssertThrowsError(try BSDTourProtocolCodec.decode(frame))
        }
    }

}

nonisolated private func canonicalFixture(named name: String) throws -> String {
    let bundle = Bundle(for: BSDTourLiveRoomSessionTests.self)
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
        throw NSError(domain: "Fixture", code: 1)
    }
    return try String(contentsOf: url, encoding: .utf8)
}

nonisolated final class BSDTourLiveRoomViewModelLifecycleTests: XCTestCase {
    @MainActor
    func testViewModelOwnsOneConsumerAndStopsBeforeStartingANewGeneration() async {
        let factory = FakeLiveRoomSessionFactory()
        let viewModel = BSDTourViewModel(
            persistenceStore: EmptyBSDTourPersistenceStore(),
            liveRoomSessionFactory: factory
        )
        let locationService = BSDTourLocationService()
        let shakeDetector = BSDTourShakeDetector()

        viewModel.start(locationService: locationService, shakeDetector: shakeDetector)
        await viewModel.waitForRestore()
        await viewModel.startLiveRoom()
        await viewModel.startLiveRoom()
        XCTAssertEqual(factory.sessionsSnapshot().count, 1)
        let firstSession = factory.sessionsSnapshot()[0]
        let firstStartCount = await firstSession.startCount()
        XCTAssertEqual(firstStartCount, 1)

        await viewModel.stopLiveRoom()
        let firstStopCount = await firstSession.stopCount()
        XCTAssertEqual(firstStopCount, 1)
        await viewModel.activateLiveRoom()
        XCTAssertEqual(factory.sessionsSnapshot().count, 2)
        let secondSession = factory.sessionsSnapshot()[1]
        let secondStartCount = await secondSession.startCount()
        XCTAssertEqual(secondStartCount, 1)
        await viewModel.liveRoomDisappeared()
        let secondStopCount = await secondSession.stopCount()
        XCTAssertEqual(secondStopCount, 1)
    }

    @MainActor
    func testFreshnessFilteringAndTerminalReceiveTearDownOverlay() async {
        let factory = FakeLiveRoomSessionFactory()
        let now = Date(timeIntervalSince1970: 1_767_268_800)
        let viewModel = BSDTourViewModel(
            persistenceStore: EmptyBSDTourPersistenceStore(),
            clock: FixedBSDTourClock(now: now),
            liveRoomSessionFactory: factory
        )
        viewModel.start(locationService: BSDTourLocationService(), shakeDetector: BSDTourShakeDetector())
        await viewModel.waitForRestore()
        await viewModel.startLiveRoom()
        let fresh = BSDTourLivePresence(
            participantID: "gisella",
            coordinate: BSDTourCoordinate(latitude: -6.3, longitude: 106.68),
            accuracyMeters: 5,
            observedAt: now,
            serverReceivedAt: now.addingTimeInterval(-10)
        )
        let own = BSDTourLivePresence(participantID: "current-user", coordinate: fresh.coordinate, accuracyMeters: 5, observedAt: now, serverReceivedAt: now)
        let unknown = BSDTourLivePresence(participantID: "unknown", coordinate: fresh.coordinate, accuracyMeters: 5, observedAt: now, serverReceivedAt: now)
        await viewModel.applyLiveRoomEventForTesting(.snapshot([fresh, own, unknown]))
        XCTAssertEqual(viewModel.mapParticipants.first(where: { $0.id == "gisella" })?.coordinate, fresh.coordinate)

        let stale = BSDTourLivePresence(
            participantID: "gisella",
            coordinate: BSDTourCoordinate(latitude: -6.31, longitude: 106.69),
            accuracyMeters: 5,
            observedAt: now,
            serverReceivedAt: now.addingTimeInterval(-31)
        )
        await viewModel.applyLiveRoomEventForTesting(.location(stale))
        XCTAssertEqual(viewModel.mapParticipants.first(where: { $0.id == "gisella" })?.coordinate, fresh.coordinate)

        await viewModel.applyLiveRoomEventForTesting(.locationExpired(participantID: "gisella"))
        XCTAssertNil(viewModel.mapParticipants.first(where: { $0.id == "gisella" }))
        await viewModel.applyLiveRoomEventForTesting(.snapshot([fresh]))
        await viewModel.applyLiveRoomEventForTesting(.left(participantID: "gisella", reason: "disconnect"))
        XCTAssertNil(viewModel.mapParticipants.first(where: { $0.id == "gisella" }))

        await viewModel.applyLiveRoomEventForTesting(.unavailable("ended"))
        XCTAssertNil(viewModel.mapParticipants.first(where: { $0.id == "gisella" }))
    }

    @MainActor
    func testInactiveFirstStartDoesNotCreateASessionUntilActivation() async {
        let factory = FakeLiveRoomSessionFactory()
        let viewModel = BSDTourViewModel(
            persistenceStore: EmptyBSDTourPersistenceStore(),
            liveRoomSessionFactory: factory
        )
        await viewModel.startTour(
            locationService: BSDTourLocationService(),
            shakeDetector: BSDTourShakeDetector(),
            sceneIsActive: false
        )
        XCTAssertTrue(factory.sessionsSnapshot().isEmpty)
        await viewModel.activateLiveRoom()
        XCTAssertEqual(factory.sessionsSnapshot().count, 1)
        await viewModel.deactivateLiveRoom()
    }
}

private struct FixedBSDTourClock: BSDTourClock {
    let now: Date
}

private final class ImmediateLiveRoomClock: BSDTourLiveRoomClock, @unchecked Sendable {
    private let lock = NSLock()
    private var pending: CheckedContinuation<Void, Error>?
    var now: Date { .now }

    func sleep(for duration: Duration) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.lock()
                if Task.isCancelled {
                    lock.unlock()
                    continuation.resume(throwing: CancellationError())
                } else {
                    pending = continuation
                    lock.unlock()
                }
            }
        } onCancel: {
            self.cancelSleep()
        }
    }

    private func cancelSleep() {
        lock.lock()
        let continuation = pending
        pending = nil
        lock.unlock()
        continuation?.resume(throwing: CancellationError())
    }
}

private final class PublicationLiveRoomClock: BSDTourLiveRoomClock, @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date
    private var pending: CheckedContinuation<Void, Error>?
    init(now: Date) { date = now }
    var now: Date { lock.lock(); defer { lock.unlock() }; return date }
    func advance(by seconds: TimeInterval) { lock.lock(); date.addTimeInterval(seconds); lock.unlock() }
    func sleep(for duration: Duration) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.lock()
                if Task.isCancelled {
                    lock.unlock()
                    continuation.resume(throwing: CancellationError())
                } else {
                    pending = continuation
                    lock.unlock()
                }
            }
        } onCancel: {
            lock.lock()
            let continuation = pending
            pending = nil
            lock.unlock()
            continuation?.resume(throwing: CancellationError())
        }
    }
}

private struct ImmediateTimeoutLiveRoomClock: BSDTourLiveRoomClock {
    var now: Date { .now }
    func sleep(for duration: Duration) async throws { throw BSDTourLiveRoomSessionError.joinTimedOut }
}

private actor FakeLiveRoomClient: WebSocketClient {
    let connection: FakeLiveRoomConnection
    init(connection: FakeLiveRoomConnection) { self.connection = connection }
    func connect(to endpoint: URL) async throws -> any WebSocketConnection { connection }
}

private actor BlockingLiveRoomClient: WebSocketClient {
    let connection: FakeLiveRoomConnection
    private let requestContinuation: AsyncStream<Void>.Continuation
    private let requests: AsyncStream<Void>
    private let releaseContinuation: AsyncStream<Void>.Continuation
    private let releases: AsyncStream<Void>

    init(connection: FakeLiveRoomConnection) {
        self.connection = connection
        let (requests, requestContinuation) = AsyncStream<Void>.makeStream()
        let (releases, releaseContinuation) = AsyncStream<Void>.makeStream()
        self.requests = requests
        self.requestContinuation = requestContinuation
        self.releases = releases
        self.releaseContinuation = releaseContinuation
    }

    func connect(to endpoint: URL) async throws -> any WebSocketConnection {
        requestContinuation.yield(())
        var iterator = releases.makeAsyncIterator()
        _ = await iterator.next()
        return connection
    }

    func waitUntilConnectRequested() async {
        var iterator = requests.makeAsyncIterator()
        _ = await iterator.next()
    }

    func releaseConnect() { releaseContinuation.yield(()) }
}

private actor FakeLiveRoomConnection: WebSocketConnection {
    private let continuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation
    private let messagesStream: AsyncThrowingStream<WebSocketMessage, Error>
    private let joinSignalContinuation: AsyncStream<Void>.Continuation
    private let joinSignals: AsyncStream<Void>
    private var sent: [String] = []

    init() {
        let (stream, continuation) = AsyncThrowingStream<WebSocketMessage, Error>.makeStream()
        let (joinSignals, joinSignalContinuation) = AsyncStream<Void>.makeStream()
        messagesStream = stream
        self.continuation = continuation
        self.joinSignals = joinSignals
        self.joinSignalContinuation = joinSignalContinuation
    }

    func currentState() async -> WebSocketConnectionState { .connected }
    func messages() async throws -> AsyncThrowingStream<WebSocketMessage, Error> { messagesStream }
    func send(_ message: WebSocketMessage) async throws {
        guard case let .text(text) = message else { return }
        sent.append(text)
        if text.contains("room.join") { joinSignalContinuation.yield(()) }
    }
    func disconnect(code: WebSocketCloseCode, reason: Data?) async { disconnects += 1 }
    func sentMessages() -> [String] { sent }
    func finishMessages() { continuation.finish() }
    func waitUntilJoinSent() async { var iterator = joinSignals.makeAsyncIterator(); _ = await iterator.next() }
    func acknowledgeJoin() { continuation.yield(.text("{\"v\":1,\"type\":\"room.snapshot\",\"serverReceivedAt\":\"2026-01-01T12:00:00.000Z\",\"participants\":[]}")) }
    func disconnectCount() -> Int { disconnects }
    private var disconnects = 0
}

private actor FakeLiveRoomSession: BSDTourLiveRoomSession {
    private var starts = 0
    private var stops = 0
    private var continuation: AsyncStream<BSDTourLiveRoomEvent>.Continuation?

    func start() async throws -> AsyncStream<BSDTourLiveRoomEvent> {
        starts += 1
        let (stream, continuation) = AsyncStream<BSDTourLiveRoomEvent>.makeStream()
        self.continuation = continuation
        return stream
    }
    func publish(_ location: BSDTourShareableLocation) async {}
    func stop() async {
        stops += 1
        continuation?.finish()
        continuation = nil
    }
    func emit(_ event: BSDTourLiveRoomEvent) { continuation?.yield(event) }
    func startCount() -> Int { starts }
    func stopCount() -> Int { stops }
}

private final class FakeLiveRoomSessionFactory: BSDTourLiveRoomSessionFactory, @unchecked Sendable {
    private let lock = NSLock()
    private var sessions: [FakeLiveRoomSession] = []

    func makeSession(identity: BSDTourSessionIdentity) -> any BSDTourLiveRoomSession {
        let session = FakeLiveRoomSession()
        lock.lock()
        sessions.append(session)
        lock.unlock()
        return session
    }

    func sessionsSnapshot() -> [FakeLiveRoomSession] {
        lock.lock()
        defer { lock.unlock() }
        return sessions
    }
}

private struct EmptyBSDTourPersistenceStore: BSDTourPersistenceStore {
    func load(session: BSDTourSessionIdentity) async throws -> BSDTourSnapshot? { nil }
    func save(_ snapshot: BSDTourSnapshot, for session: BSDTourSessionIdentity) async throws {}
    func reset(session: BSDTourSessionIdentity) async throws {}
}
