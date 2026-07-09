//
//  OngoingQuestCollapsedContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct OngoingQuestCollapsedContent: View {
    let quest: OngoingQuest
    let step: OngoingQuestStep

    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(quest.displayLabel)
                    .font(.subheadline.weight(.bold))

                Text(step.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 16)

            QuestRewardLabel(points: quest.reward)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quest.displayLabel), \(step.title), \(quest.reward) points")
    }
}

#Preview {
    OngoingQuestCollapsedContent(
        quest: OngoingQuestDemoData.quests[1],
        step: OngoingQuestDemoData.quests[1].steps[0]
    )
    .padding()
    .background(Color(.systemGray5))
}
