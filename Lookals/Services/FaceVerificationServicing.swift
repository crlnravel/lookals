//
//  FaceVerificationServicing.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import Foundation

enum FaceVerificationPhase: Equatable {
    case preparingCamera
    case aligningFace
    case scanningFace
    case finalizing
    case verified

    var instruction: String {
        switch self {
        case .preparingCamera:
            "Preparing camera."
        case .aligningFace:
            "Center your face in the frame."
        case .scanningFace:
            "Please hold your face and wait.\nWe are verifying your face."
        case .finalizing:
            "Almost done.\nFinalizing verification."
        case .verified:
            "Face verified.\nYou can continue now."
        }
    }
}

struct FaceVerificationUpdate: Equatable {
    let phase: FaceVerificationPhase
    let progress: Double
}

protocol FaceVerificationServicing {
    func verificationUpdates() -> AsyncStream<FaceVerificationUpdate>
}
