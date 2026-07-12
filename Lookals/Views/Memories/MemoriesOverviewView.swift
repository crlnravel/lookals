//
//  MemoriesOverviewView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoriesOverviewView: View {
    @State private var viewModel: MemoriesViewModel

    @MainActor
    init() {
        self.init(memoryPhotoService: LocalMemoryPhotoService.shared)
    }

    @MainActor
    init(memoryPhotoService: any MemoryPhotoServicing) {
        _viewModel = State(
            initialValue: MemoriesViewModel(memoryPhotoService: memoryPhotoService)
        )
    }

    @MainActor
    init(viewModel: MemoriesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.albums.isEmpty {
                ContentUnavailableView(
                    "No memories yet",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Captured quest photos will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.albums) { album in
                            NavigationLink(value: MemoriesRoute.album(album.id)) {
                                MemoryAlbumCard(album: album, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
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
                Text("Memories")
                    .font(.headline)
            }
        }
        .navigationDestination(for: MemoriesRoute.self) { route in
            MemoriesDestinationView(route: route, viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        MemoriesOverviewView()
    }
}
