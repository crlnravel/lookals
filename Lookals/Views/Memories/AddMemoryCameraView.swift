//
//  AddMemoryCameraView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct AddMemoryCameraView: View {
    @Environment(\.dismiss) private var dismiss

    let albumID: UUID
    let viewModel: MemoriesViewModel

    @State private var cameraManager: CameraManager
    @State private var lastAddedCaptureCount = 0

    @MainActor
    init(albumID: UUID, viewModel: MemoriesViewModel) {
        self.albumID = albumID
        self.viewModel = viewModel
        _cameraManager = State(initialValue: CameraManager())
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                if cameraManager.isCameraAvailable {
                    CameraPreviewView(manager: cameraManager)
                } else {
                    MemoryImageView(
                        source: .asset("Memory Photo 1"),
                        viewModel: viewModel,
                        accessibilityLabel: "Sample camera preview"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }

                Button("Capture memory", systemImage: "camera.fill", action: capturePhoto)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .labelStyle(.iconOnly)
                    .frame(width: 64, height: 64)
                    .background(Color.accentColor, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                    .offset(y: 32)
                    .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .layoutPriority(1)

            CameraCaptureControlsView(
                latestImage: cameraManager.latestImage,
                fallbackSource: latestMemorySource,
                viewModel: viewModel,
                canFlipCamera: cameraManager.canSwitchCamera,
                flipCamera: cameraManager.flipCamera
            )
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 24)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden()
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                MemoryToolbarBackButton()
            }

            ToolbarItem(placement: .principal) {
                Text("Add Memories")
                    .font(.headline)
            }
        }
        .onChange(of: cameraManager.captureCount) {
            addLatestCaptureIfNeeded()
        }
    }

    private var latestMemorySource: MemoryImageSource? {
        viewModel.album(for: albumID)?.photos.first?.source
    }

    private func capturePhoto() {
        cameraManager.capturePhoto()
    }

    private func addLatestCaptureIfNeeded() {
        guard cameraManager.captureCount != lastAddedCaptureCount,
              let image = cameraManager.latestImage else {
            return
        }

        lastAddedCaptureCount = cameraManager.captureCount

        if viewModel.addCapturedPhoto(image, to: albumID) != nil {
            dismiss()
        }
    }
}

#Preview {
    let viewModel = MemoriesViewModel()

    NavigationStack {
        if let album = viewModel.albums.first {
            AddMemoryCameraView(albumID: album.id, viewModel: viewModel)
        }
    }
}
