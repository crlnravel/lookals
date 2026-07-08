//
//  MockFaceVerificationService.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

struct MockFaceVerificationService: FaceVerificationServicing {
    private let updates: [FaceVerificationUpdate]
    private let delay: Duration

    init(
        updates: [FaceVerificationUpdate] = MockFaceVerificationService.defaultUpdates,
        delay: Duration = .milliseconds(700)
    ) {
        self.updates = updates
        self.delay = delay
    }

    func verificationUpdates() -> AsyncStream<FaceVerificationUpdate> {
        AsyncStream { continuation in
            let task = Task {
                for update in updates {
                    guard !Task.isCancelled else { break }
                    continuation.yield(update)

                    do {
                        try await Task.sleep(for: delay)
                    } catch {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private extension MockFaceVerificationService {
    static let defaultUpdates = [
        FaceVerificationUpdate(phase: .preparingCamera, progress: 0.05),
        FaceVerificationUpdate(phase: .aligningFace, progress: 0.25),
        FaceVerificationUpdate(phase: .scanningFace, progress: 0.55),
        FaceVerificationUpdate(phase: .scanningFace, progress: 0.85),
        FaceVerificationUpdate(phase: .finalizing, progress: 0.95),
        FaceVerificationUpdate(phase: .verified, progress: 1)
    ]
}
