//
//  OngoingQuestWidget.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct OngoingQuestWidget: View {
    @Bindable var flow: OngoingQuestFlowModel

    let onPhotoRequested: (OngoingQuestStep) -> Void
    let onQRScanRequested: (OngoingQuestStep) -> Void

    init(
        flow: OngoingQuestFlowModel,
        onPhotoRequested: @escaping (OngoingQuestStep) -> Void = { _ in },
        onQRScanRequested: @escaping (OngoingQuestStep) -> Void = { _ in }
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
                OngoingQuestCollapsedContent(quest: quest, step: step)
            } expandedContent: {
                expandedContent(quest: quest, step: step)
            }
        }
    }

    @ViewBuilder
    private func expandedContent(quest: OngoingQuest, step: OngoingQuestStep) -> some View {
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
                flow.stopDrawingCountdown()
                flow.advance()
            }
            .task(id: step.id) {
                flow.startDrawingCountdown(for: step)
            }
            .onDisappear {
                flow.stopDrawingCountdown()
            }

        case .findOut:
            FindOutQuestContent(
                quest: quest,
                step: step,
                response: textBinding(for: step),
                hasCapturedPhoto: flow.hasCapturedPhoto(for: step),
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

    private func textBinding(for step: OngoingQuestStep) -> Binding<String> {
        Binding {
            flow.textResponse(for: step)
        } set: { newValue in
            flow.updateTextResponse(newValue, for: step)
        }
    }
}

#Preview("Ongoing Quest Widget") {
    struct PreviewHost: View {
        @State private var flow = OngoingQuestFlowModel(isWidgetExpanded: true)

        var body: some View {
            ZStack {
                Color(.systemGray5).ignoresSafeArea()

                OngoingQuestWidget(flow: flow)
            }
        }
    }

    return PreviewHost()
}
