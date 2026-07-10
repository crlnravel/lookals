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
        VStack(spacing: 32) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)
                .padding(.bottom, -24)

            VStack(spacing: 2) {
                Text(step.prompt)
                    .font(.default.weight(.semibold))
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
                    .scaleEffect(1.08) // adjust until transparent edges disappear
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(cornerRadius: 50, style: .continuous)
                    )
                    .shadow(
                        color: .black.opacity(0.4),
                        radius: 50,
                        x: 0,
                        y: 8
                    )
            }

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
