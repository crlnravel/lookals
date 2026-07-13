//
//  BSDTourViewModel.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor
@Observable
final class BSDTourViewModel {
    @ObservationIgnored private let roomRepository: any BSDTourRoomRepository
    @ObservationIgnored private let persistenceStore: any BSDTourPersistenceStore
    @ObservationIgnored private let routeProvider: any BSDTourRouteProvider
    @ObservationIgnored private let clock: any BSDTourClock
    @ObservationIgnored private let liveRoomSessionFactory: any BSDTourLiveRoomSessionFactory
    @ObservationIgnored let identity: BSDTourSessionIdentity
    @ObservationIgnored private var waitingRoomCutoffTask: Task<Void, Never>?
    @ObservationIgnored private var routeRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var persistenceTask: Task<Void, Never>?
    @ObservationIgnored private var restoreTask: Task<Void, Never>?
    @ObservationIgnored private var isRestoring = false
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var resetRequestedDuringRestore = false
    @ObservationIgnored private var lastKnownLocation: CLLocation?
    @ObservationIgnored private var liveRoomSession: (any BSDTourLiveRoomSession)?
    @ObservationIgnored private var liveRoomEventTask: Task<Void, Never>?
    @ObservationIgnored private var liveRoomGeneration = 0
    @ObservationIgnored private var liveRoomSceneIsActive = true
    @ObservationIgnored private var livePresenceByParticipantID: [String: BSDTourLivePresence] = [:]

    private(set) var snapshot: BSDTourSnapshot
    private(set) var checkpoints: [BSDTourCheckpoint]
    private(set) var activeRoute: MKRoute?
    private(set) var routeErrorMessage: String?
    private(set) var routeProgress: Double
    private(set) var locationAuthorization: BSDTourLocationAuthorization

    var questFlow: BSDTourFlowModel
    var isShakeWidgetExpanded: Bool
    var isCompletionExpanded: Bool
    var arrivalFeedbackTick: Int

    init(
        roomRepository: (any BSDTourRoomRepository)? = nil,
        persistenceStore: any BSDTourPersistenceStore,
        routeProvider: (any BSDTourRouteProvider)? = nil,
        clock: (any BSDTourClock)? = nil,
        identity: BSDTourSessionIdentity = .offlineDefault,
        liveRoomSessionFactory: (any BSDTourLiveRoomSessionFactory)? = nil
    ) {
        let checkpoints = BSDTourConfiguration.checkpoints
        let snapshot = BSDTourViewModel.makeDefaultSnapshot(checkpoints: checkpoints, identity: identity)

        self.roomRepository = roomRepository ?? MockBSDTourRoomRepository()
        self.persistenceStore = persistenceStore
        self.routeProvider = routeProvider ?? MapKitBSDTourRouteProvider()
        self.clock = clock ?? SystemBSDTourClock()
        self.identity = identity
        self.liveRoomSessionFactory = liveRoomSessionFactory ?? NoopBSDTourLiveRoomSessionFactory()
        self.snapshot = snapshot
        self.checkpoints = checkpoints
        self.activeRoute = nil
        self.routeErrorMessage = nil
        self.routeProgress = 0
        self.locationAuthorization = .notDetermined
        self.questFlow = BSDTourFlowModel(
            currentQuestIndex: snapshot.currentQuestIndex,
            currentStepIndex: snapshot.currentStepIndex,
            earnedPoints: snapshot.earnedPoints,
            isWidgetExpanded: false
        )
        self.isShakeWidgetExpanded = false
        self.isCompletionExpanded = snapshot.tourCompleted && !snapshot.userEndedTour
        self.arrivalFeedbackTick = 0

        configureQuestCallbacks()
    }

    deinit {
        waitingRoomCutoffTask?.cancel()
        routeRefreshTask?.cancel()
        persistenceTask?.cancel()
        restoreTask?.cancel()
        liveRoomEventTask?.cancel()
    }

    var phase: BSDTourPhase {
        snapshot.phase
    }

    var title: String {
        "Hype Radar Map"
    }

    var scheduledCutoff: Date {
        Calendar.current.date(byAdding: .minute, value: 5, to: snapshot.scheduledStartTime) ?? snapshot.scheduledStartTime
    }

    var currentCheckpoint: BSDTourCheckpoint? {
        checkpoints[safe: snapshot.currentCheckpointIndex]
    }

    var activeDestination: BSDTourCheckpoint? {
        switch phase {
        case .navigatingToMeetingPoint, .waitingToShake, .joinedWaitingRoom, .quest, .questSuccess:
            return currentCheckpoint
        case .navigatingToCheckpoint:
            return currentCheckpoint
        case .unavailable, .tourCompleted, .tourEnded:
            return nil
        }
    }

    var activeParticipants: [BSDTourParticipant] {
        snapshot.participants.filter(\.isActive)
    }

    var joinedParticipantsForDisplay: [BSDTourParticipantDisplay] {
        let participants: [BSDTourParticipant]

        if snapshot.userJoined || snapshot.waitingRoomClosed {
            participants = snapshot.participants.filter { $0.status == .joined }
        } else {
            participants = snapshot.participants.filter(\.isCurrentUser)
        }

        return participants.map(Self.displayParticipant)
    }

    var mapParticipants: [BSDTourParticipant] {
        snapshot.participants.compactMap { participant in
            if participant.isCurrentUser {
                return participant.status == .joined ? participant : nil
            }
            if participant.status == .joined || livePresenceByParticipantID[participant.id] != nil {
                var participant = participant
                if let presence = livePresenceByParticipantID[participant.id] {
                    participant.coordinate = presence.coordinate
                }
                return participant
            }
            return nil
        }
    }

    var isCurrentUserRemoved: Bool {
        snapshot.participants.first(where: \.isCurrentUser)?.status == .removed
    }

    var canShowShakeWidget: Bool {
        phase == .waitingToShake || phase == .joinedWaitingRoom
    }

    var canAcceptShake: Bool {
        phase == .waitingToShake && !snapshot.userJoined && !snapshot.waitingRoomClosed
    }

    var shouldShowQuestWidget: Bool {
        phase == .quest || phase == .questSuccess
    }

    var shouldShowRouteCard: Bool {
        phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint
    }

    var routeCardTitle: String {
        switch phase {
        case .navigatingToMeetingPoint:
            "Go to Meeting Point"
        case .navigatingToCheckpoint:
            remainingDistanceText
        default:
            activeDestination?.name ?? "Tour"
        }
    }

    var routeCardSubtitle: String {
        switch phase {
        case .navigatingToCheckpoint:
            "Until Next Checkpoint"
        default:
            activeDestination.map { "\($0.name) \($0.address)" } ?? ""
        }
    }

    var arrivedCardSubtitle: String {
        isCurrentUserRemoved ? "This tour has started." : "You’ve arrived!"
    }

    var remainingDistanceText: String {
        guard let activeRoute, let destination = activeDestination else {
            return "Route"
        }

        let userLocation = snapshot.participants.first(where: \.isCurrentUser)?.coordinate.locationCoordinate
        guard let userLocation else {
            return "\(Int(activeRoute.distance.rounded()))m"
        }

        let remaining = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            .distance(from: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude))
        return "\(Int(max(0, remaining).rounded()))m"
    }

    var navigationPolyline: MKPolyline? {
        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else {
            return nil
        }

        return Self.navigationPolyline(
            routePolyline: activeRoute?.polyline,
            source: currentUserCoordinate,
            destination: activeDestination?.coordinate
        )
    }

    var mapRegion: MKCoordinateRegion {
        if let navigationPolyline {
            return navigationPolyline.boundingMapRect.paddedRegion
        }

        let center = activeDestination?.coordinate ?? checkpoints[0].coordinate
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    }

    var currentCloudStage: Int {
        switch phase {
        case .navigatingToMeetingPoint, .waitingToShake, .joinedWaitingRoom:
            return 0
        case .quest, .questSuccess:
            return currentCheckpoint?.cloudStage ?? 0
        case .navigatingToCheckpoint:
            return max(0, (currentCheckpoint?.cloudStage ?? 1) - 1)
        case .unavailable, .tourCompleted, .tourEnded:
            return checkpoints.count
        }
    }

    func start(locationService: BSDTourLocationService, shakeDetector: BSDTourShakeDetector) {
        guard !hasStarted else { return }
        hasStarted = true
        isRestoring = true
        locationAuthorization = locationService.authorization
        locationService.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        shakeDetector.onShake = { [weak self] in
            self?.handleShake()
        }
        shakeDetector.start()

        restoreTask = Task { [weak self] in
            guard let self else { return }
            await restore()
            isRestoring = false
            if resetRequestedDuringRestore {
                resetRequestedDuringRestore = false
                reset()
            }
            processScheduledCutoffIfNeeded()
            scheduleWaitingRoomCutoffIfNeeded()
            await refreshRouteIfNeeded()
        }
    }

    /// Starts local gameplay and waits for restore before opening the ephemeral live-room session.
    func startTour(locationService: BSDTourLocationService, shakeDetector: BSDTourShakeDetector, sceneIsActive: Bool = true) async {
        start(locationService: locationService, shakeDetector: shakeDetector)
        liveRoomSceneIsActive = sceneIsActive
        await waitForRestore()
        if sceneIsActive { await startLiveRoom() }
    }

    /// Starts a new live-room generation. A generation has one session and one event consumer.
    func startLiveRoom() async {
        guard hasStarted, !isRestoring, liveRoomSceneIsActive, liveRoomSession == nil else { return }
        liveRoomGeneration += 1
        let generation = liveRoomGeneration
        let session = liveRoomSessionFactory.makeSession(identity: identity)
        liveRoomSession = session

        do {
            let stream = try await session.start()
            guard generation == liveRoomGeneration, liveRoomSession != nil else {
                await session.stop()
                return
            }
            liveRoomEventTask = Task { [weak self] in
                var receivedTerminalEvent = false
                for await event in stream {
                    guard !Task.isCancelled else { return }
                    receivedTerminalEvent = self?.handleLiveRoomEvent(event, generation: generation) == true
                    if receivedTerminalEvent { break }
                }
                if receivedTerminalEvent {
                    await self?.finishLiveRoomAfterTerminal(generation: generation)
                }
            }
        } catch {
            guard generation == liveRoomGeneration else { return }
            liveRoomSession = nil
            livePresenceByParticipantID.removeAll()
        }
    }

    /// Stops the active generation and awaits both the sole consumer and the transport close.
    func stopLiveRoom() async {
        liveRoomGeneration += 1
        let task = liveRoomEventTask
        let session = liveRoomSession
        liveRoomEventTask = nil
        liveRoomSession = nil
        livePresenceByParticipantID.removeAll()
        task?.cancel()
        await task?.value
        await session?.stop()
    }

    func activateLiveRoom() async {
        liveRoomSceneIsActive = true
        await startLiveRoom()
    }

    func deactivateLiveRoom() async {
        liveRoomSceneIsActive = false
        await stopLiveRoom()
    }

    func liveRoomDisappeared() async {
        await stopLiveRoom()
    }

    func appBecameActive() {
        guard !isRestoring else { return }
        processScheduledCutoffIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
    }

    func updateLocationAuthorization(_ authorization: BSDTourLocationAuthorization) {
        locationAuthorization = authorization
    }

    func handleLocationUpdate(_ location: CLLocation) {
        guard !isRestoring else { return }
        lastKnownLocation = location
        updateCurrentUserCoordinate(location.coordinate)
        activeRoute = nil
        routeErrorMessage = nil
        updateRouteProgress(for: location.coordinate)
        validateArrival(using: location)

        routeRefreshTask?.cancel()
        routeRefreshTask = Task { [weak self] in
            await self?.refreshRouteIfNeeded()
        }

        guard let liveRoomSession else { return }
        let shareableLocation = BSDTourShareableLocation(
            coordinate: BSDTourCoordinate(location.coordinate),
            accuracyMeters: location.horizontalAccuracy,
            observedAt: location.timestamp
        )
        Task {
            await liveRoomSession.publish(shareableLocation)
        }
    }

    private func handleLiveRoomEvent(_ event: BSDTourLiveRoomEvent, generation: Int) -> Bool {
        guard generation == liveRoomGeneration else { return true }
        let configuredIDs = Set(snapshot.participants.map(\.id))
        switch event {
            case let .snapshot(presences):
            livePresenceByParticipantID.removeAll()
            for presence in presences {
                guard configuredIDs.contains(presence.participantID), presence.participantID != identity.participantID else { continue }
                guard isFresh(presence) else { continue }
                if let current = livePresenceByParticipantID[presence.participantID], current.serverReceivedAt >= presence.serverReceivedAt { continue }
                livePresenceByParticipantID[presence.participantID] = presence
            }
        case let .location(presence):
            guard configuredIDs.contains(presence.participantID), presence.participantID != identity.participantID, isFresh(presence) else { return false }
            guard let current = livePresenceByParticipantID[presence.participantID], current.serverReceivedAt >= presence.serverReceivedAt else {
                livePresenceByParticipantID[presence.participantID] = presence
                return false
            }
        case let .locationExpired(participantID), let .left(participantID, _):
            livePresenceByParticipantID.removeValue(forKey: participantID)
        case .unavailable:
            livePresenceByParticipantID.removeAll()
            return true
        }
        return false
    }

#if DEBUG
    /// Deterministic lifecycle seam for unit tests; production delivery still uses the sole consumer task.
    func applyLiveRoomEventForTesting(_ event: BSDTourLiveRoomEvent) async {
        let terminal = handleLiveRoomEvent(event, generation: liveRoomGeneration)
        if terminal { await finishLiveRoomAfterTerminal(generation: liveRoomGeneration) }
    }
#endif

    private func isFresh(_ presence: BSDTourLivePresence) -> Bool {
        clock.now.timeIntervalSince(presence.serverReceivedAt) < 30
    }

    private func finishLiveRoomAfterTerminal(generation: Int) async {
        guard generation == liveRoomGeneration else { return }
        let session = liveRoomSession
        liveRoomSession = nil
        liveRoomEventTask = nil
        livePresenceByParticipantID.removeAll()
        await session?.stop()
    }

    func handleShake() {
        guard !isRestoring else { return }
        guard canAcceptShake else { return }

        snapshot = roomRepository.join(participantID: identity.participantID, in: snapshot)
        snapshot.phase = .joinedWaitingRoom
        isShakeWidgetExpanded = false
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func joinNextMockParticipant() {
        guard !isRestoring else { return }
        snapshot = roomRepository.joinNextMockParticipant(in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func joinAllParticipants() {
        guard !isRestoring else { return }
        snapshot = roomRepository.joinAllParticipants(identity: identity, in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func triggerCutoff() {
        guard !isRestoring else { return }
        snapshot.scheduledStartTime = Calendar.current.date(byAdding: .minute, value: -6, to: clock.now) ?? clock.now
        processScheduledCutoffIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func simulateArrival() {
        guard !isRestoring else { return }
        guard let destination = activeDestination else { return }
        arrive(at: destination)
    }

    func simulateLeavingArrivalRadius() {
        routeProgress = min(routeProgress, 0.85)
    }

    func completeCurrentQuestForAllParticipants() {
        guard !isRestoring else { return }
        guard let quest = questFlow.currentQuest else { return }
        guard snapshot.phase == .quest else { return }

        let wasGroupComplete = snapshot.questCompletions[quest.id]?.isGroupComplete == true
        snapshot = roomRepository.completeQuestForAllActiveParticipants(quest.id, identity: identity, in: snapshot)
        markQuestGroupCompleteIfReady(quest)

        if snapshot.questCompletions[quest.id]?.isGroupComplete == true {
            awardQuestRewardIfNeeded(quest, wasGroupComplete: wasGroupComplete)
            questFlow.showExternalQuestSuccess(
                title: successTitle(for: quest),
                subtitle: successSubtitle(for: quest)
            )
            snapshot.phase = .questSuccess
        }

        persist()
    }

    func finishTour() {
        guard !isRestoring else { return }
        snapshot.userEndedTour = true
        snapshot.phase = .tourEnded
        isCompletionExpanded = false
        persist()
    }

    func reset() {
        if isRestoring {
            resetRequestedDuringRestore = true
            return
        }
        activeRoute = nil
        routeErrorMessage = nil
        routeProgress = 0
        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        snapshot = Self.makeDefaultSnapshot(checkpoints: checkpoints, identity: identity)
        if let lastKnownLocation {
            updateCurrentUserCoordinate(lastKnownLocation.coordinate)
        }
        isShakeWidgetExpanded = false
        isCompletionExpanded = false
        questFlow.setEarnedPoints(0)
        questFlow.moveToQuest(
            withID: BSDTourQuestDemoData.quests.first?.id ?? "",
            expanded: false,
            notifiesStepChange: false
        )
        let previous = persistenceTask
        persistenceTask = Task { [weak self, persistenceStore, identity] in
            await previous?.value
            try? await persistenceStore.reset(session: identity)
            await self?.refreshRouteIfNeeded()
        }
    }

    private func restore() async {
        guard let restored = try? await persistenceStore.load(session: identity) else {
            persist()
            return
        }

        snapshot = restored
        questFlow.setEarnedPoints(snapshot.earnedPoints)
        questFlow.moveToQuest(
            withID: BSDTourQuestDemoData.quests[safe: snapshot.currentQuestIndex]?.id ?? BSDTourQuestDemoData.quests[0].id,
            stepIndex: snapshot.currentStepIndex,
            expanded: snapshot.phase == .quest || snapshot.phase == .questSuccess,
            notifiesStepChange: false
        )

        if snapshot.phase == .questSuccess, let quest = questFlow.currentQuest {
            questFlow.showExternalQuestSuccess(
                title: successTitle(for: quest),
                subtitle: successSubtitle(for: quest)
            )
        }

        isCompletionExpanded = snapshot.tourCompleted && !snapshot.userEndedTour
        isShakeWidgetExpanded = snapshot.phase == .waitingToShake
        scheduleWaitingRoomCutoffIfNeeded()
    }

    private func configureQuestCallbacks() {
        questFlow.onQuestCompletionRequested = { [weak self] quest in
            self?.completeQuest(quest) ?? .waitForGroup(message: "Waiting for tour state.")
        }

        questFlow.onQuestSuccessContinued = { [weak self] quest in
            self?.continueAfterQuestSuccess(quest)
        }

        questFlow.onStepChanged = { [weak self] questIndex, stepIndex in
            self?.snapshot.currentQuestIndex = questIndex
            self?.snapshot.currentStepIndex = stepIndex
            self?.snapshot.earnedPoints = self?.questFlow.earnedPoints ?? 0
            self?.persist()
        }
    }

    private func completeQuest(_ quest: BSDQuest) -> BSDTourQuestCompletionOutcome {
        guard snapshot.phase == .quest else {
            return .waitForGroup(message: "Waiting for the current quest.")
        }

        let currentUserID = identity.participantID
        snapshot = roomRepository.completeQuest(quest.id, participantID: currentUserID, in: snapshot)

        switch completionRule(for: quest) {
        case .anyParticipant:
            let wasGroupComplete = snapshot.questCompletions[quest.id]?.isGroupComplete == true
            markQuestGroupComplete(quest, completedBy: currentUserID)
            awardQuestRewardIfNeeded(quest, wasGroupComplete: wasGroupComplete)
            snapshot.phase = .questSuccess
            persist()
            return .showSuccess(title: successTitle(for: quest), subtitle: successSubtitle(for: quest))

        case .everyParticipant:
            let wasGroupComplete = snapshot.questCompletions[quest.id]?.isGroupComplete == true
            markQuestGroupCompleteIfReady(quest)

            if snapshot.questCompletions[quest.id]?.isGroupComplete == true {
                awardQuestRewardIfNeeded(quest, wasGroupComplete: wasGroupComplete)
                snapshot.phase = .questSuccess
                persist()
                return .showSuccess(title: successTitle(for: quest), subtitle: successSubtitle(for: quest))
            }

            persist()
            return .waitForGroup(message: groupWaitMessage(for: quest))
        }
    }

    private func continueAfterQuestSuccess(_ quest: BSDQuest) {
        snapshot.earnedPoints = questFlow.earnedPoints

        guard let currentGlobalQuestIndex = BSDTourQuestDemoData.quests.firstIndex(where: { $0.id == quest.id }) else {
            completeTour()
            return
        }

        let nextQuestIndex = currentGlobalQuestIndex + 1
        guard let nextQuest = BSDTourQuestDemoData.quests[safe: nextQuestIndex] else {
            completeTour()
            return
        }

        if nextQuest.locationCode == quest.locationCode {
            snapshot.currentQuestIndex = nextQuestIndex
            snapshot.currentStepIndex = 0
            snapshot.phase = .quest
            questFlow.moveToQuest(withID: nextQuest.id, expanded: true)
            persist()
            return
        }

        unlockNextCheckpoint(for: nextQuest, questIndex: nextQuestIndex)
    }

    private func unlockNextCheckpoint(for nextQuest: BSDQuest, questIndex: Int) {
        guard let nextCheckpointIndex = checkpoints.firstIndex(where: { $0.locationCode == nextQuest.locationCode }) else {
            completeTour()
            return
        }

        snapshot.currentCheckpointIndex = nextCheckpointIndex
        snapshot.currentQuestIndex = questIndex
        snapshot.currentStepIndex = 0
        snapshot.phase = .navigatingToCheckpoint
        routeProgress = 0
        questFlow.moveToQuest(withID: nextQuest.id, expanded: false)
        persist()

        Task {
            await refreshRouteIfNeeded()
        }
    }

    private func completeTour() {
        activeRoute = nil
        routeProgress = 1
        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        snapshot.phase = .tourCompleted
        snapshot.tourCompleted = true
        snapshot.currentQuestIndex = BSDTourQuestDemoData.quests.count
        isCompletionExpanded = true
        persist()
    }

    private func arrive(at checkpoint: BSDTourCheckpoint) {
        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else { return }

        activeRoute = nil
        routeProgress = 1
        arrivalFeedbackTick += 1

        if !snapshot.reachedCheckpointIDs.contains(checkpoint.id) {
            snapshot.reachedCheckpointIDs.append(checkpoint.id)
        }

        if !snapshot.revealedCheckpointIDs.contains(checkpoint.id) {
            snapshot.revealedCheckpointIDs.append(checkpoint.id)
        }

        switch phase {
        case .navigatingToMeetingPoint:
            snapshot.phase = .waitingToShake
            isShakeWidgetExpanded = true
            scheduleWaitingRoomCutoffIfNeeded()

        case .navigatingToCheckpoint:
            snapshot.phase = .quest
            questFlow.moveToQuest(
                withID: BSDTourQuestDemoData.quests[safe: snapshot.currentQuestIndex]?.id ?? BSDTourQuestDemoData.quests[0].id,
                expanded: true
            )

        default:
            break
        }

        persist()
    }

    private func validateArrival(using location: CLLocation) {
        guard let destination = activeDestination else { return }
        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else { return }
        guard abs(location.timestamp.timeIntervalSince(clock.now)) < 20 else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 35 else { return }

        let destinationLocation = CLLocation(
            latitude: destination.coordinate.latitude,
            longitude: destination.coordinate.longitude
        )
        let distance = location.distance(from: destinationLocation)

        if distance <= 10 {
            arrive(at: destination)
        }
    }

    private func processWaitingRoomCompletionIfNeeded() {
        guard !snapshot.waitingRoomClosed else { return }

        if snapshot.participants.allSatisfy({ $0.status == .joined }) {
            closeWaitingRoom()
        }
    }

    private func processScheduledCutoffIfNeeded() {
        guard !snapshot.waitingRoomClosed else { return }
        guard clock.now >= scheduledCutoff else { return }

        closeWaitingRoom()
    }

    private func closeWaitingRoom() {
        guard !snapshot.waitingRoomClosed else { return }

        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        snapshot = roomRepository.removeUnjoinedParticipants(in: snapshot)
        snapshot.waitingRoomClosed = true
        isShakeWidgetExpanded = false

        if isCurrentUserRemoved || !snapshot.userJoined {
            snapshot.phase = .unavailable
            activeRoute = nil
            persist()
            return
        }

        snapshot.phase = .quest
        questFlow.moveToQuest(
            withID: BSDTourDemoQuestID.firstQuestID,
            expanded: true
        )
        persist()
    }

    private func scheduleWaitingRoomCutoffIfNeeded() {
        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil

        guard !snapshot.waitingRoomClosed else { return }
        guard phase == .waitingToShake || phase == .joinedWaitingRoom else { return }

        let secondsUntilCutoff = scheduledCutoff.timeIntervalSince(clock.now)
        guard secondsUntilCutoff > 0 else {
            processScheduledCutoffIfNeeded()
            return
        }

        waitingRoomCutoffTask = Task { [weak self] in
            let nanoseconds = UInt64(secondsUntilCutoff * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else { return }
            self?.processScheduledCutoffIfNeeded()
        }
    }

    private func refreshRouteIfNeeded() async {
        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else {
            activeRoute = nil
            return
        }

        guard let destination = activeDestination else { return }
        let source = snapshot.participants.first(where: \.isCurrentUser)?.coordinate.locationCoordinate
            ?? CLLocationCoordinate2D(latitude: destination.coordinate.latitude - 0.004, longitude: destination.coordinate.longitude - 0.004)

        do {
            let route = try await routeProvider.route(from: source, to: destination.coordinate)
            guard !Task.isCancelled else { return }

            activeRoute = route
            routeErrorMessage = nil
            updateRouteProgress(for: source)
        } catch {
            activeRoute = nil
            routeErrorMessage = "Unable to calculate route."
            routeProgress = 0
        }
    }

    private func updateRouteProgress(for coordinate: CLLocationCoordinate2D) {
        guard let activeRoute, let destination = activeDestination else {
            return
        }

        let remaining = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude))
        let original = max(activeRoute.distance, remaining, 1)
        let nextProgress = min(max(1 - (remaining / original), routeProgress), 1)
        routeProgress = nextProgress
    }

    private func updateCurrentUserCoordinate(_ coordinate: CLLocationCoordinate2D) {
        guard let index = snapshot.participants.firstIndex(where: \.isCurrentUser) else { return }
        snapshot.participants[index].coordinate = BSDTourCoordinate(coordinate)
    }

    private var currentUserCoordinate: CLLocationCoordinate2D? {
        snapshot.participants.first(where: \.isCurrentUser)?.coordinate.locationCoordinate
    }

    static func navigationPolyline(
        routePolyline: MKPolyline?,
        source: CLLocationCoordinate2D?,
        destination: CLLocationCoordinate2D?
    ) -> MKPolyline? {
        if let routePolyline {
            return routePolyline
        }

        guard let source, let destination else {
            return nil
        }

        var coordinates = [source, destination]
        return MKPolyline(coordinates: &coordinates, count: coordinates.count)
    }

    private func completionRule(for quest: BSDQuest) -> BSDQuestCompletionRule {
        quest.steps.contains { $0.kind == .qrConfirm } ? .everyParticipant : .anyParticipant
    }

    private func markQuestGroupComplete(_ quest: BSDQuest, completedBy participantID: String?) {
        var completion = snapshot.questCompletions[quest.id] ?? BSDTourQuestCompletionSnapshot(
            completedParticipantIDs: [],
            completedByParticipantID: nil,
            isGroupComplete: false
        )
        completion.completedByParticipantID = completion.completedByParticipantID ?? participantID
        completion.isGroupComplete = true
        snapshot.questCompletions[quest.id] = completion
    }

    private func markQuestGroupCompleteIfReady(_ quest: BSDQuest) {
        let activeIDs = Set(activeParticipants.map(\.id))
        var completion = snapshot.questCompletions[quest.id] ?? BSDTourQuestCompletionSnapshot(
            completedParticipantIDs: [],
            completedByParticipantID: nil,
            isGroupComplete: false
        )
        let completedIDs = Set(completion.completedParticipantIDs)

        if !activeIDs.isEmpty, activeIDs.isSubset(of: completedIDs) {
            completion.isGroupComplete = true
        }

        snapshot.questCompletions[quest.id] = completion
    }

    private func awardQuestRewardIfNeeded(_ quest: BSDQuest, wasGroupComplete: Bool) {
        guard !wasGroupComplete else {
            questFlow.setEarnedPoints(snapshot.earnedPoints)
            return
        }

        snapshot.earnedPoints += quest.reward
        questFlow.setEarnedPoints(snapshot.earnedPoints)
    }

    private func successTitle(for quest: BSDQuest) -> String {
        quest.steps.contains { $0.kind == .quiz } ? "Correct!" : "Quest Complete!"
    }

    private func successSubtitle(for quest: BSDQuest) -> String? {
        guard let completion = snapshot.questCompletions[quest.id] else { return nil }

        switch completionRule(for: quest) {
        case .anyParticipant:
            let name = snapshot.participants.first(where: { $0.id == completion.completedByParticipantID })?.name ?? "a participant"
            return "Completed by \(name)"

        case .everyParticipant:
            return "Everyone completed this quest"
        }
    }

    private func groupWaitMessage(for quest: BSDQuest) -> String {
        let completion = snapshot.questCompletions[quest.id]
        let completeCount = completion?.completedParticipantIDs.count ?? 0
        let total = max(activeParticipants.count, 1)
        return "Waiting for the team. \(completeCount) of \(total) participants have completed this quest."
    }

    private func persist() {
        let snapshot = snapshot
        let previous = persistenceTask
        persistenceTask = Task { [persistenceStore, identity] in
            await previous?.value
            try? await persistenceStore.save(snapshot, for: identity)
        }
    }

    /// Test and lifecycle seam for awaiting all ordered local persistence work.
    func waitForPersistenceOperations() async {
        await persistenceTask?.value
    }

    /// Test and lifecycle seam for waiting until the initial restore has completed.
    func waitForRestore() async {
        await restoreTask?.value
    }

    private static func makeDefaultSnapshot(checkpoints: [BSDTourCheckpoint], identity: BSDTourSessionIdentity) -> BSDTourSnapshot {
        BSDTourSnapshot(
            tourID: identity.tourID,
            phase: .navigatingToMeetingPoint,
            scheduledStartTime: BSDTourConfiguration.scheduledStartTime,
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

    private static func displayParticipant(_ participant: BSDTourParticipant) -> BSDTourParticipantDisplay {
        BSDTourParticipantDisplay(
            id: participant.id,
            name: participant.name,
            avatarImageName: participant.avatarImageName,
            ringColor: Color.bsdTourRingColor(named: participant.ringColorName),
            hasJoined: participant.hasJoined
        )
    }
}

private enum BSDTourDemoQuestID {
    static let firstQuestID = BSDTourQuestDemoData.quests.first?.id ?? "l1-q1"
}

private extension MKMapRect {
    var paddedRegion: MKCoordinateRegion {
        let padding = max(width, height) * 0.35
        return MKCoordinateRegion(
            MKMapRect(
                x: origin.x - padding / 2,
                y: origin.y - padding / 2,
                width: width + padding,
                height: height + padding
            )
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Color {
    static func bsdTourRingColor(named name: String) -> Color {
        switch name {
        case "blue":
            .blue
        case "green":
            .green
        case "pink":
            .pink
        case "red":
            .red
        case "yellow":
            .yellow
        default:
            .accentColor
        }
    }
}
