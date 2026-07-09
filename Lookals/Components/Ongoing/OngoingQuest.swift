//
//  OngoingQuest.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

struct OngoingQuest: Identifiable, Equatable {
    let id: String
    let locationCode: String
    let questCode: String
    let kind: OngoingQuestKind
    let displayNumber: Int
    let title: String
    let reward: Int
    let steps: [OngoingQuestStep]

    var displayLabel: String {
        "\(kind.displayLabel) \(displayNumber)"
    }
}
