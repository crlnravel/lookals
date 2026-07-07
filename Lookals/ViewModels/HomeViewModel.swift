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

    private let matchingService: LookalMatchingServicing

    private(set) var matches: [LookalMatch]
    private(set) var state: LoadingState

    var topMatch: LookalMatch? {
        matches.max { $0.resemblanceScore < $1.resemblanceScore }
    }

    init() {
        self.matchingService = MockLookalMatchingService()
        self.matches = []
        self.state = .idle
    }

    init(
        matchingService: LookalMatchingServicing,
        matches: [LookalMatch] = [],
        state: LoadingState = .idle
    ) {
        self.matchingService = matchingService
        self.matches = matches
        self.state = state
    }

    func loadMatches() async {
        guard state != .loading else { return }

        state = .loading

        do {
            matches = try await matchingService.fetchMatches()
            state = .loaded
        } catch {
            state = .failed("Unable to load matches.")
        }
    }
}
