//
//  CameraPhotoCaptureDelegate.swift
//  Lookals
//
//  Created by Codex on 10/07/26.
//

import AVFoundation
import Foundation

final class CameraPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data) -> Void
    private let finish: () -> Void

    init(
        completion: @escaping (Data) -> Void,
        finish: @escaping () -> Void
    ) {
        self.completion = completion
        self.finish = finish
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer { finish() }

        guard error == nil,
              let data = photo.fileDataRepresentation() else {
            return
        }

        completion(data)
    }
}
