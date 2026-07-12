//
//  CameraLatestThumbnailView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct CameraLatestThumbnailView: View {
    let image: UIImage?
    let fallbackSource: MemoryImageSource?
    let viewModel: MemoriesViewModel

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let fallbackSource {
                MemoryImageView(
                    source: fallbackSource,
                    viewModel: viewModel,
                    accessibilityLabel: "Latest memory"
                )
            } else {
                Color(.secondarySystemBackground)

                Image(systemName: "photo")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .clipped()
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityLabel(image == nil ? "Latest memory" : "Latest captured memory")
    }
}
