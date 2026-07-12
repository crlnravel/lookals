//
//  BSDTourBottomStatusCard.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourBottomStatusCard: View {
    let title: String
    let subtitle: String
    let progress: Double
    let isArrived: Bool
    let participants: [BSDTourParticipantDisplay]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isArrived ? .secondary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            progressRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxWidth: 392)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var progressRow: some View {
        HStack(spacing: 0) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray4))

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: max(4, proxy.size.width * min(max(progress, 0), 1)))
                }
            }
            .frame(height: 4)

            if let currentUser = participants.first {
                RadarMarker(
                    style: .participantAvatar(
                        imageName: currentUser.avatarImageName,
                        ringColor: currentUser.ringColor,
                        label: currentUser.name
                    )
                )
                .frame(width: 28, height: 28)
                .scaleEffect(0.7)
                .padding(.leading, -16)
            }

            RadarMarker(style: .smallDestination)
                .frame(width: 32, height: 32)
                .scaleEffect(0.60)
                .padding(.leading, 8)
        }
    }
}
