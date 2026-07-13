import XCTest
import SwiftData
@testable import Lookals

final class BSDTourRuntimeIdentityPersistenceTests: XCTestCase {
    func testUnconfiguredRuntimeUsesOfflineIdentityAndNoopFactory() {
        let context = BSDTourRuntimeContext.resolve(
            infoProvider: DictionaryBSDTourInfoProvider(values: [:])
        )

        XCTAssertEqual(context.identity, .offlineDefault)
        XCTAssertNil(context.liveLocationConfiguration)
    }

    func testValidRuntimeConfigurationBuildsSlashSafeEndpointAndIdentity() {
        let context = BSDTourRuntimeContext.resolve(
            infoProvider: DictionaryBSDTourInfoProvider(values: [
                "LOOKALS_BSD_TOUR_PARTICIPANT_ID": "gisella",
                "LOOKALS_BSD_TOUR_WEBSOCKET_HOST": "demo.trycloudflare.com",
                "LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN": "redacted-token"
            ])
        )

        XCTAssertEqual(context.identity.participantID, "gisella")
        XCTAssertEqual(context.liveLocationConfiguration?.endpoint.absoluteString, "wss://demo.trycloudflare.com/v1/tours")
        XCTAssertEqual(context.liveLocationConfiguration?.demoJoinToken, "redacted-token")
    }

    @MainActor
    func testMockDependencyCompositionCarriesConfiguredIdentityIntoViewModel() {
        let dependencies = AppDependencies.mock(
            infoProvider: DictionaryBSDTourInfoProvider(values: [
                "LOOKALS_BSD_TOUR_PARTICIPANT_ID": "kevin",
                "LOOKALS_BSD_TOUR_WEBSOCKET_HOST": "demo.trycloudflare.com",
                "LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN": "redacted-token"
            ])
        )
        let viewModel = BSDTourViewModel(
            persistenceStore: dependencies.bsdTourPersistenceStore,
            identity: dependencies.bsdTourRuntimeContext.identity
        )

        XCTAssertEqual(viewModel.identity.participantID, "kevin")
        XCTAssertEqual(viewModel.snapshot.participants.filter(\.isCurrentUser).map(\.id), ["kevin"])
    }

    func testMalformedRuntimeTupleFallsBackAsAWhole() {
        let context = BSDTourRuntimeContext.resolve(
            infoProvider: DictionaryBSDTourInfoProvider(values: [
                "LOOKALS_BSD_TOUR_PARTICIPANT_ID": "gisella",
                "LOOKALS_BSD_TOUR_WEBSOCKET_HOST": "wss://demo.trycloudflare.com/v1/tours",
                "LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN": "token"
            ])
        )

        XCTAssertEqual(context.identity, .offlineDefault)
        XCTAssertNil(context.liveLocationConfiguration)
    }

    func testParticipantFactoryMarksExactlyOneInjectedIdentity() {
        let identity = BSDTourSessionIdentity(participantID: "kevin")
        let participants = BSDTourConfiguration.participants(for: identity)

        XCTAssertEqual(participants.filter(\.isCurrentUser).map(\.id), ["kevin"])
        XCTAssertFalse(participants.contains(where: { $0.id == BSDTourConfiguration.defaultParticipantID }))
        XCTAssertEqual(BSDTourConfiguration.participants.map(\.id).first, BSDTourConfiguration.defaultParticipantID)
    }

    func testPersistedStateV2RoundTripsIdentityAndSnapshot() throws {
        let identity = BSDTourSessionIdentity.offlineDefault
        let snapshot = makeTestSnapshot(identity: identity)

        let encoded = try JSONEncoder().encode(BSDTourPersistedStateV2(identity: identity, snapshot: snapshot))
        let decoded = try JSONDecoder().decode(BSDTourPersistedStateV2.self, from: encoded)
        XCTAssertEqual(decoded.identity, identity)
        XCTAssertEqual(decoded.snapshot, snapshot)
    }

    func testSwiftDataV2KeysLegacyCoexistenceMismatchDeletionAndReset() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BSDTourStateRecord.self, configurations: configuration)
        let store = SwiftDataBSDTourPersistenceStore(modelContainer: container)
        let first = BSDTourSessionIdentity(participantID: "gisella")
        let second = BSDTourSessionIdentity(participantID: "kevin")
        let third = BSDTourSessionIdentity(participantID: "julian")
        let firstSnapshot = makeTestSnapshot(identity: first)
        let secondSnapshot = makeTestSnapshot(identity: second, phase: .quest)

        try await store.save(firstSnapshot, for: first)
        try await store.save(secondSnapshot, for: second)
        let loadedFirst = try await store.load(session: first)
        let loadedSecond = try await store.load(session: second)
        let loadedWrongKey = try await store.load(session: BSDTourSessionIdentity(participantID: "carleano"))
        XCTAssertEqual(loadedFirst, firstSnapshot)
        XCTAssertEqual(loadedSecond, secondSnapshot)
        XCTAssertNil(loadedWrongKey)

        let legacyPayload = try JSONEncoder().encode(firstSnapshot)
        container.mainContext.insert(BSDTourStateRecord(id: first.tourID, updatedAt: Date(), payload: legacyPayload))
        try container.mainContext.save()
        let loadedLegacyKey = try await store.load(session: third)
        XCTAssertNil(loadedLegacyKey)

        let wrongEnvelope = BSDTourPersistedStateV2(identity: first, snapshot: firstSnapshot)
        let wrongKey = SwiftDataBSDTourPersistenceStore.storageKey(for: third)
        container.mainContext.insert(
            BSDTourStateRecord(
                id: wrongKey,
                updatedAt: Date(),
                payload: try JSONEncoder().encode(wrongEnvelope)
            )
        )
        try container.mainContext.save()
        let loadedWrongEnvelope = try await store.load(session: third)
        XCTAssertNil(loadedWrongEnvelope)

        let remainingDescriptor = FetchDescriptor<BSDTourStateRecord>(predicate: #Predicate { $0.id == wrongKey })
        XCTAssertTrue(try container.mainContext.fetch(remainingDescriptor).isEmpty)

        try await store.reset(session: first)
        let loadedAfterReset = try await store.load(session: first)
        let loadedSecondAfterReset = try await store.load(session: second)
        XCTAssertNil(loadedAfterReset)
        XCTAssertEqual(loadedSecondAfterReset, secondSnapshot)
        let legacyDescriptor = FetchDescriptor<BSDTourStateRecord>(predicate: #Predicate { $0.id == first.tourID })
        XCTAssertEqual(try container.mainContext.fetch(legacyDescriptor).count, 1)
    }

    func testSwiftDataRejectsSnapshotFromWrongTour() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BSDTourStateRecord.self, configurations: configuration)
        let store = SwiftDataBSDTourPersistenceStore(modelContainer: container)
        let identity = BSDTourSessionIdentity(participantID: "gisella")
        let wrongTour = BSDTourSessionIdentity(tourID: "other-tour", participantID: identity.participantID)

        do {
            try await store.save(makeTestSnapshot(identity: wrongTour), for: identity)
            XCTFail("Expected a snapshot identity mismatch")
        } catch let error as BSDTourPersistenceError {
            XCTAssertEqual(error, .snapshotIdentityMismatch)
        }
    }

    @MainActor
    func testViewModelOrdersSaveResetAndSubsequentSave() async {
        let store = RecordingBSDTourPersistenceStore()
        let viewModel = BSDTourViewModel(persistenceStore: store)

        viewModel.finishTour()
        viewModel.reset()
        viewModel.finishTour()
        await viewModel.waitForPersistenceOperations()

        let events = await store.events()
        XCTAssertEqual(events, ["save", "reset", "save"])
    }

    @MainActor
    func testDelayedRestoreResetSaveProducesFinalSnapshotAndEnvelope() async {
        let store = DelayedBSDTourPersistenceStore()
        let viewModel = BSDTourViewModel(persistenceStore: store)
        let locationService = BSDTourLocationService()
        let shakeDetector = BSDTourShakeDetector()

        viewModel.start(locationService: locationService, shakeDetector: shakeDetector)
        await store.waitUntilLoadRequested()

        // Reset is requested while restore is suspended; it must run after restore,
        // and the final save must follow that reset.
        viewModel.reset()
        await store.releaseLoad(makeTestSnapshot(identity: .offlineDefault, phase: .quest))
        await viewModel.waitForRestore()
        await store.waitUntilResetRequested()
        await store.releaseReset()

        viewModel.finishTour()
        await store.waitUntilSaveRequested()
        await store.releaseSave()
        await viewModel.waitForPersistenceOperations()

        XCTAssertEqual(viewModel.snapshot.phase, .tourEnded)
        let envelope = await store.finalEnvelope()
        XCTAssertEqual(envelope?.identity, .offlineDefault)
        XCTAssertEqual(envelope?.snapshot.phase, .tourEnded)
    }
}

private func makeTestSnapshot(
    identity: BSDTourSessionIdentity,
    phase: BSDTourPhase = .navigatingToMeetingPoint
) -> BSDTourSnapshot {
    BSDTourSnapshot(
        tourID: identity.tourID,
        phase: phase,
        scheduledStartTime: Date(timeIntervalSince1970: 0),
        participants: BSDTourConfiguration.participants(for: identity),
        currentCheckpointIndex: 0,
        currentQuestIndex: 0,
        currentStepIndex: 0,
        earnedPoints: 0,
        revealedCheckpointIDs: [],
        reachedCheckpointIDs: [],
        questCompletions: [:],
        userJoined: false,
        waitingRoomClosed: false,
        tourCompleted: false,
        userEndedTour: false
    )
}

private actor RecordingBSDTourPersistenceStore: BSDTourPersistenceStore {
    private var recordedEvents: [String] = []

    func load(session: BSDTourSessionIdentity) async throws -> BSDTourSnapshot? { nil }

    func save(_ snapshot: BSDTourSnapshot, for session: BSDTourSessionIdentity) async throws {
        recordedEvents.append("save")
    }

    func reset(session: BSDTourSessionIdentity) async throws {
        recordedEvents.append("reset")
    }

    func events() -> [String] { recordedEvents }
}

private actor DelayedBSDTourPersistenceStore: BSDTourPersistenceStore {
    private var loadContinuation: CheckedContinuation<BSDTourSnapshot?, Never>?
    private var resetContinuation: CheckedContinuation<Void, Never>?
    private var saveContinuation: CheckedContinuation<Void, Never>?
    private var loadRequestWaiter: CheckedContinuation<Void, Never>?
    private var resetRequestWaiter: CheckedContinuation<Void, Never>?
    private var saveRequestWaiter: CheckedContinuation<Void, Never>?
    private var loadRequested = false
    private var resetRequested = false
    private var saveRequested = false
    private var envelope: BSDTourPersistedStateV2?

    func load(session: BSDTourSessionIdentity) async throws -> BSDTourSnapshot? {
        loadRequested = true
        loadRequestWaiter?.resume()
        loadRequestWaiter = nil
        return await withCheckedContinuation { continuation in
            loadContinuation = continuation
        }
    }

    func save(_ snapshot: BSDTourSnapshot, for session: BSDTourSessionIdentity) async throws {
        saveRequested = true
        saveRequestWaiter?.resume()
        saveRequestWaiter = nil
        envelope = BSDTourPersistedStateV2(identity: session, snapshot: snapshot)
        await withCheckedContinuation { continuation in
            saveContinuation = continuation
        }
    }

    func reset(session: BSDTourSessionIdentity) async throws {
        resetRequested = true
        resetRequestWaiter?.resume()
        resetRequestWaiter = nil
        await withCheckedContinuation { continuation in
            resetContinuation = continuation
        }
    }

    func waitUntilLoadRequested() async {
        if loadRequested { return }
        await withCheckedContinuation { loadRequestWaiter = $0 }
    }

    func waitUntilResetRequested() async {
        if resetRequested { return }
        await withCheckedContinuation { resetRequestWaiter = $0 }
    }

    func waitUntilSaveRequested() async {
        if saveRequested { return }
        await withCheckedContinuation { saveRequestWaiter = $0 }
    }

    func releaseLoad(_ snapshot: BSDTourSnapshot?) {
        loadContinuation?.resume(returning: snapshot)
        loadContinuation = nil
    }

    func releaseReset() {
        resetContinuation?.resume()
        resetContinuation = nil
    }

    func releaseSave() {
        saveContinuation?.resume()
        saveContinuation = nil
    }

    func finalEnvelope() -> BSDTourPersistedStateV2? { envelope }
}
