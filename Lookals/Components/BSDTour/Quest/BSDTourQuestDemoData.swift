//
//  BSDTourQuestDemoData.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

enum BSDTourQuestDemoData {
    nonisolated static let q2ExpectedQRPayload = "lookals:l2:q2:confirm"

    nonisolated static let quests: [BSDQuest] = [
        BSDQuest(
            id: "l1-q1",
            locationCode: "L1",
            questCode: "Q1",
            kind: .quest,
            displayNumber: 1,
            title: "Look Around!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l1-q1-look-around",
                    kind: .lookAround,
                    title: "Look Around!",
                    prompt: "Find this exact plant and hit up the seller to find out what it's called!",
                    footnote: "The seller wont tell unless you found it 👀",
                    imageName: "BSDMap/Daun",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l1-q1-quiz",
                    kind: .quiz,
                    title: "Quiz",
                    prompt: "",
                    footnote: nil,
                    imageName: nil,
                    quiz: BSDQuestQuiz(
                        question: "What’s the name of the plant?",
                        options: [
                            "Alocasia Watsoniana",
                            "Piper sp.",
                            "Sphattypillum",
                            "A. Papillilaminum"
                        ],
                        correctOption: "A. Papillilaminum"
                    ),
                    inputMode: nil,
                    primaryActionTitle: "Submit",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l2-sq1",
            locationCode: "L2",
            questCode: "SQ1",
            kind: .sideQuest,
            displayNumber: 1,
            title: "Be an Artist!",
            reward: 5,
            steps: [
                BSDQuestStep(
                    id: "l2-sq1-intro",
                    kind: .artistIntro,
                    title: "Be an Artist!",
                    prompt: "Got 20 seconds?\nDraw any object on your route before hitting the next checkpoint.",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: 20
                ),
                BSDQuestStep(
                    id: "l2-sq1-drawing",
                    kind: .drawingCanvas,
                    title: "Be an Artist!",
                    prompt: "Show us what you got! Draw here.",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Submit",
                    expectedQRPayload: nil,
                    durationSeconds: 20
                )
            ]
        ),
        BSDQuest(
            id: "l2-q2",
            locationCode: "L2",
            questCode: "Q2",
            kind: .quest,
            displayNumber: 2,
            title: "Look Around!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l2-q2-look-around",
                    kind: .lookAround,
                    title: "Look Around!",
                    prompt: "Track down the exact booth in this picture and ask the seller how long they’ve been running this spot.",
                    footnote: nil,
                    imageName: "BSDMap/Booth",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l2-q2-find-out",
                    kind: .findOut,
                    title: "Lets Find Out!",
                    prompt: "Ask the owner about the craziest or funniest thing that’s ever happened at this spot.\nDrop a summary of their story and snap a quick selfie!",
                    footnote: "No robotic Q&A allowed. Lets make a friend and be the Lookals!",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .text,
                    requiresPhoto: true,
                    primaryActionTitle: "Take a Photo",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l2-q2-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Ask the seller\nfor the QR code.",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan QR",
                    expectedQRPayload: q2ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l2-sq2",
            locationCode: "L2",
            questCode: "SQ2",
            kind: .sideQuest,
            displayNumber: 2,
            title: "Lets Find Out!",
            reward: 5,
            steps: [
                BSDQuestStep(
                    id: "l2-sq2-find-out",
                    kind: .findOut,
                    title: "Lets Find Out!",
                    prompt: "Time to interact with the locals!\nFind a fruit seller, ask how much 1kg of mangoes costs, and snap a quick selfie with them!",
                    footnote: "No robotic Q&A allowed. Lets make a friend and be the Lookals!",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .currency,
                    requiresPhoto: true,
                    primaryActionTitle: "Take a Photo",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                )
            ]
        )
    ]
}
