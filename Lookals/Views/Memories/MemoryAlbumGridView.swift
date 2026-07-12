//
//  MemoryAlbumGridView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryAlbumGridView: View {
    let albumID: UUID
    let viewModel: MemoriesViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if let album = viewModel.album(for: albumID) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(album.photos) { photo in
                            NavigationLink(value: MemoriesRoute.photo(photo.id)) {
                                MemoryGridPhotoCard(photo: photo, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            } else {
                ContentUnavailableView(
                    "Album not found",
                    systemImage: "photo.stack",
                    description: Text("This memory album is no longer available.")
                )
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden()
        .task(id: albumID) {
            await viewModel.loadCloudPhotos(for: albumID)
        }
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                MemoryToolbarBackButton()
            }

            ToolbarItem(placement: .principal) {
                Text(viewModel.album(for: albumID)?.title ?? "Memories")
                    .font(.headline)
            }
        }
    }
}

#Preview {
    let viewModel = MemoriesViewModel()

    NavigationStack {
        if let album = viewModel.albums.first {
            MemoryAlbumGridView(albumID: album.id, viewModel: viewModel)
        }
    }
}
