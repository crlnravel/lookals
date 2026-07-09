//
//  CameraCaptureView.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    let onPhotoData: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhotoData: onPhotoData, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPhotoData: (Data) -> Void
        let onCancel: () -> Void

        init(onPhotoData: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onPhotoData = onPhotoData
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard
                let image = info[.originalImage] as? UIImage,
                let data = image.jpegData(compressionQuality: 0.82)
            else {
                onCancel()
                return
            }

            onPhotoData(data)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
