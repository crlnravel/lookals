//
//  ArtistIntroQuestContent.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import SwiftUI

struct ArtistIntroQuestContent: View {
    let quest: OngoingQuest
    let step: OngoingQuestStep
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

            Spacer(minLength: 160)

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                action: onNext
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .frame(minHeight: 620)
    }
}

#Preview {
    ArtistIntroQuestContent(
        quest: OngoingQuestDemoData.quests[1],
        step: OngoingQuestDemoData.quests[1].steps[0],
        onNext: {}
    )
    .frame(maxWidth: 360)
    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
}
