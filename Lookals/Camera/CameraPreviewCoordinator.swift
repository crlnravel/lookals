//
//  CameraPreviewCoordinator.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import UIKit

@MainActor
final class CameraPreviewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let manager: CameraManager

    init(manager: CameraManager) {
        self.manager = manager
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else { return }
        manager.receiveCapturedPhoto(image)
    }
}
