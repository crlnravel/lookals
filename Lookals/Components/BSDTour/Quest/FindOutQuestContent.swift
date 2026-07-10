//
//  FindOutQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct FindOutQuestContent: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    @Binding var response: String
    let hasCapturedPhoto: Bool
    let requiresPhoto: Bool
    let onPhoto: () -> Void
    let onSubmit: () -> Void

    @FocusState private var isResponseFocused: Bool

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
                    .focused($isResponseFocused)
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

            PrimaryButton(
                buttonTitle,
                font: .headline.weight(.heavy),
                isActive: canContinue,
                action: buttonAction
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isResponseFocused = false
                }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isResponseFocused = false
                }
            }
        }
    }

    private var canContinue: Bool {
        if step.inputMode == nil {
            return true
        }

        return !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var buttonTitle: String {
        requiresPhoto && hasCapturedPhoto ? "Next" : step.primaryActionTitle
    }

    private func buttonAction() {
        if requiresPhoto && !hasCapturedPhoto {
            onPhoto()
        } else {
            onSubmit()
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var response = ""

        var body: some View {
            BSDQuestContentPreviewContainer(
                quest: BSDTourQuestDemoData.quests[3],
                step: BSDTourQuestDemoData.quests[3].steps[0]
            ) {
                FindOutQuestContent(
                    quest: BSDTourQuestDemoData.quests[3],
                    step: BSDTourQuestDemoData.quests[3].steps[0],
                    response: $response,
                    hasCapturedPhoto: false,
                    requiresPhoto: true,
                    onPhoto: {},
                    onSubmit: {}
                )
            }
        }
    }

    return PreviewHost()
}
