//
//  MemoriesDestinationView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoriesDestinationView: View {
    let route: MemoriesRoute
    let viewModel: MemoriesViewModel

    var body: some View {
        switch route {
        case .album(let albumID):
            MemoryAlbumGridView(albumID: albumID, viewModel: viewModel)

        case .photo(let photoID):
            MemoryPhotoDetailView(photoID: photoID, viewModel: viewModel)

        case .addMemory(let albumID):
            AddMemoryCameraView(albumID: albumID, viewModel: viewModel)
        }
    }
}
