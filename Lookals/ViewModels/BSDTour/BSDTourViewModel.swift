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
    @ObservationIgnored private var routeRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var lastKnownLocation: CLLocation?

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
        snapshot.participants.filter { $0.status == .joined }
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
        locationAuthorization = locationService.authorization
        locationService.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        shakeDetector.onShake = { [weak self] in
            self?.handleShake()
        }
        shakeDetector.start()

        Task {
            await restore()
            processScheduledCutoffIfNeeded()
            scheduleWaitingRoomCutoffIfNeeded()
            await refreshRouteIfNeeded()
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
    }

    func handleShake() {
        guard canAcceptShake else { return }

        snapshot = roomRepository.join(participantID: BSDTourConfiguration.currentUserID, in: snapshot)
        snapshot.phase = .joinedWaitingRoom
        isShakeWidgetExpanded = false
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func joinNextMockParticipant() {
        snapshot = roomRepository.joinNextMockParticipant(in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
    }

    func joinAllParticipants() {
        snapshot = roomRepository.joinAllParticipants(in: snapshot)
        processWaitingRoomCompletionIfNeeded()
        scheduleWaitingRoomCutoffIfNeeded()
        persist()
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
        waitingRoomCutoffTask?.cancel()
        waitingRoomCutoffTask = nil
        snapshot = Self.makeDefaultSnapshot(checkpoints: checkpoints)
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
