//
//  HomeViewModel.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let repository: any LookalMatchRepository

    private(set) var matches: [LookalMatch]
    private(set) var state: LoadingState

    var topMatch: LookalMatch? {
        matches.max { $0.resemblanceScore < $1.resemblanceScore }
    }

    init() {
        self.repository = AppDependencies.preview.lookalMatchRepository
        self.matches = []
        self.state = .idle
    }

    init(
        repository: any LookalMatchRepository,
        matches: [LookalMatch] = [],
        state: LoadingState = .idle
    ) {
        self.repository = repository
        self.matches = matches
        self.state = state
    }

    func loadMatches(refresh: Bool = false) async {
        guard state != .loading else { return }

        state = .loading

        do {
            matches = try await repository.fetchMatches(refresh: refresh)
            state = .loaded
        } catch {
            state = .failed("Unable to load matches.")
        }
    }
}
