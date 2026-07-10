//
//  BSDTourQuestDemoData.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

enum BSDTourQuestDemoData {
    nonisolated static let q2ExpectedQRPayload = "lookals:l2:q2:confirm"
    nonisolated static let q3ExpectedQRPayload = "lookals:l3:q3:confirm"
    nonisolated static let q4ExpectedQRPayload = "lookals:l4:q4:confirm"
    nonisolated static let q5ExpectedQRPayload = "lookals:l5:q5:confirm"
    nonisolated static let q6ExpectedQRPayload = "lookals:l6:q6:confirm"
    nonisolated static let q7ExpectedQRPayload = "lookals:l7:q7:confirm"
    nonisolated static let q8ExpectedQRPayload = "lookals:l8:q8:confirm"

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
        ),
        BSDQuest(
            id: "l3-q3",
            locationCode: "L3",
            questCode: "Q3",
            kind: .quest,
            displayNumber: 3,
            title: "Lets Interact!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l3-q3-interact",
                    kind: .lookAround,
                    title: "Lets Interact!",
                    prompt: "Ask the owner how this place started (hint: it’s been here for over a decade!), then leave your mark on the wall before you head out.",
                    footnote: nil,
                    imageName: "BSDMap/BaristaOwner",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l3-q3-find-out",
                    kind: .findOut,
                    title: "Lets Find Out!",
                    prompt: "Drop a summary of their story!",
                    footnote: "No robotic Q&A allowed. Lets make a friend and be the Lookals!",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .text,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l3-q3-leave-mark",
                    kind: .timedPhysicalChallenge,
                    title: "Leave a Mark",
                    prompt: "Think quick! Draw one object on the wall as a team. Each person got 20 seconds to complete each other drawing!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: nil,
                    durationSeconds: 20
                ),
                BSDQuestStep(
                    id: "l3-q3-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Show the barista your drawing and\nask for a QR code!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q3ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l4-q4",
            locationCode: "L4",
            questCode: "Q4",
            kind: .quest,
            displayNumber: 4,
            title: "Look Around!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l4-q4-look-around",
                    kind: .lookAround,
                    title: "Look Around!",
                    prompt: "Find this cute blue door in the area, find out what is the place about!",
                    footnote: nil,
                    imageName: "BSDMap/BlueDoor",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l4-q4-find-out",
                    kind: .findOut,
                    title: "Lets Find Out!",
                    prompt: "Direct from the source. Hit up the owner and ask them what their personal favorite pasta or rice dish is on the menu.",
                    footnote: "No robotic Q&A allowed. Lets make a friend and be the Lookals!",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .text,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l4-q4-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Ask the owner\nfor the QR code!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q4ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l5-q5",
            locationCode: "L5",
            questCode: "Q5",
            kind: .quest,
            displayNumber: 5,
            title: "Show your Skill!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l5-q5-look-around",
                    kind: .lookAround,
                    title: "Show your Skill!",
                    prompt: "Team up and be the champion with your team!",
                    footnote: nil,
                    imageName: "BSDMap/Hoop",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l5-q5-challenge",
                    kind: .timedPhysicalChallenge,
                    title: "Show your Skill!",
                    prompt: "Each of you got exactly 20 seconds on the court. Hit up the store keeper and tell them your team’s final score!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: nil,
                    durationSeconds: 20
                ),
                BSDQuestStep(
                    id: "l5-q5-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Ask the store keeper\nfor the QR code!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q5ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l6-q6",
            locationCode: "L6",
            questCode: "Q6",
            kind: .quest,
            displayNumber: 6,
            title: "Treasure Hunt!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l6-q6-treasure-hunt",
                    kind: .lookAround,
                    title: "Treasure Hunt!",
                    prompt: "Match the photo, follow the instructions, and unlock the treasure!",
                    footnote: nil,
                    imageName: "BSDMap/TH 1 Tree",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l6-q6-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Find the next clue!",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q6ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l7-q7",
            locationCode: "L7",
            questCode: "Q7",
            kind: .quest,
            displayNumber: 7,
            title: "Lets Interact!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l7-q7-interact",
                    kind: .lookAround,
                    title: "Lets Interact!",
                    prompt: "This strip is packed with tailors. Cut through the noise and track down Mr. Samsudin.",
                    footnote: nil,
                    imageName: "BSDMap/GangPenjahit",
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Next",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l7-q7-find-out",
                    kind: .findOut,
                    title: "Lets Find Out!",
                    prompt: "Ask Mr. Samsudin about the craziest or most impossible tailoring request he’s ever gotten from a customer. Drop his story in the notes!",
                    footnote: "No robotic Q&A allowed. Lets make a friend and be the Lookals!",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .text,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l7-q7-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Ask Mr. Samsudin\nfor the QR code.",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q7ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        ),
        BSDQuest(
            id: "l8-q8",
            locationCode: "L8",
            questCode: "Q8",
            kind: .quest,
            displayNumber: 8,
            title: "Collab Time!",
            reward: 30,
            steps: [
                BSDQuestStep(
                    id: "l8-q8-collab",
                    kind: .findOut,
                    title: "Collab Time!",
                    prompt: "Team up to write a 4-line poem about the city, one line per person.\nOnce it’s done, step up and perform it for the Kelontong owner.\nLet the master judge your flow!",
                    footnote: "Put your line of poem",
                    imageName: nil,
                    quiz: nil,
                    inputMode: .text,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: nil,
                    durationSeconds: nil
                ),
                BSDQuestStep(
                    id: "l8-q8-confirm",
                    kind: .qrConfirm,
                    title: "Confirm",
                    prompt: "Ask Kelontong owner\nfor the QR code.",
                    footnote: nil,
                    imageName: nil,
                    quiz: nil,
                    inputMode: nil,
                    primaryActionTitle: "Scan to Confirm",
                    expectedQRPayload: q8ExpectedQRPayload,
                    durationSeconds: nil
                )
            ]
        )
    ]
}
