//
//  CameraCaptureControlsView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct CameraCaptureControlsView: View {
    let latestImage: UIImage?
    let fallbackSource: MemoryImageSource?
    let viewModel: MemoriesViewModel
    let galleryDestination: MemoriesRoute
    let canFlipCamera: Bool
    let isSavingCapture: Bool
    let capturePhoto: () -> Void
    let flipCamera: () -> Void

    var body: some View {
        ZStack {
            HStack {
                NavigationLink(value: galleryDestination) {
                    CameraLatestThumbnailView(
                        image: latestImage,
                        fallbackSource: fallbackSource,
                        viewModel: viewModel
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Flip camera", systemImage: "arrow.triangle.2.circlepath", action: flipCamera)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .labelStyle(.iconOnly)
                    .frame(width: 56, height: 56)
                    .background(.regularMaterial, in: Circle())
                    .disabled(!canFlipCamera)
                    .opacity(canFlipCamera ? 1 : 0.55)
            }

            Button("Capture memory", systemImage: "camera.fill", action: capturePhoto)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .labelStyle(.iconOnly)
                .frame(width: 64, height: 64)
                .background(Color.accentColor, in: Circle())
                .overlay {
                    if isSavingCapture {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                }
                .disabled(isSavingCapture)
        }
        .frame(minHeight: 64)
    }
}
