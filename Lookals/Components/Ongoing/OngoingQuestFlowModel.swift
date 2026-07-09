//
//  OngoingQuestFlowModel.swift
//  Lookals
//
//  Created by OpenAI on 10/07/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class OngoingQuestFlowModel {
    private(set) var quests: [OngoingQuest]
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

    init(
        quests: [OngoingQuest] = OngoingQuestDemoData.quests,
        currentQuestIndex: Int = 0,
        currentStepIndex: Int = 0,
        earnedPoints: Int = 0,
        isWidgetExpanded: Bool = false
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
    }

    var currentQuest: OngoingQuest? {
        quests[safe: currentQuestIndex]
    }

    var currentStep: OngoingQuestStep? {
        currentQuest?.steps[safe: currentStepIndex]
    }

    var isComplete: Bool {
        currentQuest == nil
    }

    func updateTextResponse(_ response: String, for step: OngoingQuestStep) {
        textResponses[step.id] = response
    }

    func updateCapturedPhotoData(_ data: Data, for step: OngoingQuestStep) {
        capturedPhotoData[step.id] = data
    }

    func updateDrawingData(_ data: Data?) {
        drawingData = data
    }

    func setDrawingRemainingSeconds(_ seconds: Int) {
        drawingRemainingSeconds = max(0, seconds)
    }

    func validateQRPayload(_ payload: String, for step: OngoingQuestStep) -> Bool {
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
        guard let quest = currentQuest else { return }

        if currentStepIndex < quest.steps.count - 1 {
            currentStepIndex += 1
            prepareCurrentStep()
        } else {
            completeCurrentQuest()
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
        prepareCurrentStep()
    }

    private func completeCurrentQuest() {
        if let currentQuest {
            earnedPoints += currentQuest.reward
        }

        currentQuestIndex += 1
        currentStepIndex = 0
        isWidgetExpanded = false
        prepareCurrentStep()
    }

    private func prepareCurrentStep() {
        selectedQuizOption = nil
        qrValidationMessage = nil
        drawingRemainingSeconds = currentStep?.durationSeconds ?? 0
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
