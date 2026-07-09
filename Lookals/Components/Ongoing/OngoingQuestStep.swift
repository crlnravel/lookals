//
//  OngoingQuestStep.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

struct OngoingQuestStep: Identifiable, Equatable {
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
    let quiz: OngoingQuestQuiz?
    let inputMode: OngoingQuestInputMode?
    let primaryActionTitle: String
    let expectedQRPayload: String?
    let durationSeconds: Int?
}
