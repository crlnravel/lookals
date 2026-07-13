//
//  ShakePhoneCollapsedContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct ShakePhoneCollapsedContent: View {
    let participants: [BSDTourParticipantDisplay]

    init(participants: [BSDTourParticipantDisplay] = []) {
        self.participants = participants
    }

    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 48, height: 48)

            ShakePhoneAsset(size: .small)

            VStack(alignment: .leading, spacing: 8) {
                Text("Shake Your Phone!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                ShakePhoneParticipantRow(participants: participants)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shake your phone to confirm your meetup")
    }
}

struct ShakePhoneParticipantRow: View {
    let participants: [BSDTourParticipantDisplay]

    init(participants: [BSDTourParticipantDisplay] = []) {
        self.participants = participants
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(participants) { participant in
                Group {
                    if participant.hasJoined {
                        RadarMarker(
                            style: .participantAvatar(
                                imageName: participant.avatarImageName,
                                ringColor: participant.ringColor,
                                label: participant.name
                            )
                        )
                        .frame(width: 28, height: 28)
                        .scaleEffect(0.64)
                    } else {
                        ShakePhoneParticipantRing(color: participant.ringColor)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.bouncy, value: participants.map(\.id))
        .accessibilityHidden(true)
    }
}

struct ShakePhoneParticipantRing: View {
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 4)
            .frame(width: size, height: size)
    }
}

struct ShakePhoneAsset: View {
    enum Size {
        case small
        case large

        var width: CGFloat {
            switch self {
            case .small:
                61
            case .large:
                122
            }
        }

        var height: CGFloat {
            switch self {
            case .small:
                49
            case .large:
                97
            }
        }
    }

    let size: Size

    var body: some View {
        Image("ShakePhone")
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }
}

#Preview {
    ShakePhoneCollapsedContent()
        .frame(maxWidth: 392)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding()
        .background(Color(.systemGray5))
}
