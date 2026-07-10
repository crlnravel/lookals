//
//  QRConfirmQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct QRConfirmQuestContent: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let validationMessage: String?
    let onPayload: (String) -> Bool

    @State private var authorizationStatus = CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
    @State private var scannerSessionID = UUID()
    @State private var isPausedAfterInvalidScan = false

    var body: some View {
        VStack(spacing: 28) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            Text(step.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)

            scannerPanel

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if isPausedAfterInvalidScan {
                PrimaryButton(
                    "Try Again",
                    font: .headline.weight(.heavy),
                    action: retryScanning
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .task {
            await requestCameraAccessIfNeeded()
        }
    }

    private var scannerPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemGray4))

            scannerPanelContent
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityLabel("QR scanner preview")
    }

    @ViewBuilder
    private var scannerPanelContent: some View {
        switch effectiveAuthorizationStatus {
        case .authorized:
            if isPausedAfterInvalidScan {
                scannerPausedContent
            } else {
                QRCodeScannerView(
                    onPayload: handlePayload,
                    onUnavailable: {
                        authorizationStatus = .unavailable
                    }
                )
                .id(scannerSessionID)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 220, height: 220)
                        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                        .accessibilityHidden(true)
                }
            }

        case .notDetermined:
            ProgressView()
                .controlSize(.large)

        case .denied, .restricted:
            ContentUnavailableView(
                "Camera Access Needed",
                systemImage: "camera.fill",
                description: Text("Allow camera access in Settings to scan this quest QR code.")
            )
            .padding(16)

        case .unavailable:
            ContentUnavailableView(
                "Camera Unavailable",
                systemImage: "camera.slash",
                description: Text("This device cannot scan QR codes right now.")
            )
            .padding(16)
        }
    }

    private var scannerPausedContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Color(.systemGray))
                .accessibilityHidden(true)

            Text("Ready to retry")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.secondary)
        }
    }

    private var effectiveAuthorizationStatus: CameraAuthorizationStatus {
        guard
            UIImagePickerController.isSourceTypeAvailable(.camera),
            AVCaptureDevice.default(for: .video) != nil
        else {
            return .unavailable
        }

        return authorizationStatus
    }

    private func requestCameraAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }

        let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = isAuthorized ? .authorized : CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }

    private func handlePayload(_ payload: String) {
        let isValid = onPayload(payload)

        if !isValid {
            isPausedAfterInvalidScan = true
        }
    }

    private func retryScanning() {
        scannerSessionID = UUID()
        isPausedAfterInvalidScan = false
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[2],
        step: BSDTourQuestDemoData.quests[2].steps[2]
    ) {
        QRConfirmQuestContent(
            quest: BSDTourQuestDemoData.quests[2],
            step: BSDTourQuestDemoData.quests[2].steps[2],
            validationMessage: "That QR code does not match this quest. Try again.",
            onPayload: { _ in false }
        )
    }
}
