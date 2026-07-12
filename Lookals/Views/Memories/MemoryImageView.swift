//
//  MemoryImageView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryImageView: View {
    let source: MemoryImageSource
    let viewModel: MemoriesViewModel
    let contentMode: ContentMode
    let accessibilityLabel: String

    init(
        source: MemoryImageSource,
        viewModel: MemoriesViewModel,
        contentMode: ContentMode = .fill,
        accessibilityLabel: String = "Memory photo"
    ) {
        self.source = source
        self.viewModel = viewModel
        self.contentMode = contentMode
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        ZStack {
            switch source {
            case .asset(let imageName):
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)

            case .captured(let imageID), .cloud(let imageID):
                if let image = viewModel.memoryImage(for: imageID) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    Color(.secondarySystemBackground)

                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
