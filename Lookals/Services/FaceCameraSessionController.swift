//
//  FaceCameraSessionController.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import AVFoundation
import Foundation

enum FaceCameraAuthorizationState: Equatable {
    case authorized
    case denied
    case restricted
    case unavailable
}

final class FaceCameraSessionController {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.lookals.face-camera-session")
    private var isConfigured = false

    func start() async -> FaceCameraAuthorizationState {
        let authorizationState = await requestAuthorization()
        guard authorizationState == .authorized else { return authorizationState }

        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: .unavailable)
                    return
                }

                guard self.configureSessionIfNeeded() else {
                    continuation.resume(returning: .unavailable)
                    return
                }

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                continuation.resume(returning: .authorized)
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func requestAuthorization() async -> FaceCameraAuthorizationState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
    }

    private func configureSessionIfNeeded() -> Bool {
        guard !isConfigured else { return true }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            return false
        }

        session.addInput(input)
        isConfigured = true
        return true
    }
}
