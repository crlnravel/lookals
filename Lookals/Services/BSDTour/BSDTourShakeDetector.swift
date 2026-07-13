//
//  BSDTourShakeDetector.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import CoreMotion
import Foundation
import Observation

@MainActor
@Observable
final class BSDTourShakeDetector {
    private let motionManager = CMMotionManager()
    private var lastShakeDate = Date.distantPast

    var onShake: (() -> Void)?

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        guard !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = 0.12
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.handleAcceleration(data.acceleration)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func simulateShake() {
        onShake?()
    }

    private func handleAcceleration(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )

        guard magnitude > 2.4 else { return }
        guard Date().timeIntervalSince(lastShakeDate) > 1.2 else { return }

        lastShakeDate = Date()
        onShake?()
    }
}
