//
//  QRCodeScannerView.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import AVFoundation
import SwiftUI

struct QRCodeScannerView: UIViewRepresentable {
    let onPayload: (String) -> Void

    func makeUIView(context: Context) -> QRCodeScannerPreviewView {
        let previewView = QRCodeScannerPreviewView()
        context.coordinator.configure(previewView: previewView)
        return previewView
    }

    func updateUIView(_ previewView: QRCodeScannerPreviewView, context: Context) {
        context.coordinator.updatePreviewFrame()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    static func dismantleUIView(_ uiView: QRCodeScannerPreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let onPayload: (String) -> Void
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "lookals.qr-scanner.session")
        private weak var previewView: QRCodeScannerPreviewView?
        private var didScanPayload = false

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func configure(previewView: QRCodeScannerPreviewView) {
            self.previewView = previewView
            previewView.videoPreviewLayer.session = session
            previewView.videoPreviewLayer.videoGravity = .resizeAspectFill

            sessionQueue.async { [weak self] in
                self?.configureSession()
            }
        }

        func updatePreviewFrame() {
            DispatchQueue.main.async { [weak self] in
                self?.previewView?.videoPreviewLayer.frame = self?.previewView?.bounds ?? .zero
            }
        }

        func stop() {
            sessionQueue.async { [session] in
                if session.isRunning {
                    session.stopRunning()
                }
            }
        }

        private func configureSession() {
            guard session.inputs.isEmpty else {
                startSession()
                return
            }

            guard
                let captureDevice = AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: captureDevice),
                session.canAddInput(input)
            else {
                return
            }

            session.beginConfiguration()
            session.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            session.commitConfiguration()
            startSession()
        }

        private func startSession() {
            guard !session.isRunning else { return }
            session.startRunning()
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                !didScanPayload,
                let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let payload = readableObject.stringValue
            else {
                return
            }

            didScanPayload = true
            stop()
            onPayload(payload)
        }
    }
}

final class QRCodeScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
