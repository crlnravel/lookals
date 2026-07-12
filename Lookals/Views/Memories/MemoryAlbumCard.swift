//
//  MemoryAlbumCard.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryAlbumCard: View {
    let album: MemoryAlbum
    let viewModel: MemoriesViewModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MemoryImageView(
                source: album.coverSource,
                viewModel: viewModel,
                accessibilityLabel: "\(album.title) album cover"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            Text(album.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(24)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 28))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(album.title)
        .accessibilityHint("Opens memory album")
    }
}
