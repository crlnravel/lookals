//
//  CameraManager.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Observation
import UIKit

@MainActor
@Observable
final class CameraManager {
    @ObservationIgnored private weak var picker: UIImagePickerController?

    private(set) var latestImage: UIImage?
    private(set) var captureCount = 0

    var cameraDevice: UIImagePickerController.CameraDevice = .rear {
        didSet {
            guard UIImagePickerController.isCameraDeviceAvailable(cameraDevice) else { return }
            picker?.cameraDevice = cameraDevice
        }
    }

    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var canSwitchCamera: Bool {
        UIImagePickerController.isCameraDeviceAvailable(.front)
            && UIImagePickerController.isCameraDeviceAvailable(.rear)
    }

    func attach(_ picker: UIImagePickerController) {
        self.picker = picker
        picker.cameraDevice = cameraDevice
    }

    func detach(_ picker: UIImagePickerController) {
        guard self.picker === picker else { return }
        self.picker = nil
    }

    func capturePhoto() {
        guard isCameraAvailable else {
            captureSamplePhoto()
            return
        }

        picker?.takePicture()
    }

    func flipCamera() {
        guard canSwitchCamera else { return }
        cameraDevice = cameraDevice == .rear ? .front : .rear
    }

    func receiveCapturedPhoto(_ image: UIImage) {
        latestImage = image
        captureCount += 1
    }

    private func captureSamplePhoto() {
        guard let image = UIImage(named: "Memory Photo 2") else { return }
        receiveCapturedPhoto(image)
    }
}
