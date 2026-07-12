//
//  MemoryThumbnailStrip.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryThumbnailStrip: View {
    let album: MemoryAlbum
    let viewModel: MemoriesViewModel

    @Binding var selectedPhotoID: UUID

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(album.photos) { photo in
                        Button {
                            selectedPhotoID = photo.id
                        } label: {
                            Color(.secondarySystemBackground)
                                .frame(width: 88, height: 64)
                                .overlay {
                                    MemoryImageView(
                                        source: photo.source,
                                        viewModel: viewModel,
                                        accessibilityLabel: photo.accessibilityLabel
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                }
                                .clipShape(.rect(cornerRadius: 10))
                                .overlay {
                                    if selectedPhotoID == photo.id {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.accentColor, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .id(photo.id)
                        .accessibilityLabel("Show memory photo")
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selectedPhotoID) {
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo(selectedPhotoID, anchor: .center)
                }
            }
        }
    }
}
