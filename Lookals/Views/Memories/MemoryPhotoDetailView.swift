//
//  MemoryPhotoDetailView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryPhotoDetailView: View {
    let photoID: UUID
    let viewModel: MemoriesViewModel

    @State private var selectedPhotoID: UUID

    init(photoID: UUID, viewModel: MemoriesViewModel) {
        self.photoID = photoID
        self.viewModel = viewModel
        _selectedPhotoID = State(initialValue: photoID)
    }

    var body: some View {
        Group {
            if let selectedPhoto = viewModel.photo(for: selectedPhotoID),
               let album = viewModel.album(containing: selectedPhoto.id) {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    TabView(selection: $selectedPhotoID) {
                        ForEach(album.photos) { photo in
                            Color(.systemBackground)
                                .overlay {
                                    MemoryImageView(
                                        source: photo.source,
                                        viewModel: viewModel,
                                        contentMode: .fit,
                                        accessibilityLabel: photo.accessibilityLabel
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                }
                                .tag(photo.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(
                        "Memory photo \(selectedIndex(in: album) + 1) of \(album.photos.count)"
                    )

                    Spacer(minLength: 24)

                    MemoryThumbnailStrip(
                        album: album,
                        viewModel: viewModel,
                        selectedPhotoID: $selectedPhotoID
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            } else {
                ContentUnavailableView(
                    "Photo not found",
                    systemImage: "photo",
                    description: Text("This memory photo is no longer available.")
                )
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden()
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                MemoryToolbarBackButton()
            }

            ToolbarItem(placement: .principal) {
                MemoryPhotoTitleView(photo: viewModel.photo(for: selectedPhotoID))
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Label("Share memory", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(CircleToolbarButtonStyle())
            }
        }
    }

    private var shareText: String {
        guard let photo = viewModel.photo(for: selectedPhotoID) else {
            return "Lookals memory"
        }

        return "\(photo.title) at \(photo.time)"
    }

    private func selectedIndex(in album: MemoryAlbum) -> Int {
        album.photos.firstIndex { $0.id == selectedPhotoID } ?? 0
    }
}
