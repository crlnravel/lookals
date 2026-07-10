//
//  FaceCameraSessionController.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import AVFoundation
import CoreImage
import Foundation
import UIKit
import Vision

enum FaceCameraAuthorizationState: Equatable {
    case authorized
    case denied
    case restricted
    case unavailable
}

struct FaceDetectionUpdate {
    let isFaceDetected: Bool
    let capturedImage: UIImage?
}

final class FaceCameraSessionController: NSObject {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.lookals.face-camera-session")
    private let videoOutputQueue = DispatchQueue(label: "com.lookals.face-camera-video-output")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()

    private var isConfigured = false
    private var detectionContinuation: AsyncStream<FaceDetectionUpdate>.Continuation?
    private var didCaptureFaceImage = false
    private var lastDetectionDate = Date.distantPast

    func faceDetectionUpdates() -> AsyncStream<FaceDetectionUpdate> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            videoOutputQueue.async { [weak self] in
                self?.detectionContinuation = continuation
                self?.didCaptureFaceImage = false
            }

            continuation.onTermination = { [weak self] _ in
                self?.videoOutputQueue.async {
                    self?.detectionContinuation = nil
                }
            }
        }
    }

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

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

        guard session.canAddOutput(videoOutput) else {
            return false
        }

        session.addOutput(videoOutput)

        isConfigured = true
        return true
    }
}

extension FaceCameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard detectionContinuation != nil else { return }

        let now = Date()
        guard now.timeIntervalSince(lastDetectionDate) >= 0.2 else { return }
        lastDetectionDate = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {
            try handler.perform([request])
            let hasFace = !(request.results ?? []).isEmpty
            detectionContinuation?.yield(
                FaceDetectionUpdate(
                    isFaceDetected: hasFace,
                    capturedImage: capturedImage(from: pixelBuffer, when: hasFace)
                )
            )
        } catch {
            detectionContinuation?.yield(FaceDetectionUpdate(isFaceDetected: false, capturedImage: nil))
        }
    }

    private func capturedImage(from pixelBuffer: CVPixelBuffer, when hasFace: Bool) -> UIImage? {
        guard hasFace, !didCaptureFaceImage else { return nil }

        let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else { return nil }

        didCaptureFaceImage = true
        return UIImage(cgImage: cgImage)
    }
}
