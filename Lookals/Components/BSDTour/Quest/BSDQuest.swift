//
//  BSDQuest.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

struct BSDQuest: Identifiable, Equatable {
    let id: String
    let locationCode: String
    let questCode: String
    let kind: BSDQuestKind
    let displayNumber: Int
    let title: String
    let reward: Int
    let steps: [BSDQuestStep]

    var displayLabel: String {
        "\(kind.displayLabel) \(displayNumber)"
    }
}
