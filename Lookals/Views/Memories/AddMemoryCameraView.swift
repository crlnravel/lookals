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
    @State private var isSavingCapture = false
    @State private var uploadErrorMessage: String?

    @MainActor
    init(albumID: UUID, viewModel: MemoriesViewModel) {
        self.albumID = albumID
        self.viewModel = viewModel
        _cameraManager = State(initialValue: CameraManager())
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if cameraManager.isCameraAvailable {
                    CameraPreviewView(session: cameraManager.session)
                        .onAppear {
                            cameraManager.startSession()
                        }
                        .onDisappear {
                            cameraManager.stopSession()
                        }
                } else {
                    MemoryImageView(
                        source: .asset("Memory Photo 1"),
                        viewModel: viewModel,
                        accessibilityLabel: "Sample camera preview"
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .layoutPriority(1)

            CameraCaptureControlsView(
                latestImage: cameraManager.latestImage,
                fallbackSource: latestMemorySource,
                viewModel: viewModel,
                galleryDestination: .memory(.album(albumID)),
                canFlipCamera: cameraManager.canSwitchCamera,
                isSavingCapture: isSavingCapture,
                capturePhoto: capturePhoto,
                flipCamera: cameraManager.flipCamera
            )
            .padding(.horizontal, 40)
            .padding(.top, 24)
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
            Task {
                await addLatestCaptureIfNeeded()
            }
        }
        .alert("Memory upload failed", isPresented: isShowingUploadError) {
            Button("OK", role: .cancel) {
                uploadErrorMessage = nil
            }
        } message: {
            Text(uploadErrorMessage ?? "")
        }
    }

    private var latestMemorySource: MemoryImageSource? {
        viewModel.album(for: albumID)?.photos.first?.source
    }

    private func capturePhoto() {
        guard !isSavingCapture else { return }
        cameraManager.capturePhoto()
    }

    private var isShowingUploadError: Binding<Bool> {
        Binding(
            get: { uploadErrorMessage != nil },
            set: { isShowing in
                if !isShowing {
                    uploadErrorMessage = nil
                }
            }
        )
    }

    private func addLatestCaptureIfNeeded() async {
        guard cameraManager.captureCount != lastAddedCaptureCount,
              let image = cameraManager.latestImage else {
            return
        }

        lastAddedCaptureCount = cameraManager.captureCount
        isSavingCapture = true
        defer {
            isSavingCapture = false
        }

        if await viewModel.addCapturedPhoto(image, to: albumID) != nil {
            dismiss()
        } else {
            uploadErrorMessage = viewModel.cloudErrorMessage
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
