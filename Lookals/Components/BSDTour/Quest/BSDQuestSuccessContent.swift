//
//  BSDQuestSuccessContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDQuestSuccessContent: View {
    let quest: BSDQuest
    let title: String
    let subtitle: String?
    let onContinue: () -> Void

    init(
        quest: BSDQuest,
        title: String,
        subtitle: String? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.quest = quest
        self.title = title
        self.subtitle = subtitle
        self.onContinue = onContinue
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(quest.displayLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)

                if let subtitle {
                    Text(subtitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.top, 32)

            SuccessAvatarCluster(participants: BSDTourConfiguration.participants)

            QuestSuccessRewardLabel(points: quest.reward)


            PrimaryButton(
                "Continue",
                font: .headline.weight(.heavy),
                action: onContinue
            )
        }
        .frame(minHeight: 520)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .overlay {
            ConfettiBurstView()
                .allowsHitTesting(false)
        }
        .clipped()
        .accessibilityElement(children: .contain)
    }
}

private struct QuestSuccessRewardLabel: View {
    let points: Int

    var body: some View {
        QuestRewardLabel(points: points)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SuccessAvatarCluster: View {
    let participants: [BSDTourParticipant]

    private let placements: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-40, 16, 56),
        (-16, -12, 56),
        (24, -24, 64),
        (8, 24, 48),
        (48, 18, 56)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(participants.prefix(placements.count).enumerated()), id: \.element.id) { index, participant in
                let placement = placements[index]

                Image(participant.avatarImageName ?? "AvatarPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: placement.size, height: placement.size)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.bsdTourRingColor(named: participant.ringColorName), lineWidth: 5)
                    }
                    .offset(x: placement.x, y: placement.y)
            }
        }
        .frame(width: 148, height: 104)
        .accessibilityLabel("Quest team")
    }
}

private struct ConfettiBurstView: View {
    private let pieces = ConfettiPiece.samples

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, containerSize: proxy.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let startRotation: Double
    let endRotation: Double
    let endX: CGFloat
    let endY: CGFloat
    let delay: Double
    let duration: Double

    static let samples: [ConfettiPiece] = [
        ConfettiPiece(color: .red, width: 12, height: 28, startRotation: -20, endRotation: 92, endX: -0.54, endY: -0.36, delay: 0.00, duration: 0.90),
        ConfettiPiece(color: .orange, width: 10, height: 30, startRotation: 12, endRotation: 128, endX: 0.46, endY: -0.42, delay: 0.04, duration: 1.00),
        ConfettiPiece(color: .yellow, width: 10, height: 24, startRotation: 8, endRotation: 110, endX: -0.30, endY: 0.36, delay: 0.02, duration: 1.10),
        ConfettiPiece(color: .blue, width: 12, height: 24, startRotation: -16, endRotation: -96, endX: 0.34, endY: 0.32, delay: 0.06, duration: 1.05),
        ConfettiPiece(color: .mint, width: 12, height: 28, startRotation: 24, endRotation: 148, endX: 0.56, endY: 0.12, delay: 0.08, duration: 1.15),
        ConfettiPiece(color: .pink, width: 10, height: 28, startRotation: -8, endRotation: -126, endX: -0.52, endY: 0.14, delay: 0.10, duration: 1.20),
        ConfettiPiece(color: .white, width: 14, height: 26, startRotation: 20, endRotation: 98, endX: -0.36, endY: 0.72, delay: 0.12, duration: 1.30),
        ConfettiPiece(color: .orange, width: 12, height: 30, startRotation: -12, endRotation: -108, endX: 0.40, endY: 0.68, delay: 0.14, duration: 1.35),
        ConfettiPiece(color: .red, width: 10, height: 24, startRotation: 6, endRotation: 120, endX: 0.58, endY: 0.52, delay: 0.16, duration: 1.25),
        ConfettiPiece(color: .yellow, width: 12, height: 28, startRotation: -18, endRotation: 92, endX: -0.58, endY: 0.52, delay: 0.18, duration: 1.32),
        ConfettiPiece(color: .blue, width: 9, height: 24, startRotation: 26, endRotation: -116, endX: 0.20, endY: -0.30, delay: 0.04, duration: 1.00),
        ConfettiPiece(color: .mint, width: 9, height: 26, startRotation: -24, endRotation: 104, endX: -0.18, endY: -0.28, delay: 0.06, duration: 0.95)
    ]
}

private struct ConfettiPieceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let piece: ConfettiPiece
    let containerSize: CGSize

    @State private var isAnimating = false
    @State private var isVisible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .rotationEffect(.degrees(isAnimating ? piece.endRotation : piece.startRotation))
            .offset(
                x: isAnimating ? piece.endX * containerSize.width : 0,
                y: isAnimating ? piece.endY * containerSize.height : -40
            )
            .opacity(isVisible && !reduceMotion ? 0.95 : 0)
            .animation(
                .easeOut(duration: piece.duration).delay(piece.delay),
                value: isAnimating
            )
            .animation(.easeIn(duration: 0.12), value: isVisible)
            .task {
                guard !reduceMotion else { return }
                isAnimating = true

                let totalDuration = piece.delay + piece.duration
                try? await Task.sleep(for: .seconds(totalDuration))

                guard !Task.isCancelled else { return }
                isVisible = false
            }
    }
}

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[0],
        step: BSDTourQuestDemoData.quests[0].steps[1]
    ) {
        BSDQuestSuccessContent(
            quest: BSDTourQuestDemoData.quests[0],
            title: "Correct!",
            subtitle: "Completed by You",
            onContinue: {}
        )
    }
}
