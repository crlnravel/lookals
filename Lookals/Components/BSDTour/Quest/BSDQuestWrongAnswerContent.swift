//
//  BSDQuestWrongAnswerContent.swift
//  Lookals
//

import SwiftUI

struct BSDQuestWrongAnswerContent: View {
    let correctAnswer: String
    let participants: [BSDTourParticipant]
    let onContinue: () -> Void

    init(
        correctAnswer: String,
        participants: [BSDTourParticipant] = BSDTourConfiguration.participants,
        onContinue: @escaping () -> Void
    ) {
        self.correctAnswer = correctAnswer
        self.participants = participants
        self.onContinue = onContinue
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                Text("Not this time.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Actually, it's \(correctAnswer).\nNow you know ;)")
                    .font(.default)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 84)

            QuestParticipantAvatarCluster(participants: participants)

            PrimaryButton(
                "Continue",
                font: .headline.weight(.heavy),
                action: onContinue
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .accessibilityElement(children: .contain)
    }
}

struct QuestParticipantAvatarCluster: View {
    let participants: [BSDTourParticipant]

    private let placements: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-40, 16, 56), (-16, -12, 56), (24, -24, 64), (8, 24, 48), (48, 18, 56)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(participants.prefix(placements.count).enumerated()), id: \.element.id) { index, participant in
                Image(participant.avatarImageName ?? "AvatarPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: placements[index].size, height: placements[index].size)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.bsdTourRingColor(named: participant.ringColorName), lineWidth: 5)
                    }
                    .offset(x: placements[index].x, y: placements[index].y)
            }
        }
        .frame(width: 148, height: 104)
        .accessibilityLabel("Quest team")
    }
}

#Preview {
    BSDQuestWrongAnswerContent(correctAnswer: "Piper sp.", onContinue: {})
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding()
        .background(Color(.systemGray5))
}
