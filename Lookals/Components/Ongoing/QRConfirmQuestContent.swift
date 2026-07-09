//
//  QRConfirmQuestContent.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import SwiftUI

struct QRConfirmQuestContent: View {
    let quest: OngoingQuest
    let step: OngoingQuestStep
    let validationMessage: String?
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            Text(step.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemGray4))
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .overlay {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(Color(.systemGray))
                        .accessibilityHidden(true)
                }
                .accessibilityLabel("QR scanner preview")

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                step.primaryActionTitle,
                font: .headline.weight(.heavy),
                action: onScan
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
}

#Preview {
    QRConfirmQuestContent(
        quest: OngoingQuestDemoData.quests[2],
        step: OngoingQuestDemoData.quests[2].steps[2],
        validationMessage: "That QR code does not match this quest. Try again.",
        onScan: {}
    )
    .frame(maxWidth: 360)
    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
}
