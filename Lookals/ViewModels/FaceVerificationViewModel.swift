//
//  FaceVerificationViewModel.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class FaceVerificationViewModel {
    enum State: Equatable {
        case idle
        case requestingCamera
        case verifying(FaceVerificationPhase)
        case complete
        case cameraUnavailable(String)
    }

    private let cameraController: FaceCameraSessionController
    private let verificationService: any FaceVerificationServicing

    @ObservationIgnored private var verificationTask: Task<Void, Never>?

    private(set) var state: State = .idle
    private(set) var progress: Double = 0

    var captureSession: AVCaptureSession {
        cameraController.session
    }

    var instruction: String {
        switch state {
        case .idle, .requestingCamera:
            FaceVerificationPhase.preparingCamera.instruction
        case .verifying(let phase):
            phase.instruction
        case .complete:
            FaceVerificationPhase.verified.instruction
        case .cameraUnavailable(let message):
            message
        }
    }

    var isComplete: Bool {
        state == .complete
    }

    var shouldShowCameraPreview: Bool {
        switch state {
        case .verifying, .complete:
            true
        case .idle, .requestingCamera, .cameraUnavailable:
            false
        }
    }

    init(
        cameraController: FaceCameraSessionController? = nil,
        verificationService: (any FaceVerificationServicing)? = nil
    ) {
        self.cameraController = cameraController ?? FaceCameraSessionController()
        self.verificationService = verificationService ?? MockFaceVerificationService()
    }

    static func preview(
        state: State = .verifying(.scanningFace),
        progress: Double = 0.85
    ) -> FaceVerificationViewModel {
        let viewModel = FaceVerificationViewModel()
        viewModel.state = state
        viewModel.progress = min(max(progress, 0), 1)
        return viewModel
    }

    deinit {
        verificationTask?.cancel()
    }

    func start() {
        guard verificationTask == nil else { return }

        verificationTask = Task { [weak self] in
            await self?.runVerification()
        }
    }

    func cancel() {
        verificationTask?.cancel()
        verificationTask = nil
        cameraController.stop()
    }

    private func runVerification() async {
        state = .requestingCamera
        progress = 0

        let cameraState = await cameraController.start()
        guard cameraState == .authorized else {
            state = .cameraUnavailable(message(for: cameraState))
            return
        }

        for await update in verificationService.verificationUpdates() {
            guard !Task.isCancelled else { return }
            progress = min(max(update.progress, 0), 1)

            if update.phase == .verified || progress >= 1 {
                state = .complete
            } else {
                state = .verifying(update.phase)
            }
        }
    }

    private func message(for cameraState: FaceCameraAuthorizationState) -> String {
        switch cameraState {
        case .authorized:
            FaceVerificationPhase.preparingCamera.instruction
        case .denied:
            "Camera access is off.\nEnable it in Settings to verify your face."
        case .restricted:
            "Camera access is restricted on this device."
        case .unavailable:
            "Camera is unavailable.\nPlease try again later."
        }
    }
}
