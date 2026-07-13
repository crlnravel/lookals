//
//  BSDTourMapView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import MapKit
import SwiftUI

private struct BSDTourMemoryCameraRequest: Identifiable {
    let albumID: UUID

    var id: UUID { albumID }
}

struct BSDTourMapView: View {
    @Environment(\.scenePhase) private var scenePhase

    let onBack: () -> Void
    let onLocate: () -> Void
    private let automaticallyStartArrivalPreview: Bool

    @State private var viewModel: BSDTourViewModel
    @State private var memoriesViewModel: MemoriesViewModel
    @State private var locationService = BSDTourLocationService()
    @State private var shakeDetector = BSDTourShakeDetector()
    @State private var cameraStep: BSDQuestStep?
    @State private var hasStarted = false
    @State private var isDebugControlsPresented = false
    @State private var activeMemoryCamera: BSDTourMemoryCameraRequest?
    @State private var isLookalsFactPresented = false

    init(
        dependencies: AppDependencies = .preview,
        automaticallyStartArrivalPreview: Bool = false,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {}
    ) {
        self._viewModel = State(
            initialValue: BSDTourViewModel(
                persistenceStore: dependencies.bsdTourPersistenceStore
            )
        )
        self._memoriesViewModel = State(
            initialValue: MemoriesViewModel(memoryPhotoService: dependencies.memoryPhotoService)
        )
        self.automaticallyStartArrivalPreview = automaticallyStartArrivalPreview
        self.onBack = onBack
        self.onLocate = onLocate
    }

    var body: some View {
        CustomMapView(
            title: viewModel.title,
            region: viewModel.mapRegion,
            markers: [],
            coordinateMarkers: coordinateMarkers,
            navigationPolyline: viewModel.navigationPolyline,
            showsUserLocation: true,
            onBack: onBack,
            onLocate: locateTapped,
            trailingAction: trailingMapHeaderAction
        ) {
            MapCloudOverlay(stage: viewModel.currentCloudStage)
        } bottomOverlay: {
            bottomOverlay
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $cameraStep) { step in
            CameraCaptureSheet { photoData in
                viewModel.questFlow.updateCapturedPhotoData(photoData, for: step)
                cameraStep = nil
                viewModel.questFlow.advance()
            } onCancel: {
                cameraStep = nil
            }
        }
        .sheet(item: $activeMemoryCamera) { request in
            NavigationStack {
                AddMemoryCameraView(
                    albumID: request.albumID,
                    viewModel: memoriesViewModel
                )
            }
        }
        .overlay { factOverlay }
        .sensoryFeedback(.success, trigger: viewModel.arrivalFeedbackTick)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            await viewModel.start(locationService: locationService, shakeDetector: shakeDetector)
            locationService.requestAuthorizationAndStart()

            if automaticallyStartArrivalPreview {
                viewModel.previewArrivalFromMedanRia()
            }
        }
        .onChange(of: locationService.authorization, initial: true) { _, newValue in
            viewModel.updateLocationAuthorization(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            viewModel.appBecameActive()
        }
    }

    private var coordinateMarkers: [CustomCoordinateMapMarker] {
        var markers: [CustomCoordinateMapMarker] = []

        markers.append(contentsOf: checkpointMarkers)
        markers.append(contentsOf: participantMarkers)

        return markers
    }

    @ViewBuilder
    private var factOverlay: some View {
            if isLookalsFactPresented, let fact = busStopFact {
                LookalsFactPopup(fact: fact, onDismiss: dismissLookalsFact)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(1)
        }
    }

    private var checkpointMarkers: [CustomCoordinateMapMarker] {
        var markers: [CustomCoordinateMapMarker] = []

        for checkpoint in viewModel.checkpoints {
            guard let style = markerStyle(for: checkpoint) else {
                continue
            }

            let action: (() -> Void)?
            if checkpoint.id == factCheckpointID {
                action = presentBusStopFact
            } else {
                action = nil
            }

            markers.append(CustomCoordinateMapMarker(
                id: "checkpoint-\(checkpoint.id)-\(style.accessibilityLabel)",
                style: style,
                coordinate: checkpoint.coordinate,
                action: action
            ))
        }

        return markers
    }

    private var participantMarkers: [CustomCoordinateMapMarker] {
        viewModel.mapParticipants.map { participant in
            CustomCoordinateMapMarker(
                id: "participant-\(participant.id)",
                style: .participantAvatar(
                    imageName: participant.avatarImageName,
                    ringColor: Color.bsdTourRingColor(named: participant.ringColorName),
                    label: participant.name
                ),
                coordinate: markerCoordinate(for: participant)
            )
        }
    }

    private func markerCoordinate(for participant: BSDTourParticipant) -> CLLocationCoordinate2D {
        guard participant.isCurrentUser,
              !viewModel.shouldShowRouteCard,
              let destination = viewModel.activeDestination else {
            return participant.coordinate.locationCoordinate
        }

        return CLLocationCoordinate2D(
            latitude: destination.coordinate.latitude + 0.00006,
            longitude: destination.coordinate.longitude
        )
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        ZStack {
            baseControls

            switch viewModel.phase {
            case .unavailable:
                unavailableOverlay

            case .tourCompleted:
                completionOverlay

            case .tourEnded:
                EmptyView()

            default:
                tourOverlay
            }

            debugOverlay
        }
    }

    private var baseControls: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                MapPointsBadge(points: viewModel.questFlow.earnedPoints)

                Spacer()

                MapCameraButton(action: presentMemoryCamera)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, baseControlsBottomPadding)
        }
    }

    private var baseControlsBottomPadding: CGFloat {
        if viewModel.shouldShowQuestWidget, !viewModel.questFlow.isWidgetExpanded {
            return 265
        }

        if viewModel.phase == .tourCompleted, !viewModel.isCompletionExpanded {
            return 145
        }

        return 176
    }

    private var tourOverlay: some View {
        ZStack {
            if shouldShowStatusCard {
                statusCard(bottomPadding: statusCardBottomPadding)
            }

            if viewModel.canShowShakeWidget && !viewModel.isLookalsFactExperienceActive {
                shakeWidget
            }

            if viewModel.shouldShowQuestWidget {
                BSDTourQuestWidget(
                    flow: viewModel.questFlow,
                    onPhotoRequested: presentCamera
                )
            }
        }
    }

    private var shouldShowStatusCard: Bool {
        viewModel.shouldShowRouteCard ||
        viewModel.phase == .waitingToShake ||
        viewModel.phase == .joinedWaitingRoom ||
        viewModel.shouldShowQuestWidget
    }

    private var statusCardBottomPadding: CGFloat {
        if viewModel.canShowShakeWidget && !viewModel.isLookalsFactExperienceActive {
            return 132
        }

        if viewModel.shouldShowQuestWidget, !viewModel.questFlow.isWidgetExpanded {
            return 130
        }

        return 32
    }

    private func statusCard(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            BSDTourBottomStatusCard(
                title: statusTitle,
                subtitle: statusSubtitle,
                progress: statusProgress,
                isArrived: !viewModel.shouldShowRouteCard,
                participants: viewModel.joinedParticipantsForDisplay
            )
            .padding(.horizontal, 20)
            .padding(.bottom, bottomPadding)
        }
    }

    private var statusTitle: String {
        if viewModel.shouldShowRouteCard {
            return viewModel.routeCardTitle
        }

        return viewModel.activeDestination?.name ?? "BSD Tour"
    }

    private var statusSubtitle: String {
        if viewModel.shouldShowRouteCard {
            return viewModel.routeCardSubtitle
        }

        return viewModel.arrivedCardSubtitle
    }

    private var statusProgress: Double {
        viewModel.shouldShowRouteCard ? viewModel.routeProgress : 1
    }

    private var shakeWidget: some View {
        ExpandableWidget(
            isExpanded: $viewModel.isShakeWidgetExpanded,
            collapsedMaxWidth: 392,
            expandedMaxWidth: 360,
            horizontalPadding: 20,
            edgePadding: 16
        ) {
            ShakePhoneCollapsedContent(participants: viewModel.joinedParticipantsForDisplay)
        } expandedContent: {
            ShakePhoneQuestContent(participants: viewModel.joinedParticipantsForDisplay)
        }
    }

    private var completionOverlay: some View {
        ExpandableWidget(
            isExpanded: $viewModel.isCompletionExpanded,
            collapsedMaxWidth: 392,
            expandedMaxWidth: 360,
            horizontalPadding: 20,
            edgePadding: 16
        ) {
            BSDTourCompletionCollapsedContent(points: viewModel.questFlow.earnedPoints)
        } expandedContent: {
            BSDTourCompletionExpandedContent(
                points: viewModel.questFlow.earnedPoints,
                participants: viewModel.joinedParticipantsForDisplay,
                onFinish: viewModel.finishTour
            )
        }
    }

    private var unavailableOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            BSDTourUnavailableCard(onBack: onBack)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private var debugOverlay: some View {
        #if DEBUG
        if isDebugControlsPresented {
            VStack(spacing: 0) {
                Spacer()

                HStack {
                    BSDTourDebugControls(
                        viewModel: viewModel,
                        shakeDetector: shakeDetector,
                        isPresented: $isDebugControlsPresented,
                        onFactRequested: presentBusStopFact
                    )
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 24)
            }
        }
        #else
        EmptyView()
        #endif
    }

    private func markerStyle(for checkpoint: BSDTourCheckpoint) -> RadarMarkerStyle? {
        if checkpoint.id == factCheckpointID {
            return .pulsatingLandmark(
                imageName: "BSDMap/MuseumIcon",
                label: checkpoint.name
            )
        }

        if viewModel.snapshot.revealedCheckpointIDs.contains(checkpoint.id) {
            return .landmark(imageName: checkpoint.landmarkImageName, label: checkpoint.name)
        }

        if viewModel.activeDestination?.id == checkpoint.id,
           viewModel.phase == .navigatingToMeetingPoint || viewModel.phase == .navigatingToCheckpoint {
            return viewModel.phase == .navigatingToMeetingPoint ? .smallDestination : .unknownCheckpoint
        }

        return nil
    }

    private func presentCamera(for step: BSDQuestStep) {
        cameraStep = step
    }

    private func presentMemoryCamera() {
        guard let tourMap = TourMap.sampleData.first else { return }

        let albumID = memoriesViewModel.prepareAlbum(for: tourMap)
        activeMemoryCamera = BSDTourMemoryCameraRequest(albumID: albumID)
    }

    private var factCheckpointID: String? {
        viewModel.checkpoints.first(where: { $0.name == "Bus Stop" })?.id
    }

    private var busStopFact: LookalsFact? {
        dummyBSDRoute.stops.first(where: { $0.name == "Bus Stop" })?.fact
    }

    private func presentBusStopFact() {
        viewModel.activateLookalsFactExperience()
        withAnimation(.smooth(duration: 0.25)) {
            isLookalsFactPresented = true
        }
    }

    private func dismissLookalsFact() {
        withAnimation(.smooth(duration: 0.2)) {
            isLookalsFactPresented = false
        }
    }

    private func locateTapped() {
        onLocate()
        locationService.requestAuthorizationAndStart()
    }

    private var trailingMapHeaderAction: CustomMapHeaderAction? {
        #if DEBUG
        CustomMapHeaderAction(
            systemImage: "location",
            accessibilityLabel: "Open debug controls",
            background: Color.accentColor,
            foreground: .white,
            action: { isDebugControlsPresented = true }
        )
        #else
        nil
        #endif
    }
}

#Preview("BSD Tour Map") {
    BSDTourMapView()
}
