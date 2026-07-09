//
//  OngoingQuestKind.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

enum OngoingQuestKind: Equatable {
    case quest
    case sideQuest

    var displayLabel: String {
        switch self {
        case .quest:
            "QUEST"
        case .sideQuest:
            "SIDE QUEST"
        }
    }
}
