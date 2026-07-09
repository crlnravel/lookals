//
//  LookAroundQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct LookAroundQuestContent: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            VStack(spacing: 4) {
                Text(step.prompt)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(.primary)

                if let footnote = step.footnote {
                    Text(footnote)
                        .font(.footnote.weight(.semibold))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }

            if let imageName = step.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.82, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
                    .accessibilityLabel(step.prompt)
            }

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                action: onNext
            )
            .padding(.top, 24)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[0],
        step: BSDTourQuestDemoData.quests[0].steps[0]
    ) {
        LookAroundQuestContent(
            quest: BSDTourQuestDemoData.quests[0],
            step: BSDTourQuestDemoData.quests[0].steps[0],
            onNext: {}
        )
    }
}
