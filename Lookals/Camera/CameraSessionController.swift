//
//  CameraSessionController.swift
//  Lookals
//
//  Created by Codex on 10/07/26.
//

import AVFoundation
import Foundation

final class CameraSessionController {
    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "Lookals.Camera.Session")
    private var currentInput: AVCaptureDeviceInput?
    private var photoCaptureDelegate: CameraPhotoCaptureDelegate?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var isConfigured = false

    var isCameraAvailable: Bool {
        Self.device(for: .back) != nil || Self.device(for: .front) != nil
    }

    var canSwitchCamera: Bool {
        Self.device(for: .back) != nil && Self.device(for: .front) != nil
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.configureIfNeeded(position: self.currentPosition) else { return }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (Data) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.configureIfNeeded(position: self.currentPosition) else { return }

            let settings = AVCapturePhotoSettings()
            let delegate = CameraPhotoCaptureDelegate(
                completion: completion,
                finish: { [weak self] in
                    self?.sessionQueue.async {
                        self?.photoCaptureDelegate = nil
                    }
                }
            )

            self.photoCaptureDelegate = delegate

            Task { @MainActor [photoOutput = self.photoOutput] in
                photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    func flipCamera() {
        guard canSwitchCamera else { return }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            let nextPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
            guard self.configureSession(position: nextPosition) else { return }
            self.currentPosition = nextPosition
        }
    }

    private func configureIfNeeded(position: AVCaptureDevice.Position) -> Bool {
        guard !isConfigured else { return true }
        return configureSession(position: position)
    }

    private func configureSession(position: AVCaptureDevice.Position) -> Bool {
        guard let device = Self.device(for: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return false
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        if let currentInput {
            session.removeInput(currentInput)
        }

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return false
        }

        session.addInput(input)
        currentInput = input

        if !session.outputs.contains(photoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
        isConfigured = true
        return true
    }

    private static func device(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}
