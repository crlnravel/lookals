//
//  ArtistIntroQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct ArtistIntroQuestContent: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            Text(step.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                action: onNext
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[1],
        step: BSDTourQuestDemoData.quests[1].steps[0]
    ) {
        ArtistIntroQuestContent(
            quest: BSDTourQuestDemoData.quests[1],
            step: BSDTourQuestDemoData.quests[1].steps[0],
            onNext: {}
        )
    }
}
