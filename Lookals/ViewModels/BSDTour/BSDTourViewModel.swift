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
    @ObservationIgnored private var waitingRoomCutoffTask: Task<Void, Never>?
    @ObservationIgnored private var mockParticipantJoinTask: Task<Void, Never>?
    @ObservationIgnored private var routeRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var arrivalPreviewTask: Task<Void, Never>?
    @ObservationIgnored private var arrivalPreviewID: UUID?
    @ObservationIgnored private var lastKnownLocation: CLLocation?
    @ObservationIgnored private var startingRouteDistance: CLLocationDistance?
    @ObservationIgnored private var previewMapRegion: MKCoordinateRegion?
    @ObservationIgnored private var previewRouteCoordinates: [CLLocationCoordinate2D]?
    @ObservationIgnored private var factDebugTrailTask: Task<Void, Never>?

    private(set) var snapshot: BSDTourSnapshot
    private(set) var checkpoints: [BSDTourCheckpoint]
    private(set) var activeRoute: MKRoute?
    private(set) var routeErrorMessage: String?
    private(set) var routeProgress: Double
    private(set) var locationAuthorization: BSDTourLocationAuthorization
    private(set) var factDebugTrailPolyline: MKPolyline?

    var questFlow: BSDTourFlowModel
    var isShakeWidgetExpanded: Bool
    var isCompletionExpanded: Bool
    var isLookalsFactExperienceActive: Bool
    var arrivalFeedbackTick: Int

    init(
        roomRepository: (any BSDTourRoomRepository)? = nil,
        persistenceStore: any BSDTourPersistenceStore,
        routeProvider: (any BSDTourRouteProvider)? = nil,
        clock: (any BSDTourClock)? = nil
    ) {
        let checkpoints = BSDTourConfiguration.checkpoints
        let snapshot = BSDTourViewModel.makeDefaultSnapshot(checkpoints: checkpoints)

        self.roomRepository = roomRepository ?? MockBSDTourRoomRepository()
        self.persistenceStore = persistenceStore
        self.routeProvider = routeProvider ?? MapKitBSDTourRouteProvider()
        self.clock = clock ?? SystemBSDTourClock()
        self.snapshot = snapshot
        self.checkpoints = checkpoints
        self.activeRoute = nil
        self.routeErrorMessage = nil
        self.routeProgress = 0
        self.locationAuthorization = .notDetermined
        self.factDebugTrailPolyline = nil
        self.questFlow = BSDTourFlowModel(
            currentQuestIndex: snapshot.currentQuestIndex,
            currentStepIndex: snapshot.currentStepIndex,
            earnedPoints: snapshot.earnedPoints,
            isWidgetExpanded: false
        )
        self.isShakeWidgetExpanded = false
        self.isCompletionExpanded = snapshot.tourCompleted && !snapshot.userEndedTour
        self.isLookalsFactExperienceActive = false
        self.arrivalFeedbackTick = 0

        configureQuestCallbacks()
    }

    deinit {
        waitingRoomCutoffTask?.cancel()
        mockParticipantJoinTask?.cancel()
        routeRefreshTask?.cancel()
        arrivalPreviewTask?.cancel()
        factDebugTrailTask?.cancel()
    }

    var phase: BSDTourPhase {
        snapshot.phase
    }

    var title: String {
        "The Blueprint"
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
        snapshot.participants.filter {
            $0.status == .joined || ($0.isCurrentUser && $0.status != .removed)
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
        guard let destination = activeDestination else {
            return "Route"
        }

        let userLocation = snapshot.participants.first(where: \.isCurrentUser)?.coordinate.locationCoordinate
        guard let userLocation else {
            guard let activeRoute else { return "Route" }
            return "\(Int(activeRoute.distance.rounded()))m"
        }

        let remaining = distance(from: userLocation, to: destination.coordinate)
        return "\(Int(max(0, remaining).rounded()))m"
    }

    var navigationPolyline: MKPolyline? {
        if isLookalsFactExperienceActive, let completedTrailPolyline {
            return completedTrailPolyline
        }

        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else {
            return nil
        }

        if arrivalPreviewID != nil, let previewRouteCoordinates {
            return Self.remainingPolyline(after: routeProgress, along: previewRouteCoordinates)
        }

        return Self.navigationPolyline(
            routePolyline: activeRoute?.polyline,
            source: currentUserCoordinate,
            destination: activeDestination?.coordinate
        )
    }

    var mapRegion: MKCoordinateRegion {
        if let previewMapRegion {
            return previewMapRegion
        }

        if isLookalsFactExperienceActive, let completedTrailPolyline {
            return completedTrailPolyline.boundingMapRect.paddedRegion
        }

        if shouldFollowCurrentUserOnMap, let currentUserCoordinate {
            return MKCoordinateRegion(
                center: currentUserCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )
        }

        if let navigationPolyline {
            return navigationPolyline.boundingMapRect.paddedRegion
        }

        let center = activeDestination?.coordinate ?? checkpoints[0].coordinate
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    }

    private var shouldFollowCurrentUserOnMap: Bool {
        switch phase {
        case .joinedWaitingRoom, .quest, .questSuccess:
            true
        case .navigatingToMeetingPoint, .navigatingToCheckpoint, .waitingToShake,
             .unavailable, .tourCompleted, .tourEnded:
            false
        }
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

    func start(locationService: BSDTourLocationService, shakeDetector: BSDTourShakeDetector) async {
        locationAuthorization = locationService.authorization
        locationService.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        shakeDetector.onShake = { [weak self] in
            self?.handleShake()
        }
        shakeDetector.start()

        await restore()
        processScheduledCutoffIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()

        routeRefreshTask?.cancel()
        routeRefreshTask = Task { [weak self] in
            await self?.refreshRouteIfNeeded()
        }
    }

    func appBecameActive() {
        processScheduledCutoffIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
    }

    func updateLocationAuthorization(_ authorization: BSDTourLocationAuthorization) {
        locationAuthorization = authorization
    }

    func handleLocationUpdate(_ location: CLLocation) {
        #if DEBUG
        // The BSD Tour uses its fixed RM. Medan Ria route while recording a demo.
        return
        #else
        guard arrivalPreviewID == nil else { return }

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
        #endif
    }

    func handleShake() {
        guard canAcceptShake else { return }

        snapshot = roomRepository.join(participantID: BSDTourConfiguration.currentUserID, in: snapshot)
        snapshot.phase = .joinedWaitingRoom
        isShakeWidgetExpanded = false
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        scheduleMockParticipantJoins()
        persist()
    }

    func joinNextMockParticipant() {
        snapshot = roomRepository.joinNextMockParticipant(in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func joinAllParticipants() {
        mockParticipantJoinTask?.cancel()
        mockParticipantJoinTask = nil
        snapshot = roomRepository.joinAllParticipants(in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func showLookalsFactDebug() {
        guard let factCheckpointIndex = checkpoints.firstIndex(where: { $0.name == "Bus Stop" }) else {
            return
        }

        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        mockParticipantJoinTask?.cancel()
        mockParticipantJoinTask = nil
        arrivalPreviewTask?.cancel()
        arrivalPreviewTask = nil
        arrivalPreviewID = nil
        previewMapRegion = nil
        previewRouteCoordinates = nil
        activeRoute = nil
        routeProgress = 1
        factDebugTrailTask?.cancel()
        factDebugTrailTask = nil

        snapshot = Self.makeDefaultSnapshot(checkpoints: checkpoints)
        snapshot.currentCheckpointIndex = factCheckpointIndex
        snapshot.phase = .joinedWaitingRoom
        snapshot.earnedPoints = 150
        let completedCheckpoints = Array(checkpoints.prefix(through: factCheckpointIndex))
        let completedCheckpointIDs = completedCheckpoints.map(\.id)
        snapshot.revealedCheckpointIDs = completedCheckpointIDs
        snapshot.reachedCheckpointIDs = completedCheckpointIDs
        factDebugTrailPolyline = Self.polyline(for: completedCheckpoints)
        questFlow.setEarnedPoints(snapshot.earnedPoints)
        snapshot = roomRepository.joinAllParticipants(in: snapshot)
        positionJoinedParticipants(at: checkpoints[factCheckpointIndex].coordinate)
        isShakeWidgetExpanded = false
        isCompletionExpanded = false
        isLookalsFactExperienceActive = true
        loadFactDebugWalkingTrail(through: completedCheckpoints)
        persist()
    }

    func activateLookalsFactExperience() {
        isShakeWidgetExpanded = false
        isLookalsFactExperienceActive = true
    }

    func triggerCutoff() {
        snapshot.scheduledStartTime = Calendar.current.date(byAdding: .minute, value: -6, to: clock.now) ?? clock.now
        processScheduledCutoffIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func simulateArrival() {
        guard let destination = activeDestination else { return }
        arrive(at: destination)
    }

    func previewArrivalFromMedanRia() {
        guard let destination = activeDestination else { return }
        guard phase == .navigatingToMeetingPoint || phase == .navigatingToCheckpoint else { return }

        arrivalPreviewTask?.cancel()
        routeRefreshTask?.cancel()
        routeRefreshTask = nil
        activeRoute = nil
        previewRouteCoordinates = nil

        let startingCoordinate = BSDTourConfiguration.medanRiaCoordinate.locationCoordinate
        startingRouteDistance = distance(from: startingCoordinate, to: destination.coordinate)
        routeProgress = 0
        updateCurrentUserCoordinate(startingCoordinate)
        let previewID = UUID()
        arrivalPreviewID = previewID

        arrivalPreviewTask = Task { [weak self] in
            defer {
                self?.finishArrivalPreview(id: previewID)
            }

            guard let self else { return }

            let route = try? await self.routeProvider.route(
                from: startingCoordinate,
                to: destination.coordinate
            )
            guard !Task.isCancelled, self.arrivalPreviewID == previewID else { return }

            self.activeRoute = route

            let routePolyline = Self.navigationPolyline(
                routePolyline: route?.polyline,
                source: startingCoordinate,
                destination: destination.coordinate
            )
            self.previewMapRegion = routePolyline?.boundingMapRect.paddedRegion
            let routeCoordinates = routePolyline.map { Self.coordinates(in: $0) }
                ?? [startingCoordinate, destination.coordinate]
            self.previewRouteCoordinates = routeCoordinates

            let frameCount = 250

            for frame in 0...frameCount {
                guard !Task.isCancelled, self.arrivalPreviewID == previewID else { return }

                let linearProgress = Double(frame) / Double(frameCount)
                let progress = linearProgress * linearProgress * (3 - (2 * linearProgress))
                let simulatedCoordinate = Self.coordinate(at: progress, along: routeCoordinates)

                self.updateCurrentUserCoordinate(simulatedCoordinate)
                self.routeProgress = progress

                if frame < frameCount {
                    do {
                        try await Task.sleep(for: .milliseconds(20))
                    } catch {
                        return
                    }
                }
            }

            guard !Task.isCancelled else { return }
            self.simulateArrival()
        }
    }

    func simulateLeavingArrivalRadius() {
        routeProgress = min(routeProgress, 0.85)
    }

    func completeCurrentQuestForAllParticipants() {
        guard let quest = questFlow.currentQuest else { return }
        guard snapshot.phase == .quest else { return }

        let wasGroupComplete = snapshot.questCompletions[quest.id]?.isGroupComplete == true
        snapshot = roomRepository.completeQuestForAllActiveParticipants(quest.id, in: snapshot)
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
        snapshot.userEndedTour = true
        snapshot.phase = .tourEnded
        isCompletionExpanded = false
        persist()
    }

    func reset() {
        activeRoute = nil
        routeErrorMessage = nil
        routeProgress = 0
        startingRouteDistance = nil
        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        mockParticipantJoinTask?.cancel()
        mockParticipantJoinTask = nil
        arrivalPreviewTask?.cancel()
        arrivalPreviewTask = nil
        arrivalPreviewID = nil
        previewMapRegion = nil
        previewRouteCoordinates = nil
        factDebugTrailTask?.cancel()
        factDebugTrailTask = nil
        factDebugTrailPolyline = nil
        snapshot = Self.makeDefaultSnapshot(checkpoints: checkpoints)
        #if !DEBUG
        if let lastKnownLocation {
            updateCurrentUserCoordinate(lastKnownLocation.coordinate)
        }
        #endif
        isShakeWidgetExpanded = false
        isCompletionExpanded = false
        isLookalsFactExperienceActive = false
        questFlow.setEarnedPoints(0)
        questFlow.moveToQuest(
            withID: BSDTourQuestDemoData.quests.first?.id ?? "",
            expanded: false,
            notifiesStepChange: false
        )
        Task {
            try? await persistenceStore.reset(tourID: BSDTourConfiguration.tourID)
            await refreshRouteIfNeeded()
        }
    }

    private func restore() async {
        guard let restored = try? await persistenceStore.loadSnapshot(tourID: BSDTourConfiguration.tourID) else {
            persist()
            return
        }

        snapshot = restored
        let normalizedParticipants = Self.normalizedParticipants(from: snapshot.participants)
        if snapshot.participants != normalizedParticipants {
            snapshot.participants = normalizedParticipants
            persist()
        }
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

        if snapshot.phase == .joinedWaitingRoom {
            scheduleMockParticipantJoins()
        }
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

        let currentUserID = BSDTourConfiguration.currentUserID
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
        startingRouteDistance = nil
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
        mockParticipantJoinTask?.cancel()
        mockParticipantJoinTask = nil
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
            do {
                try await Task.sleep(for: .seconds(secondsUntilCutoff))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            self?.processScheduledCutoffIfNeeded()
        }
    }

    private func scheduleMockParticipantJoins() {
        mockParticipantJoinTask?.cancel()

        guard phase == .joinedWaitingRoom,
              !snapshot.waitingRoomClosed,
              snapshot.participants.contains(where: { !$0.isCurrentUser && $0.status == .invited }) else {
            mockParticipantJoinTask = nil
            return
        }

        mockParticipantJoinTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    return
                }

                guard let self,
                      self.phase == .joinedWaitingRoom,
                      !self.snapshot.waitingRoomClosed,
                      self.snapshot.participants.contains(where: { !$0.isCurrentUser && $0.status == .invited }) else {
                    return
                }

                self.joinNextMockParticipant()
            }
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
        guard let destination = activeDestination else {
            return
        }

        let remaining = distance(from: coordinate, to: destination.coordinate)
        let original = max(startingRouteDistance ?? activeRoute?.distance ?? remaining, 1)
        startingRouteDistance = original
        let nextProgress = min(max(1 - (remaining / original), routeProgress), 1)
        routeProgress = nextProgress
    }

    private func distance(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: source.latitude, longitude: source.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }

    private func finishArrivalPreview(id: UUID) {
        guard arrivalPreviewID == id else { return }
        arrivalPreviewID = nil
        arrivalPreviewTask = nil
        previewMapRegion = nil
        previewRouteCoordinates = nil
    }

    private func updateCurrentUserCoordinate(_ coordinate: CLLocationCoordinate2D) {
        guard let index = snapshot.participants.firstIndex(where: \.isCurrentUser) else { return }
        snapshot.participants[index].coordinate = BSDTourCoordinate(coordinate)
    }

    private func positionJoinedParticipants(at coordinate: CLLocationCoordinate2D) {
        let offsets: [(latitude: Double, longitude: Double)] = [
            (0.00008, 0),
            (0.00006, 0.000055),
            (0.00006, -0.000055),
            (0.00002, 0.00008),
            (0.00002, -0.00008)
        ]
        let joinedIndexes = snapshot.participants.indices.filter {
            snapshot.participants[$0].status == .joined
        }

        for (offsetIndex, participantIndex) in joinedIndexes.enumerated() {
            let offset = offsets[offsetIndex % offsets.count]
            snapshot.participants[participantIndex].coordinate = BSDTourCoordinate(
                latitude: coordinate.latitude + offset.latitude,
                longitude: coordinate.longitude + offset.longitude
            )
        }
    }

    private var currentUserCoordinate: CLLocationCoordinate2D? {
        snapshot.participants.first(where: \.isCurrentUser)?.coordinate.locationCoordinate
    }

    private var completedTrailPolyline: MKPolyline? {
        if let factDebugTrailPolyline {
            return factDebugTrailPolyline
        }

        let completedCheckpoints = checkpoints.filter {
            snapshot.reachedCheckpointIDs.contains($0.id)
        }
        return Self.polyline(for: completedCheckpoints)
    }

    private func loadFactDebugWalkingTrail(through checkpoints: [BSDTourCheckpoint]) {
        guard checkpoints.count > 1 else { return }

        factDebugTrailTask?.cancel()
        factDebugTrailTask = Task { [weak self] in
            guard let self else { return }

            var routeCoordinates: [CLLocationCoordinate2D] = []

            for index in 0..<(checkpoints.count - 1) {
                guard !Task.isCancelled else { return }

                let source = checkpoints[index].coordinate
                let destination = checkpoints[index + 1].coordinate
                let segmentCoordinates: [CLLocationCoordinate2D]

                if let route = try? await self.routeProvider.route(from: source, to: destination) {
                    segmentCoordinates = Self.coordinates(in: route.polyline)
                } else {
                    segmentCoordinates = [source, destination]
                }

                if routeCoordinates.isEmpty {
                    routeCoordinates.append(contentsOf: segmentCoordinates)
                } else {
                    routeCoordinates.append(contentsOf: segmentCoordinates.dropFirst())
                }
            }

            guard !Task.isCancelled, routeCoordinates.count > 1 else { return }
            var coordinates = routeCoordinates
            self.factDebugTrailPolyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        }
    }

    private static func polyline(for checkpoints: [BSDTourCheckpoint]) -> MKPolyline? {
        guard checkpoints.count > 1 else { return nil }

        var coordinates = checkpoints.map(\.coordinate)
        return MKPolyline(coordinates: &coordinates, count: coordinates.count)
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

    private static func coordinates(in polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        guard polyline.pointCount > 0 else { return [] }

        var coordinates = Array(
            repeating: CLLocationCoordinate2D(),
            count: polyline.pointCount
        )
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        return coordinates
    }

    private static func coordinate(
        at progress: Double,
        along coordinates: [CLLocationCoordinate2D]
    ) -> CLLocationCoordinate2D {
        guard let first = coordinates.first else {
            return BSDTourConfiguration.medanRiaCoordinate.locationCoordinate
        }
        guard coordinates.count > 1 else { return first }

        let segments = zip(coordinates, coordinates.dropFirst()).map { start, end in
            (start, end, CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)))
        }
        let totalDistance = segments.reduce(0) { $0 + $1.2 }
        guard totalDistance > 0 else { return first }

        let targetDistance = min(max(progress, 0), 1) * totalDistance
        var distanceCovered: CLLocationDistance = 0

        for (start, end, segmentDistance) in segments {
            let nextDistance = distanceCovered + segmentDistance
            if targetDistance <= nextDistance, segmentDistance > 0 {
                let segmentProgress = (targetDistance - distanceCovered) / segmentDistance
                return CLLocationCoordinate2D(
                    latitude: start.latitude + (end.latitude - start.latitude) * segmentProgress,
                    longitude: start.longitude + (end.longitude - start.longitude) * segmentProgress
                )
            }
            distanceCovered = nextDistance
        }

        return coordinates[coordinates.count - 1]
    }

    private static func remainingPolyline(
        after progress: Double,
        along coordinates: [CLLocationCoordinate2D]
    ) -> MKPolyline? {
        guard coordinates.count > 1 else { return nil }

        let segments = zip(coordinates, coordinates.dropFirst()).map { start, end in
            CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        }
        let totalDistance = segments.reduce(0, +)
        guard totalDistance > 0 else { return nil }

        let targetDistance = min(max(progress, 0), 1) * totalDistance
        var distanceCovered: CLLocationDistance = 0

        for (index, segmentDistance) in segments.enumerated() {
            let nextDistance = distanceCovered + segmentDistance
            if targetDistance <= nextDistance {
                var remainingCoordinates = [coordinate(at: progress, along: coordinates)]
                remainingCoordinates.append(contentsOf: coordinates.dropFirst(index + 1))

                guard remainingCoordinates.count > 1 else { return nil }
                return MKPolyline(
                    coordinates: &remainingCoordinates,
                    count: remainingCoordinates.count
                )
            }
            distanceCovered = nextDistance
        }

        return nil
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
        Task {
            try? await persistenceStore.saveSnapshot(snapshot)
        }
    }

    private static func makeDefaultSnapshot(checkpoints: [BSDTourCheckpoint]) -> BSDTourSnapshot {
        BSDTourSnapshot(
            tourID: BSDTourConfiguration.tourID,
            phase: .navigatingToMeetingPoint,
            scheduledStartTime: BSDTourConfiguration.scheduledStartTime,
            participants: BSDTourConfiguration.participants,
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

    private static func normalizedParticipants(
        from storedParticipants: [BSDTourParticipant]
    ) -> [BSDTourParticipant] {
        let storedByID = Dictionary(uniqueKeysWithValues: storedParticipants.map { ($0.id, $0) })

        return BSDTourConfiguration.participants.map { configuredParticipant in
            let storedParticipant = storedByID[configuredParticipant.id]
                ?? (configuredParticipant.id == "zee" ? storedByID["julian"] : nil)

            guard let storedParticipant else { return configuredParticipant }

            var participant = configuredParticipant
            participant.status = storedParticipant.status
            participant.coordinate = storedParticipant.coordinate
            return participant
        }
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
