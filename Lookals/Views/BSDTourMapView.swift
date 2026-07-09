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
    @State private var qrStep: BSDQuestStep?

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
            BSDTourCloudOverlay()
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
        .sheet(item: $qrStep) { step in
            QRCodeScannerSheet { payload in
                let isValid = flow.validateQRPayload(payload, for: step)
                qrStep = nil

                if isValid {
                    flow.advance()
                } else {
                    flow.isWidgetExpanded = true
                }
            } onCancel: {
                qrStep = nil
            }
        }
    }

    private var markers: [CustomMapMarker] {
        [
            CustomMapMarker(id: "booth", style: .place, xRatio: 0.42, yRatio: 0.52),
            CustomMapMarker(id: "avatar", style: .avatar, xRatio: 0.54, yRatio: 0.60),
            CustomMapMarker(id: "route", style: .mapBadge("L2"), xRatio: 0.32, yRatio: 0.40)
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
                    onPhotoRequested: presentCamera,
                    onQRScanRequested: presentQRScanner
                )
            }
        }
    }

    private var floatingProgressControls: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                HypeRadarPointsBadge(points: flow.earnedPoints)

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

    private func presentQRScanner(for step: BSDQuestStep) {
        qrStep = step
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

#Preview("BSD Tour Quest Demo Map - Complete") {
    BSDTourMapView(
        flow: BSDTourFlowModel(
            currentQuestIndex: BSDTourQuestDemoData.quests.count,
            currentStepIndex: 0,
            earnedPoints: 70,
            isWidgetExpanded: false
        )
    )
}
