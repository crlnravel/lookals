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
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            ConfettiBurstView()
                .allowsHitTesting(false)

            VStack(spacing: 40) {
                VStack(spacing: 28) {
                    Text(quest.displayLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(title)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)
                }
                .padding(.top, 88)

                Spacer(minLength: 24)

                SuccessAvatarCluster()

                QuestSuccessRewardLabel(points: quest.reward)

                Spacer(minLength: 32)

                PrimaryButton(
                    "Continue",
                    font: .headline.weight(.heavy),
                    action: onContinue
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(minHeight: 620)
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
    private let avatars: [AvatarToken] = [
        AvatarToken(color: .accentColor, icon: "person.crop.circle.fill", xOffset: -48, yOffset: 20, size: 64),
        AvatarToken(color: .orange, icon: "face.smiling.fill", xOffset: -20, yOffset: -16, size: 64),
        AvatarToken(color: .blue, icon: "person.crop.circle.fill", xOffset: 28, yOffset: -28, size: 76),
        AvatarToken(color: .yellow, icon: "person.crop.circle.fill", xOffset: 12, yOffset: 28, size: 56),
        AvatarToken(color: .mint, icon: "person.crop.circle.fill", xOffset: 58, yOffset: 22, size: 64)
    ]

    var body: some View {
        ZStack {
            ForEach(avatars) { avatar in
                Image(systemName: avatar.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(.systemBackground), avatar.color)
                    .frame(width: avatar.size, height: avatar.size)
                    .background(avatar.color, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(avatar.color, lineWidth: 5)
                    }
                    .offset(x: avatar.xOffset, y: avatar.yOffset)
            }
        }
        .frame(width: 180, height: 128)
        .accessibilityLabel("Quest team")
    }
}

private struct ConfettiBurstView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    private let pieces = ConfettiPiece.samples

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .rotationEffect(.degrees(isAnimating ? piece.endRotation : piece.startRotation))
                        .offset(
                            x: isAnimating ? piece.endX * proxy.size.width : 0,
                            y: isAnimating ? piece.endY * proxy.size.height : -40
                        )
                        .opacity(reduceMotion ? 0.75 : (isAnimating ? 0.95 : 0))
                        .animation(
                            .easeOut(duration: piece.duration).delay(piece.delay),
                            value: isAnimating
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                guard !reduceMotion else { return }
                isAnimating = true
            }
        }
    }
}

private struct AvatarToken: Identifiable {
    let id = UUID()
    let color: Color
    let icon: String
    let xOffset: CGFloat
    let yOffset: CGFloat
    let size: CGFloat
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

#Preview {
    BSDQuestContentPreviewContainer(
        quest: BSDTourQuestDemoData.quests[0],
        step: BSDTourQuestDemoData.quests[0].steps[1]
    ) {
        BSDQuestSuccessContent(
            quest: BSDTourQuestDemoData.quests[0],
            title: "Correct!",
            onContinue: {}
        )
    }
}
