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
        .accessibilityLabel("\(title). \(subtitle). \(Int(clampedProgress * 100)) percent of the route complete.")
    }

    private var progressRow: some View {
        GeometryReader { proxy in
            let avatarDiameter: CGFloat = 28
            let destinationDiameter: CGFloat = 32
            let availableTravelWidth = max(0, proxy.size.width - avatarDiameter - destinationDiameter)
            let avatarPosition = avatarDiameter / 2 + availableTravelWidth * clampedProgress
            let destinationPosition = proxy.size.width - destinationDiameter / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .padding(.trailing, destinationDiameter / 2)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(4, min(avatarPosition, destinationPosition)), height: 4)

                if let currentUser = participants.first {
                    RadarMarker(
                        style: .participantAvatar(
                            imageName: currentUser.avatarImageName,
                            ringColor: currentUser.ringColor,
                            label: currentUser.name
                        )
                    )
                    .frame(width: avatarDiameter, height: avatarDiameter)
                    .scaleEffect(0.7)
                    .position(x: avatarPosition, y: proxy.size.height / 2)
                }

                RadarMarker(style: .smallDestination)
                    .frame(width: destinationDiameter, height: destinationDiameter)
                    .scaleEffect(0.60)
                    .position(x: destinationPosition, y: proxy.size.height / 2)
            }
        }
        .frame(height: 40)
        .animation(.linear(duration: 0.05), value: clampedProgress)
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
}
