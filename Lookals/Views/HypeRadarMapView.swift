//
//  HypeRadarMapView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import MapKit
import SwiftUI

struct HypeRadarMapView: View {
    let state: HypeRadarMapState
    let onBack: () -> Void
    let onLocate: () -> Void
    let onOpenCamera: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraPosition: MapCameraPosition = .region(Self.mapRegion)
    @State private var isQuizWidgetExpanded = false
    @State private var isQuizWidgetVisible = false
    @State private var selectedQuizOption: String?

    private static let mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7478, longitude: -73.9854),
        span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.055)
    )

    init(
        state: HypeRadarMapState = .goingToMeetingPoint,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {},
        onOpenCamera: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onBack = onBack
        self.onLocate = onLocate
        self.onOpenCamera = onOpenCamera
        self._isQuizWidgetVisible = State(initialValue: state == .quiz)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    mapBackground

                    OngoingCloudOverlay()

                    radarMarkers(in: proxy.size)

                    bottomOverlay
                }
                .padding(.bottom, 10)
                .ignoresSafeArea()
            }
            .navigationTitle("Hype Radar Map")
            .toolbarTitleDisplayMode(.inline)
            .onChange(of: state, initial: true) { _, newState in
                prepareWidgetState(for: newState)
            }
            .toolbar {
                ToolbarIconButton(
                    placement: .topBarLeading,
                    systemImage: "chevron.left",
                    accessibilityLabel: "Go back",
                    background: .white,
                    action: onBack
                )

                ToolbarIconButton(
                    placement: .topBarTrailing,
                    systemImage: "location.north.fill",
                    accessibilityLabel: "Show current location",
                    background: .accent,
                    foreground: .white,
                    action: onLocate
                )
            }
        }
    }

    private var mapBackground: some View {
        Map(position: $cameraPosition, interactionModes: .pan)
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .saturation(0.72)
        .opacity(0.82)
        .overlay(Color.white.opacity(0.16))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func radarMarkers(in size: CGSize) -> some View {
        Group {
            switch state {
            case .goingToMeetingPoint:
                RadarMarker(style: .smallDestination)
                    .position(x: size.width * 0.30, y: size.height * 0.56)

                RadarMarker(style: .avatar)
                    .position(x: size.width * 0.36, y: size.height * 0.66)

                RadarMarker(style: .mapBadge("9A"))
                    .position(x: size.width * 0.30, y: size.height * 0.42)

            case .arrived:
                RadarMarker(style: .place)
                    .position(x: size.width * 0.43, y: size.height * 0.56)

                RadarMarker(style: .avatar)
                    .position(x: size.width * 0.54, y: size.height * 0.59)

            case .shakeYourPhone, .quiz:
                RadarMarker(style: .place)
                    .position(x: size.width * 0.43, y: size.height * 0.56)

                RadarMarker(style: .avatar)
                    .position(x: size.width * 0.54, y: size.height * 0.59)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        switch state {
        case .goingToMeetingPoint:
            bottomStatusCard(state: state, bottomPadding: 32)

        case .arrived:
            ZStack {
                bottomStatusCard(state: state, bottomPadding: 32)
                mapUtilityControls(bottomPadding: 224)
            }

        case .shakeYourPhone:
            ZStack {
                bottomStatusCard(state: .arrived, bottomPadding: 132)

                ExpandableWidget(
                    isExpanded: $isQuizWidgetExpanded,
                    collapsedMaxWidth: 392,
                    expandedMaxWidth: 360,
                    horizontalPadding: 20,
                    edgePadding: 16
                ) {
                    ShakePhoneCollapsedContent()
                } expandedContent: {
                    ShakePhoneQuestContent()
                }
            }

        case .quiz:
            ZStack {
                if !isQuizWidgetExpanded {
                    bottomStatusCard(state: .arrived, bottomPadding: isQuizWidgetVisible ? 132 : 32)
                    mapUtilityControls(bottomPadding: isQuizWidgetVisible ? 324 : 224)
                }

                if isQuizWidgetVisible {
                    quizWidget
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func bottomStatusCard(state: HypeRadarMapState, bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            OngoingBottomStatusCard(state: state)
                .padding(.horizontal, 20)
                .padding(.bottom, bottomPadding)
        }
    }

    private func mapUtilityControls(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                HypeRadarPointsBadge(points: selectedQuizOption == nil ? 0 : 30)

                Spacer()

                HypeRadarCameraButton(action: onOpenCamera)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, bottomPadding)
        }
    }

    private var quizWidget: some View {
        HypeRadarQuizWidget(
            isExpanded: $isQuizWidgetExpanded,
            selectedOption: $selectedQuizOption,
            onSubmit: { submitQuiz() }
        )
    }

    private func prepareWidgetState(for state: HypeRadarMapState) {
        isQuizWidgetExpanded = false
        selectedQuizOption = nil

        let shouldShowQuizWidget = state == .quiz

        if reduceMotion {
            isQuizWidgetVisible = shouldShowQuizWidget
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                isQuizWidgetVisible = shouldShowQuizWidget
            }
        }
    }

    private func submitQuiz() {
        isQuizWidgetExpanded = false
    }
}

#Preview("Going to meeting point") {
    HypeRadarMapView(state: .goingToMeetingPoint)
}

#Preview("Arrived") {
    HypeRadarMapView(state: .arrived)
}

#Preview("Shake Your Phone") {
    HypeRadarMapView(state: .shakeYourPhone)
}
#Preview("Quiz") {
    HypeRadarMapView(state: .quiz)
}

