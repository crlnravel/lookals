//
//  BSDTourFlowModel.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class BSDTourFlowModel {
    @ObservationIgnored private var drawingCountdownTask: Task<Void, Never>?
    @ObservationIgnored var onQuestCompletionRequested: ((BSDQuest) -> BSDTourQuestCompletionOutcome)?
    @ObservationIgnored var onQuestSuccessContinued: ((BSDQuest) -> Void)?
    @ObservationIgnored var onStepChanged: ((Int, Int) -> Void)?

    private(set) var quests: [BSDQuest]
    private(set) var currentQuestIndex: Int
    private(set) var currentStepIndex: Int
    private(set) var earnedPoints: Int

    var isWidgetExpanded: Bool
    var selectedQuizOption: String?
    var drawingData: Data?
    var drawingRemainingSeconds: Int
    var textResponses: [String: String]
    var capturedPhotoData: [String: Data]
    var scannedQRPayloads: [String: String]
    var qrValidationMessage: String?
    var isShowingQuestSuccess: Bool
    var questSuccessTitleOverride: String?
    var questSuccessSubtitle: String?
    var isWaitingForGroupCompletion: Bool
    var groupWaitMessage: String?

    init(
        quests: [BSDQuest] = BSDTourQuestDemoData.quests,
        currentQuestIndex: Int = 0,
        currentStepIndex: Int = 0,
        earnedPoints: Int = 0,
        isWidgetExpanded: Bool = false,
        isShowingQuestSuccess: Bool = false
    ) {
        self.quests = quests
        self.currentQuestIndex = currentQuestIndex
        self.currentStepIndex = currentStepIndex
        self.earnedPoints = earnedPoints
        self.isWidgetExpanded = isWidgetExpanded
        self.selectedQuizOption = nil
        self.drawingData = nil
        self.drawingRemainingSeconds = quests[safe: currentQuestIndex]?.steps[safe: currentStepIndex]?.durationSeconds ?? 0
        self.textResponses = [:]
        self.capturedPhotoData = [:]
        self.scannedQRPayloads = [:]
        self.qrValidationMessage = nil
        self.isShowingQuestSuccess = isShowingQuestSuccess
        self.questSuccessTitleOverride = nil
        self.questSuccessSubtitle = nil
        self.isWaitingForGroupCompletion = false
        self.groupWaitMessage = nil

        prepareCurrentStep()
    }

    deinit {
        drawingCountdownTask?.cancel()
    }

    var currentQuest: BSDQuest? {
        quests[safe: currentQuestIndex]
    }

    var currentStep: BSDQuestStep? {
        currentQuest?.steps[safe: currentStepIndex]
    }

    var canGoBack: Bool {
        guard !isShowingQuestSuccess else {
            return false
        }

        guard
            currentStepIndex > 0,
            let currentQuest,
            let currentStep
        else {
            return false
        }

        if currentStep.kind.isTimerStep {
            return false
        }

        if currentQuest.id == "l6-q6", currentStep.kind == .qrConfirm {
            return false
        }

        if currentQuest.steps[safe: currentStepIndex - 1]?.kind.isTimerStep == true {
            return false
        }

        return true
    }

    var isComplete: Bool {
        currentQuest == nil
    }

    var questSuccessTitle: String {
        if let questSuccessTitleOverride {
            return questSuccessTitleOverride
        }

        return currentStep?.kind == .quiz ? "Correct!" : "Quest Complete!"
    }

    func updateTextResponse(_ response: String, for step: BSDQuestStep) {
        textResponses[step.id] = response
    }

    func textResponse(for step: BSDQuestStep) -> String {
        textResponses[step.id, default: ""]
    }

    func updateCapturedPhotoData(_ data: Data, for step: BSDQuestStep) {
        capturedPhotoData[step.id] = data
    }

    func hasCapturedPhoto(for step: BSDQuestStep) -> Bool {
        capturedPhotoData[step.id] != nil
    }

    func updateDrawingData(_ data: Data?) {
        drawingData = data
    }

    private func startDrawingCountdown(for step: BSDQuestStep) {
        drawingCountdownTask?.cancel()

        guard let durationSeconds = step.durationSeconds else {
            drawingRemainingSeconds = 0
            return
        }

        drawingRemainingSeconds = durationSeconds
        drawingCountdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard !Task.isCancelled else { return }

                self?.tickDrawingCountdown()
            }
        }
    }

    private func stopDrawingCountdown() {
        drawingCountdownTask?.cancel()
        drawingCountdownTask = nil
    }

    func setDrawingRemainingSeconds(_ seconds: Int) {
        drawingRemainingSeconds = max(0, seconds)
    }

    func setEarnedPoints(_ points: Int) {
        earnedPoints = max(0, points)
    }

    func validateQRPayload(_ payload: String, for step: BSDQuestStep) -> Bool {
        scannedQRPayloads[step.id] = payload

        guard let expectedQRPayload = step.expectedQRPayload else {
            qrValidationMessage = nil
            return true
        }

        let isValid = payload == expectedQRPayload
        qrValidationMessage = isValid ? nil : "That QR code does not match this quest. Try again."
        return isValid
    }

    func advance() {
        guard !isShowingQuestSuccess, let quest = currentQuest else { return }

        if currentStepIndex < quest.steps.count - 1 {
            currentStepIndex += 1
            prepareCurrentStep()
            onStepChanged?(currentQuestIndex, currentStepIndex)
        } else {
            showQuestSuccess()
        }
    }

    func goBack() {
        guard canGoBack else { return }

        currentStepIndex -= 1
        prepareCurrentStep()
        onStepChanged?(currentQuestIndex, currentStepIndex)
    }

    func continueAfterQuestSuccess() {
        guard isShowingQuestSuccess else { return }

        let completedQuest = currentQuest
        isShowingQuestSuccess = false

        if let completedQuest, let onQuestSuccessContinued {
            onQuestSuccessContinued(completedQuest)
        } else {
            currentQuestIndex += 1
            currentStepIndex = 0
            isWidgetExpanded = false
            prepareCurrentStep()
        }
    }

    func showExternalQuestSuccess(title: String, subtitle: String?) {
        guard currentQuest != nil else { return }

        stopDrawingCountdown()
        qrValidationMessage = nil
        questSuccessTitleOverride = title
        questSuccessSubtitle = subtitle
        isWaitingForGroupCompletion = false
        groupWaitMessage = nil
        isWidgetExpanded = true
        isShowingQuestSuccess = true
    }

    func moveToQuest(
        withID questID: String,
        stepIndex: Int = 0,
        expanded: Bool = true,
        notifiesStepChange: Bool = true
    ) {
        guard let index = quests.firstIndex(where: { $0.id == questID }) else { return }

        currentQuestIndex = index
        currentStepIndex = stepIndex
        isWidgetExpanded = expanded
        selectedQuizOption = nil
        qrValidationMessage = nil
        questSuccessTitleOverride = nil
        questSuccessSubtitle = nil
        isShowingQuestSuccess = false
        isWaitingForGroupCompletion = false
        groupWaitMessage = nil
        prepareCurrentStep()

        if notifiesStepChange {
            onStepChanged?(currentQuestIndex, currentStepIndex)
        }
    }

    func restart() {
        currentQuestIndex = 0
        currentStepIndex = 0
        earnedPoints = 0
        isWidgetExpanded = false
        selectedQuizOption = nil
        drawingData = nil
        textResponses = [:]
        capturedPhotoData = [:]
        scannedQRPayloads = [:]
        qrValidationMessage = nil
        questSuccessTitleOverride = nil
        questSuccessSubtitle = nil
        isShowingQuestSuccess = false
        isWaitingForGroupCompletion = false
        groupWaitMessage = nil
        prepareCurrentStep()
    }

    private func showQuestSuccess() {
        guard let currentQuest else {
            return
        }

        if let outcome = onQuestCompletionRequested?(currentQuest) {
            switch outcome {
            case .showSuccess(let title, let subtitle):
                stopDrawingCountdown()
                qrValidationMessage = nil
                questSuccessTitleOverride = title
                questSuccessSubtitle = subtitle
                isWaitingForGroupCompletion = false
                groupWaitMessage = nil
                isWidgetExpanded = true
                isShowingQuestSuccess = true

            case .waitForGroup(let message):
                stopDrawingCountdown()
                qrValidationMessage = nil
                isWidgetExpanded = true
                isShowingQuestSuccess = false
                isWaitingForGroupCompletion = true
                groupWaitMessage = message
            }

            return
        }

        earnedPoints += currentQuest.reward
        stopDrawingCountdown()
        qrValidationMessage = nil
        questSuccessTitleOverride = nil
        questSuccessSubtitle = nil
        isWaitingForGroupCompletion = false
        groupWaitMessage = nil
        isWidgetExpanded = true
        isShowingQuestSuccess = true
    }

    private func prepareCurrentStep() {
        stopDrawingCountdown()
        selectedQuizOption = nil
        qrValidationMessage = nil
        questSuccessTitleOverride = nil
        questSuccessSubtitle = nil
        isWaitingForGroupCompletion = false
        groupWaitMessage = nil

        guard let currentStep else {
            drawingRemainingSeconds = 0
            return
        }

        guard currentStep.kind == .drawingCanvas || currentStep.kind == .timedPhysicalChallenge else {
            drawingRemainingSeconds = currentStep.durationSeconds ?? 0
            return
        }

        startDrawingCountdown(for: currentStep)
    }

    private func tickDrawingCountdown() {
        guard drawingRemainingSeconds > 0 else {
            stopDrawingCountdown()
            return
        }

        drawingRemainingSeconds -= 1

        if drawingRemainingSeconds == 0 {
            stopDrawingCountdown()
        }
    }
}

private extension BSDQuestStep.Kind {
    var isTimerStep: Bool {
        self == .drawingCanvas || self == .timedPhysicalChallenge
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
