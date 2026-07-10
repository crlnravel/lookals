//
//  TimedPhysicalChallengeQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct TimedPhysicalChallengeQuestContent: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let remainingSeconds: Int
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            Text(step.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 10)

                Text(timerText)
                    .font(.system(size: 44, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(remainingSeconds) seconds remaining")
            }
            .frame(width: 200, height: 200)
            .accessibilityElement(children: .combine)

            Spacer(minLength: 48)

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                isActive: remainingSeconds == 0,
                action: onSubmit
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .frame(minHeight: 620)
    }

    private var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        return "\(twoDigit(minutes)):\(twoDigit(seconds))"
    }

    private func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[4],
        step: BSDTourQuestDemoData.quests[4].steps[2]
    ) {
        TimedPhysicalChallengeQuestContent(
            quest: BSDTourQuestDemoData.quests[4],
            step: BSDTourQuestDemoData.quests[4].steps[2],
            remainingSeconds: 20,
            onSubmit: {}
        )
    }
}
