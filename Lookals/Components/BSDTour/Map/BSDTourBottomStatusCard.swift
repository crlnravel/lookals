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
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isArrived ? .secondary : .primary)
                    .lineLimit(2)
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
        HStack(spacing: 12) {
            GeometryReader { proxy in
                let avatarDiameter: CGFloat = 36
                let avatarRadius = avatarDiameter / 2
                let trackWidth = proxy.size.width
                let avatarPosition = min(
                    max(avatarRadius, trackWidth * clampedProgress),
                    trackWidth - avatarRadius
                )
                let completedTrackWidth = min(
                    max(4, trackWidth * clampedProgress),
                    trackWidth
                )

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray4))
                        .frame(width: trackWidth, height: 4)
                        .position(x: trackWidth / 2, y: proxy.size.height / 2)

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: completedTrackWidth, height: 4)
                        .position(
                            x: completedTrackWidth / 2,
                            y: proxy.size.height / 2
                        )

                    if let currentUser = participants.first {
                        RadarMarker(
                            style: .participantAvatar(
                                imageName: currentUser.avatarImageName,
                                ringColor: currentUser.ringColor,
                                label: currentUser.name
                            )
                        )
                        .frame(width: avatarDiameter, height: proxy.size.height)
                        .scaleEffect(0.78)
                        .position(x: avatarPosition, y: proxy.size.height / 2)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(height: 40)

            RadarMarker(style: .smallDestination)
                .frame(width: 28, height: 40)
                .scaleEffect(0.65)
        }
        .frame(height: 40)
        .animation(.smooth(duration: 0.25), value: clampedProgress)
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
}
