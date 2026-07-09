//
//  HypeRadarMapView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct HypeRadarMapView: View {
    let onBack: () -> Void
    let onLocate: () -> Void
    let onOpenCamera: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state: HypeRadarMapState
    @State private var isQuizWidgetExpanded = false
    @State private var isQuizWidgetVisible = false
    @State private var selectedQuizOption: String?

    init(
        phase: HypeRadarMapPhase = .goingToMeetingPoint,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {},
        onOpenCamera: @escaping () -> Void = {}
    ) {
        self.init(
            state: HypeRadarMapState(phase: phase),
            onBack: onBack,
            onLocate: onLocate,
            onOpenCamera: onOpenCamera
        )
    }

    init(
        state: HypeRadarMapState,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {},
        onOpenCamera: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onLocate = onLocate
        self.onOpenCamera = onOpenCamera
        self._state = State(initialValue: state)
        self._isQuizWidgetVisible = State(initialValue: state.phase == .quiz)
    }

    var body: some View {
        CustomMapView(
            title: state.title,
            region: state.region,
            markers: state.markers,
            onBack: onBack,
            onLocate: onLocate
        ) {
            MapCloudOverlay()
        } bottomOverlay: {
            bottomOverlay
        }
        .onChange(of: state.phase, initial: true) { _, newPhase in
            prepareWidgetState(for: newPhase)
        }
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        switch state.phase {
        case .goingToMeetingPoint:
            bottomStatusCard(phase: state.phase, bottomPadding: 32)

        case .arrived:
            ZStack {
                bottomStatusCard(phase: state.phase, bottomPadding: 32)
            }

        case .shakeYourPhone:
            ZStack {
                bottomStatusCard(phase: state.statusCardPhase, bottomPadding: 132)

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
                    bottomStatusCard(phase: state.statusCardPhase, bottomPadding: isQuizWidgetVisible ? 130 : 32)
                    mapUtilityControls(bottomPadding: isQuizWidgetVisible ? 265 : 165)
                }

                if isQuizWidgetVisible {
                    quizWidget
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func bottomStatusCard(phase: HypeRadarMapPhase, bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            HypeRadarBottomStatusCard(phase: phase, place: state.place)
                .padding(.horizontal, 20)
                .padding(.bottom, bottomPadding)
        }
    }

    private func mapUtilityControls(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                MapPointsBadge(points: selectedQuizOption == nil ? 0 : 30)

                Spacer()

                MapCameraButton(action: onOpenCamera)
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

    private func prepareWidgetState(for phase: HypeRadarMapPhase) {
        isQuizWidgetExpanded = false
        selectedQuizOption = nil

        let shouldShowQuizWidget = phase == .quiz

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
    HypeRadarMapView(phase: .goingToMeetingPoint)
}

#Preview("Arrived") {
    HypeRadarMapView(phase: .arrived)
}

#Preview("Shake Your Phone") {
    HypeRadarMapView(phase: .shakeYourPhone)
}
#Preview("Quiz") {
    HypeRadarMapView(phase: .quiz)
}
