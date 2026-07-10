//
//  BSDTourMapView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreLocation
import MapKit
import SwiftUI

struct BSDTourMapView: View {
    let onBack: () -> Void
    let onLocate: () -> Void

    @State private var flow: BSDTourFlowModel
    @State private var cameraStep: BSDQuestStep?

    private let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.3016, longitude: 106.6519),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    init(
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {}
    ) {
        self._flow = State(initialValue: BSDTourFlowModel())
        self.onBack = onBack
        self.onLocate = onLocate
    }

    init(
        flow: BSDTourFlowModel,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {}
    ) {
        self._flow = State(initialValue: flow)
        self.onBack = onBack
        self.onLocate = onLocate
    }

    var body: some View {
        CustomMapView(
            title: "BSD Quest Map",
            region: region,
            markers: markers,
            onBack: onBack,
            onLocate: onLocate
        ) {
            MapCloudOverlay()
        } bottomOverlay: {
            bottomOverlay
        }
        .sheet(item: $cameraStep) { step in
            CameraCaptureSheet { photoData in
                flow.updateCapturedPhotoData(photoData, for: step)
                cameraStep = nil
                flow.advance()
            } onCancel: {
                cameraStep = nil
            }
        }
    }

    private var markers: [CustomMapMarker] {
        [
            CustomMapMarker(id: "booth", style: .place, xRatio: 0.42, yRatio: 0.52),
            CustomMapMarker(id: "avatar", style: .avatar, xRatio: 0.54, yRatio: 0.60),
            CustomMapMarker(id: "l1", style: .mapBadge("L1"), xRatio: 0.24, yRatio: 0.34),
            CustomMapMarker(id: "l2", style: .mapBadge("L2"), xRatio: 0.32, yRatio: 0.40),
            CustomMapMarker(id: "l3", style: .mapBadge("L3"), xRatio: 0.44, yRatio: 0.45),
            CustomMapMarker(id: "l4", style: .mapBadge("L4"), xRatio: 0.58, yRatio: 0.48),
            CustomMapMarker(id: "l5", style: .mapBadge("L5"), xRatio: 0.68, yRatio: 0.57),
            CustomMapMarker(id: "l6", style: .mapBadge("L6"), xRatio: 0.58, yRatio: 0.72),
            CustomMapMarker(id: "l7", style: .mapBadge("L7"), xRatio: 0.42, yRatio: 0.76),
            CustomMapMarker(id: "l8", style: .mapBadge("L8"), xRatio: 0.28, yRatio: 0.64)
        ]
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        ZStack {
            if !flow.isWidgetExpanded {
                floatingProgressControls
            }

            if flow.isComplete {
                completionCard
            } else {
                BSDTourQuestWidget(
                    flow: flow,
                    onPhotoRequested: presentCamera
                )
            }
        }
    }

    private var floatingProgressControls: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                MapPointsBadge(points: flow.earnedPoints)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 152)
        }
    }

    private var completionCard: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                QuestRewardLabel(points: flow.earnedPoints)

                VStack(spacing: 4) {
                    Text("Quests Complete")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.primary)

                    Text("You finished the demo route.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                PrimaryButton(
                    "Restart",
                    font: .headline.weight(.heavy),
                    action: flow.restart
                )
            }
            .frame(maxWidth: 392)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func presentCamera(for step: BSDQuestStep) {
        cameraStep = step
    }

}

#Preview("BSD Tour Quest Demo Map") {
    BSDTourMapView()
}

#Preview("BSD Tour Quest Demo Map - Drawing") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: 1,
            currentStepIndex: 1,
            earnedPoints: 30,
            isWidgetExpanded: true
        )
    )
}

#Preview("BSD Tour Quest Demo Map - Q3 Timer") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: 4,
            currentStepIndex: 2,
            earnedPoints: 70,
            isWidgetExpanded: true
        )
    )
}

#Preview("BSD Tour Quest Demo Map - Q6 Clue") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: 7,
            currentStepIndex: 1,
            earnedPoints: 160,
            isWidgetExpanded: true
        )
    )
}

#Preview("BSD Tour Quest Demo Map - Q6 Final Clue") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: 7,
            currentStepIndex: 3,
            earnedPoints: 160,
            isWidgetExpanded: true
        )
    )
}

#Preview("BSD Tour Quest Demo Map - Complete") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: BSDTourQuestDemoData.quests.count,
            currentStepIndex: 0,
            earnedPoints: BSDTourQuestDemoData.quests.reduce(0) { $0 + $1.reward },
            isWidgetExpanded: false
        )
    )
}
