//
//  ShakePhoneQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct ShakePhoneQuestContent: View {
    let participants: [BSDTourParticipantDisplay]

    init(participants: [BSDTourParticipantDisplay] = []) {
        self.participants = participants
    }

    var body: some View {
        VStack(spacing: 24) {
            ShakePhoneAsset(size: .large)

            VStack(spacing: 16) {
                Text("Shake Your\nPhone")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Text("Shake your iPhone close to their iPhone to confirm your meetup.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ShakePhoneExpandedParticipantCluster(participants: participants)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
        .padding(.bottom, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shake your phone. Shake your iPhone close to their iPhone to confirm your meetup.")
    }
}

private struct ShakePhoneExpandedParticipantCluster: View {
    let participants: [BSDTourParticipantDisplay]

    var body: some View {
        ZStack {
            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                participantMarker(participant)
                    .frame(width: markerSize(at: index), height: markerSize(at: index))
                    .scaleEffect(index == 4 ? 0.86 : 1)
                    .offset(offset(at: index))
            }
        }
        .frame(width: 196, height: 132)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func participantMarker(_ participant: BSDTourParticipantDisplay) -> some View {
        if participant.hasJoined {
            RadarMarker(
                style: .participantAvatar(
                    imageName: participant.avatarImageName,
                    ringColor: participant.ringColor,
                    label: participant.name
                )
            )
        } else {
            ShakePhoneParticipantRing(color: participant.ringColor, size: 58)
        }
    }

    private func offset(at index: Int) -> CGSize {
        let offsets = [
            CGSize(width: -64, height: 32),
            CGSize(width: -12, height: 24),
            CGSize(width: -44, height: -28),
            CGSize(width: 40, height: -44),
            CGSize(width: 76, height: 28)
        ]
        return offsets[safe: index] ?? .zero
    }

    private func markerSize(at index: Int) -> CGFloat {
        [48, 42, 58, 76, 64][safe: index] ?? 48
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ShakePhoneQuestContent()
        .frame(maxWidth: 360)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding()
        .background(Color(.systemGray5))
}
