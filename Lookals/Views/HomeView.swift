//
//  HomeView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init() {
        _viewModel = State(initialValue: HomeViewModel())
    }

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let topMatch = viewModel.topMatch {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(topMatch.name)
                                .font(.title2.weight(.semibold))

                            Text("\(topMatch.resemblanceScore)% resemblance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ContentUnavailableView(
                            "No matches yet",
                            systemImage: "person.crop.circle.badge.questionmark",
                            description: Text("Start by loading sample matches.")
                        )
                    }
                } header: {
                    Text("Top Match")
                }

                Section("Matches") {
                    ForEach(viewModel.matches) { match in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle")
                                .imageScale(.large)
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.name)
                                    .font(.body.weight(.medium))

                                Text(match.category)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(match.resemblanceScore)%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Lookals")
            .overlay {
                if viewModel.state == .loading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadMatches()
            }
            .refreshable {
                await viewModel.loadMatches()
            }
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            matchingService: MockLookalMatchingService(),
            matches: [
                LookalMatch(name: "Alex", resemblanceScore: 92, category: "Style match"),
                LookalMatch(name: "Mika", resemblanceScore: 87, category: "Face shape")
            ],
            state: .loaded
        )
    )
}
