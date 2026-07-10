//
//  BSDQuestStep.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

struct BSDQuestStep: Identifiable, Equatable {
    enum Kind: Equatable {
        case lookAround
        case quiz
        case artistIntro
        case drawingCanvas
        case findOut
        case qrConfirm
    }

    let id: String
    let kind: Kind
    let title: String
    let prompt: String
    let footnote: String?
    let imageName: String?
    let quiz: BSDQuestQuiz?
    let inputMode: BSDQuestInputMode?
    let requiresPhoto: Bool
    let primaryActionTitle: String
    let expectedQRPayload: String?
    let durationSeconds: Int?

    init(
        id: String,
        kind: Kind,
        title: String,
        prompt: String,
        footnote: String?,
        imageName: String?,
        quiz: BSDQuestQuiz?,
        inputMode: BSDQuestInputMode?,
        requiresPhoto: Bool = false,
        primaryActionTitle: String,
        expectedQRPayload: String?,
        durationSeconds: Int?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.prompt = prompt
        self.footnote = footnote
        self.imageName = imageName
        self.quiz = quiz
        self.inputMode = inputMode
        self.requiresPhoto = requiresPhoto
        self.primaryActionTitle = primaryActionTitle
        self.expectedQRPayload = expectedQRPayload
        self.durationSeconds = durationSeconds
    }
}
