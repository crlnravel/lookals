//
//  BSDTourBottomStatusCard.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct BSDTourBottomStatusCard: View {
    let phase: HypeRadarMapPhase
    let place: HypeRadarMapPlace

    init(
        phase: HypeRadarMapPhase,
        place: HypeRadarMapPlace = .poetTea
    ) {
        self.phase = phase
        self.place = place
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch phase {
            case .goingToMeetingPoint:
                goingContent
            case .arrived:
                arrivedContent
            case .shakeYourPhone, .quiz:
                arrivedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxWidth: 392)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var goingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Go to Meeting Point")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)

            HStack(alignment: .center, spacing: 16) {
                RadarMarker(style: .smallDestination)
                    .frame(width: 28, height: 32)
                    .scaleEffect(0.60)

                Text("\(place.name)\n\(place.address)")
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var arrivedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text(place.name)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)

                Text("You’ve arrived!")
                    .font(.default.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 4)

                RadarMarker(style: .avatar)
                    .frame(width: 28, height: 28)
                    .scaleEffect(0.7)
                    .padding(.leading, -16)

                RadarMarker(style: .smallDestination)
                    .frame(width: 32, height: 32)
                    .scaleEffect(0.60)
                    .padding(.leading, 8)
            }
        }
    }
}

#Preview("Going to Meeting Point Card") {
    BSDTourBottomStatusCard(phase: .goingToMeetingPoint)
        .padding(20)
        .background(Color(.systemGray5))
}

#Preview("Arrived Card") {
    BSDTourBottomStatusCard(phase: .arrived)
        .padding(20)
        .background(Color(.systemGray5))
}
