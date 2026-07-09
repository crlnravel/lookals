//
//  CameraPreviewView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI
import UIKit

struct CameraPreviewView: UIViewControllerRepresentable {
    let manager: CameraManager

    func makeCoordinator() -> CameraPreviewCoordinator {
        CameraPreviewCoordinator(manager: manager)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = manager.cameraDevice
        picker.showsCameraControls = false
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        manager.attach(picker)
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {
        guard UIImagePickerController.isCameraDeviceAvailable(manager.cameraDevice) else { return }
        picker.cameraDevice = manager.cameraDevice
    }

    static func dismantleUIViewController(
        _ picker: UIImagePickerController,
        coordinator: CameraPreviewCoordinator
    ) {
        coordinator.manager.detach(picker)
    }
}
