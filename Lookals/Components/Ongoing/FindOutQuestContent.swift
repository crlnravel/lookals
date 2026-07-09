//
//  FindOutQuestContent.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import SwiftUI

struct FindOutQuestContent: View {
    let quest: OngoingQuest
    let step: OngoingQuestStep
    @Binding var response: String
    let hasCapturedPhoto: Bool
    let onPhoto: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            QuestExpandedHeader(label: quest.displayLabel, title: step.title, reward: quest.reward)

            Text(step.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                TextField(step.inputMode?.placeholder ?? "", text: $response, axis: .vertical)
                    .font(.title3.weight(.medium))
                    .lineLimit(2...4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(minHeight: 64, alignment: .topLeading)
                    .keyboardType(step.inputMode == .currency ? .numberPad : .default)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(.systemGray), lineWidth: 1.5)
                    }

                if let footnote = step.footnote {
                    Text(footnote)
                        .font(.footnote.weight(.semibold))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 120)

            PrimaryButton(
                hasCapturedPhoto ? "Next" : step.primaryActionTitle,
                font: .headline.weight(.heavy),
                isActive: canContinue,
                action: hasCapturedPhoto ? onSubmit : onPhoto
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .frame(minHeight: 620)
    }

    private var canContinue: Bool {
        if step.inputMode == nil {
            return true
        }

        return !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var response = ""

        var body: some View {
            FindOutQuestContent(
                quest: OngoingQuestDemoData.quests[3],
                step: OngoingQuestDemoData.quests[3].steps[0],
                response: $response,
                hasCapturedPhoto: false,
                onPhoto: {},
                onSubmit: {}
            )
            .frame(maxWidth: 360)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
    }

    return PreviewHost()
}
