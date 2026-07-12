//
//  MemoryGridPhotoCard.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryGridPhotoCard: View {
    let photo: MemoryPhoto
    let viewModel: MemoriesViewModel

    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                MemoryImageView(
                    source: photo.source,
                    viewModel: viewModel,
                    accessibilityLabel: photo.accessibilityLabel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        .clipShape(.rect(cornerRadius: 18))
        .accessibilityHint("Opens photo")
    }
}
