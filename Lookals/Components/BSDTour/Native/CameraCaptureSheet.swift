//
//  CameraCaptureSheet.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraCaptureSheet: View {
    let onPhotoData: (Data) -> Void
    let onCancel: () -> Void

    @State private var authorizationStatus = CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Take a Photo")
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
        switch effectiveAuthorizationStatus {
        case .authorized:
            CameraCaptureView(onPhotoData: onPhotoData, onCancel: onCancel)
                .ignoresSafeArea(edges: .bottom)

        case .notDetermined:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .denied, .restricted:
            ContentUnavailableView(
                "Camera Access Needed",
                systemImage: "camera.fill",
                description: Text("Allow camera access in Settings to take quest photos.")
            )

        case .unavailable:
            ContentUnavailableView(
                "Camera Unavailable",
                systemImage: "camera.slash",
                description: Text("This device cannot take quest photos right now.")
            )
        }
    }

    private var effectiveAuthorizationStatus: CameraAuthorizationStatus {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return .unavailable
        }

        return authorizationStatus
    }

    private func requestCameraAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }

        let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = isAuthorized ? .authorized : CameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }
}
