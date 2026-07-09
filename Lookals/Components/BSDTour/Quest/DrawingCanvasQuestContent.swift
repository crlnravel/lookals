//
//  DrawingCanvasQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct DrawingCanvasQuestContent<Canvas: View>: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let remainingSeconds: Int
    let canvas: Canvas
    let onSubmit: () -> Void

    init(
        quest: BSDQuest,
        step: BSDQuestStep,
        remainingSeconds: Int,
        @ViewBuilder canvas: () -> Canvas,
        onSubmit: @escaping () -> Void
    ) {
        self.quest = quest
        self.step = step
        self.remainingSeconds = remainingSeconds
        self.canvas = canvas()
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: 20) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            VStack(spacing: 8) {
                Text(step.prompt)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text("\(remainingSeconds)s")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("\(remainingSeconds) seconds remaining")
            }

            canvas
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary, lineWidth: 1.5)
                }

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                action: onSubmit
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
}

struct DrawingCanvasPlaceholder: View {
    var body: some View {
        Color.clear
            .accessibilityLabel("Drawing canvas")
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[1],
        step: BSDTourQuestDemoData.quests[1].steps[1]
    ) {
        DrawingCanvasQuestContent(
            quest: BSDTourQuestDemoData.quests[1],
            step: BSDTourQuestDemoData.quests[1].steps[1],
            remainingSeconds: 20
        ) {
            DrawingCanvasPlaceholder()
        } onSubmit: {}
    }
}
