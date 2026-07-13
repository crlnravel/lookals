//
//  CameraAuthorizationStatus.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import AVFoundation

enum CameraAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .unavailable
        }
    }
}
