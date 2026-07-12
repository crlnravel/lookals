//
//  CameraManager.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import Observation
import AVFoundation
import UIKit

@MainActor
@Observable
final class CameraManager {
    @ObservationIgnored private let cameraSession = CameraSessionController()

    private(set) var latestImage: UIImage?
    private(set) var captureCount = 0

    var session: AVCaptureSession {
        cameraSession.session
    }

    var isCameraAvailable: Bool {
        cameraSession.isCameraAvailable
    }

    var canSwitchCamera: Bool {
        cameraSession.canSwitchCamera
    }

    func startSession() {
        cameraSession.start()
    }

    func stopSession() {
        cameraSession.stop()
    }

    func capturePhoto() {
        guard isCameraAvailable else {
            captureSamplePhoto()
            return
        }

        cameraSession.capturePhoto { [weak self] data in
            Task { @MainActor in
                guard let image = UIImage(data: data) else { return }
                self?.receiveCapturedPhoto(image)
            }
        }
    }

    func flipCamera() {
        guard canSwitchCamera else { return }
        cameraSession.flipCamera()
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
