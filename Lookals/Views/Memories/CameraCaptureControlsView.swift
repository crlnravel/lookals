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
    let canFlipCamera: Bool
    let flipCamera: () -> Void

    var body: some View {
        HStack {
            CameraLatestThumbnailView(
                image: latestImage,
                fallbackSource: fallbackSource,
                viewModel: viewModel
            )

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
        .frame(minHeight: 64)
    }
}
