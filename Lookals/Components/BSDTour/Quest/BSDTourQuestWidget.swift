//
//  BSDTourQuestWidget.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourQuestWidget: View {
    @Bindable var flow: BSDTourFlowModel

    let onPhotoRequested: (BSDQuestStep) -> Void
    let onQRScanRequested: (BSDQuestStep) -> Void

    init(
        flow: BSDTourFlowModel,
        onPhotoRequested: @escaping (BSDQuestStep) -> Void = { _ in },
        onQRScanRequested: @escaping (BSDQuestStep) -> Void = { _ in }
    ) {
        self.flow = flow
        self.onPhotoRequested = onPhotoRequested
        self.onQRScanRequested = onQRScanRequested
    }

    var body: some View {
        if let quest = flow.currentQuest, let step = flow.currentStep {
            ExpandableWidget(
                isExpanded: $flow.isWidgetExpanded,
                collapsedMaxWidth: 392,
                expandedMaxWidth: 360,
                horizontalPadding: 20,
                edgePadding: 16
            ) {
                BSDTourQuestCollapsedContent(quest: quest, step: step)
            } expandedContent: {
                expandedContent(quest: quest, step: step)
            }
        }
    }

    @ViewBuilder
    private func expandedContent(quest: BSDQuest, step: BSDQuestStep) -> some View {
        switch step.kind {
        case .lookAround:
            LookAroundQuestContent(quest: quest, step: step, onNext: flow.advance)

        case .quiz:
            if let quiz = step.quiz {
                QuizQuestContent(
                    label: quest.displayLabel,
                    title: step.title,
                    question: quiz.question,
                    options: quiz.options,
                    selectedOption: $flow.selectedQuizOption,
                    reward: quest.reward,
                    onSubmit: flow.advance
                )
            }

        case .artistIntro:
            ArtistIntroQuestContent(quest: quest, step: step, onNext: flow.advance)

        case .drawingCanvas:
            DrawingCanvasQuestContent(
                quest: quest,
                step: step,
                remainingSeconds: flow.drawingRemainingSeconds
            ) {
                DrawingCanvasView(drawingData: $flow.drawingData)
            } onSubmit: {
                flow.advance()
            }

        case .timedPhysicalChallenge:
            TimedPhysicalChallengeQuestContent(
                quest: quest,
                step: step,
                remainingSeconds: flow.drawingRemainingSeconds,
                onSubmit: flow.advance
            )

        case .findOut:
            FindOutQuestContent(
                quest: quest,
                step: step,
                response: textBinding(for: step),
                hasCapturedPhoto: flow.hasCapturedPhoto(for: step),
                requiresPhoto: step.requiresPhoto,
                onPhoto: { onPhotoRequested(step) },
                onSubmit: flow.advance
            )

        case .qrConfirm:
            QRConfirmQuestContent(
                quest: quest,
                step: step,
                validationMessage: flow.qrValidationMessage,
                onScan: { onQRScanRequested(step) }
            )
        }
    }

    private func textBinding(for step: BSDQuestStep) -> Binding<String> {
        Binding {
            flow.textResponse(for: step)
        } set: { newValue in
            flow.updateTextResponse(newValue, for: step)
        }
    }
}

#Preview("BSD Tour Quest Widget") {
    struct PreviewHost: View {
        @State private var flow = BSDTourFlowModel(isWidgetExpanded: true)

        var body: some View {
            ZStack {
                Color(.systemGray5).ignoresSafeArea()

                BSDTourQuestWidget(flow: flow)
            }
        }
    }

    return PreviewHost()
}
