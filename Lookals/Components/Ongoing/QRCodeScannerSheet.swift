//
//  QRCodeScannerSheet.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import AVFoundation
import SwiftUI

struct QRCodeScannerSheet: View {
    let onPayload: (String) -> Void
    let onCancel: () -> Void

    @State private var authorizationStatus = CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan QR Code")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel", action: onCancel)
                    }
                }
        }
        .task {
            await requestCameraAccessIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch authorizationStatus {
        case .authorized:
            QRCodeScannerView(onPayload: onPayload)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                        .accessibilityHidden(true)
                }

        case .notDetermined:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .denied, .restricted:
            ContentUnavailableView(
                "Camera Access Needed",
                systemImage: "camera.fill",
                description: Text("Allow camera access in Settings to scan the seller's QR code.")
            )

        case .unavailable:
            ContentUnavailableView(
                "Camera Unavailable",
                systemImage: "camera.slash",
                description: Text("This device cannot scan QR codes right now.")
            )
        }
    }

    private func requestCameraAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }

        let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = isAuthorized ? .authorized : CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }
}
